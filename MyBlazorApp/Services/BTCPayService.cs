using Microsoft.Extensions.Configuration;
using MyBlazorApp.Models;
using System.Net.Http.Json;
using System.Text.Json;

namespace MyBlazorApp.Services;

/// <summary>
/// Calls the PaymentsApi backend to create and query BTCPay Server invoices.
///
/// WHY delegate to PaymentsApi instead of calling BTCPay directly?
///   Blazor WebAssembly runs entirely in the browser. Any value stored in WASM
///   memory is visible to the user via browser devtools. Sending the BTCPay API
///   key to the client would be a security risk, so all Greenfield API calls are
///   made server-side by PaymentsApi. This service just calls that local backend.
///
/// Configuration:
///   PAYMENT_API_BASE in wwwroot/appsettings.json (or appsettings.Development.json)
///   sets where PaymentsApi is running.  The default "/api" works when the Blazor
///   app is hosted on the same origin as PaymentsApi (e.g. behind a reverse proxy).
///   For local development, appsettings.Development.json sets it to
///   "https://localhost:5001/api" so both dev servers can run independently.
/// </summary>
public class BTCPayService : IBTCPayService
{
    private readonly HttpClient _http;

    // The resolved base URL of PaymentsApi (without a trailing slash).
    // Endpoint paths are appended as "/payments/create-invoice", etc.
    private readonly string _apiBase;

    public BTCPayService(HttpClient http, IConfiguration configuration)
    {
        _http = http;

        // Read PAYMENT_API_BASE from the Blazor configuration system, which
        // merges wwwroot/appsettings.json and wwwroot/appsettings.Development.json.
        // Fall back to "/api" (same-origin) if the key is absent.
        var configuredBase = configuration["PAYMENT_API_BASE"];
        _apiBase = string.IsNullOrWhiteSpace(configuredBase)
            ? "/api"
            : configuredBase.TrimEnd('/');
    }

    /// <inheritdoc />
    public async Task<CreateInvoiceResult?> CreateInvoiceAsync(
        decimal amount, string currency, string orderId, string? returnUrl = null)
    {
        // Build the request body that PaymentsApi expects.
        // PascalCase here matches the C# record CreateInvoiceRequest on the server side.
        var payload = new
        {
            Amount = amount,
            Currency = currency,
            OrderId = orderId,
            ReturnUrl = returnUrl
        };

        // POST to PaymentsApi → which proxies to BTCPay with the secret API key.
        var resp = await _http.PostAsJsonAsync($"{_apiBase}/payments/create-invoice", payload);

        // Return null on failure instead of throwing; the caller (Shop.razor)
        // decides what message to show the user.
        if (!resp.IsSuccessStatusCode)
            return null;

        // PaymentsApi returns { invoiceId, checkoutUrl } — map to the model record.
        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        var root = doc.RootElement;

        var invoiceId = root.TryGetProperty("invoiceId", out var id) ? id.GetString() : null;
        var checkoutUrl = root.TryGetProperty("checkoutUrl", out var cu) ? cu.GetString() : null;

        // If invoiceId is missing the response is unusable; return null so the
        // component shows the generic "could not create invoice" error message.
        return invoiceId is null ? null : new CreateInvoiceResult(invoiceId, checkoutUrl);
    }

    /// <inheritdoc />
    public async Task<InvoiceStatusResult?> GetInvoiceStatusAsync(string invoiceId)
    {
        // Uri.EscapeDataString prevents path-injection if the invoiceId ever
        // contains characters that would change the URL structure.
        var resp = await _http.GetAsync($"{_apiBase}/payments/invoice/{Uri.EscapeDataString(invoiceId)}");

        // A non-success response (e.g. 404 or 500) is treated as "no status"
        // so the poll loop in Shop.razor skips that tick quietly.
        if (!resp.IsSuccessStatusCode)
            return null;

        // PaymentsApi returns { invoiceId, status, additionalStatus }.
        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        var root = doc.RootElement;

        var id = root.TryGetProperty("invoiceId", out var idProp) ? idProp.GetString() : invoiceId;
        var status = root.TryGetProperty("status", out var s) ? s.GetString() ?? "Unknown" : "Unknown";
        var additionalStatus = root.TryGetProperty("additionalStatus", out var a) ? a.GetString() : null;

        return new InvoiceStatusResult(id ?? invoiceId, status, additionalStatus);
    }
}
