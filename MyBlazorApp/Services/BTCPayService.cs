using Microsoft.Extensions.Configuration;
using MyBlazorApp.Models;
using System.Net.Http.Json;
using System.Text.Json;

namespace MyBlazorApp.Services;

/// <summary>
/// Calls the PaymentsApi backend to create and query BTCPay Server invoices.
/// The actual BTCPay Greenfield API requests are made server-side by PaymentsApi,
/// keeping the API key out of browser memory.
/// </summary>
public class BTCPayService : IBTCPayService
{
    private readonly HttpClient _http;
    private readonly string _apiBase;

    public BTCPayService(HttpClient http, IConfiguration configuration)
    {
        _http = http;
        var configuredBase = configuration["PAYMENT_API_BASE"];
        _apiBase = string.IsNullOrWhiteSpace(configuredBase)
            ? "/api"
            : configuredBase.TrimEnd('/');
    }

    /// <inheritdoc />
    public async Task<CreateInvoiceResult?> CreateInvoiceAsync(
        decimal amount, string currency, string orderId, string? returnUrl = null)
    {
        var payload = new
        {
            Amount = amount,
            Currency = currency,
            OrderId = orderId,
            ReturnUrl = returnUrl
        };

        var resp = await _http.PostAsJsonAsync($"{_apiBase}/payments/create-invoice", payload);
        if (!resp.IsSuccessStatusCode)
            return null;

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        var root = doc.RootElement;

        var invoiceId = root.TryGetProperty("invoiceId", out var id) ? id.GetString() : null;
        var checkoutUrl = root.TryGetProperty("checkoutUrl", out var cu) ? cu.GetString() : null;

        return invoiceId is null ? null : new CreateInvoiceResult(invoiceId, checkoutUrl);
    }

    /// <inheritdoc />
    public async Task<InvoiceStatusResult?> GetInvoiceStatusAsync(string invoiceId)
    {
        var resp = await _http.GetAsync($"{_apiBase}/payments/invoice/{Uri.EscapeDataString(invoiceId)}");
        if (!resp.IsSuccessStatusCode)
            return null;

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        var root = doc.RootElement;

        var id = root.TryGetProperty("invoiceId", out var idProp) ? idProp.GetString() : invoiceId;
        var status = root.TryGetProperty("status", out var s) ? s.GetString() ?? "Unknown" : "Unknown";
        var additionalStatus = root.TryGetProperty("additionalStatus", out var a) ? a.GetString() : null;

        return new InvoiceStatusResult(id ?? invoiceId, status, additionalStatus);
    }
}
