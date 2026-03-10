using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

// ---------------------------------------------------------------------------
// PaymentsApi — minimal ASP.NET Core API that acts as a secure proxy between
// the Blazor WebAssembly front-end and the BTCPay Server Greenfield REST API.
//
// WHY a separate API project?
//   Blazor WebAssembly runs entirely in the browser, so any secret stored there
//   (like a BTCPay API key) would be visible to users. By keeping all BTCPay
//   calls here on the server, the API key never leaves the backend.
//
// Configuration (environment variables or appsettings.Development.json):
//   BTCPAY_URL       — base URL of your BTCPay instance (e.g. https://btcpay.example.com)
//   BTCPAY_STORE_ID  — store identifier from BTCPay → Store Settings
//   BTCPAY_API_KEY   — API key with cancreateinvoice + canviewinvoices permissions
// ---------------------------------------------------------------------------

var builder = WebApplication.CreateBuilder(args);

// CORS: in development allow any origin so the Blazor dev server (localhost:5173,
// :7xxx, etc.) can call this API freely.
// In production, replace AllowAnyOrigin() with .WithOrigins("https://your-site.com")
// so no other site can proxy requests through your BTCPay credentials.
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAllDev", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

app.UseCors("AllowAllDev");

// ---------------------------------------------------------------------------
// Helper: CreateBTCPayClient
//
// Extracted so both endpoints share the same config-reading and auth logic
// without duplicating code. Returns either a ready-to-use HttpClient or an
// IResult error that the caller can return directly.
//
// Config is read with a "config first, env var fallback" pattern so that
// appsettings.Development.json works locally while production uses proper
// environment variables or a secret store (e.g. Azure Key Vault).
// ---------------------------------------------------------------------------
static (HttpClient? client, IResult? error) CreateBTCPayClient(IConfiguration config)
{
    // Read BTCPAY_URL and BTCPAY_API_KEY; try IConfiguration first so local
    // appsettings.Development.json values are picked up during development.
    var btcpayBase = config["BTCPAY_URL"] ?? Environment.GetEnvironmentVariable("BTCPAY_URL");
    var apiKey = config["BTCPAY_API_KEY"] ?? Environment.GetEnvironmentVariable("BTCPAY_API_KEY");

    if (string.IsNullOrWhiteSpace(btcpayBase) || string.IsNullOrWhiteSpace(apiKey))
        return (null, Results.Problem("BTCPay configuration is missing. Set BTCPAY_URL, BTCPAY_STORE_ID and BTCPAY_API_KEY.", statusCode: 500));

    // TrimEnd('/') + "/" ensures the BaseAddress always ends with a slash,
    // which is required for relative path segments to resolve correctly with HttpClient.
    var client = new HttpClient { BaseAddress = new Uri(btcpayBase.TrimEnd('/') + "/") };

    // BTCPay Greenfield API uses "Authorization: token <apikey>" (not "Bearer").
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("token", apiKey);
    return (client, null);
}

// ---------------------------------------------------------------------------
// POST /api/payments/create-invoice
//
// Called by the Blazor Shop page when the user clicks "Pay with Bitcoin".
// Forwards the request to the BTCPay Greenfield v1 invoices endpoint and
// returns just the invoiceId and checkoutUrl that the front-end needs.
// ---------------------------------------------------------------------------
app.MapPost("/api/payments/create-invoice", async (HttpContext http, IConfiguration config) =>
{
    // Deserialize the JSON body sent by BTCPayService.CreateInvoiceAsync().
    // PropertyNameCaseInsensitive allows the Blazor client to send PascalCase
    // (Amount, Currency, …) while this record uses C# conventions.
    var req = await JsonSerializer.DeserializeAsync<CreateInvoiceRequest>(
        http.Request.Body,
        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

    if (req is null)
        return Results.BadRequest("Invalid payload");

    // BTCPAY_STORE_ID is needed for the Greenfield URL path, so validate it
    // separately from the shared client helper.
    var storeId = config["BTCPAY_STORE_ID"] ?? Environment.GetEnvironmentVariable("BTCPAY_STORE_ID");
    if (string.IsNullOrWhiteSpace(storeId))
        return Results.Problem("BTCPAY_STORE_ID is not configured.", statusCode: 500);

    var (client, configError) = CreateBTCPayClient(config);
    if (configError is not null) return configError;
    using var _ = client; // dispose the HttpClient when this request is done

    // Build the Greenfield invoice payload.
    // Field names must be camelCase to match the BTCPay API schema.
    var payload = new
    {
        amount = req.Amount,
        currency = req.Currency,
        metadata = new { orderId = req.OrderId },         // orderId surfaces in the BTCPay dashboard
        checkout = new { redirectUrl = req.ReturnUrl }    // where BTCPay redirects after payment
    };

    var json = JsonSerializer.Serialize(payload);
    using var content = new StringContent(json, Encoding.UTF8, "application/json");

    // Greenfield v1 endpoint: POST /api/v1/stores/{storeId}/invoices
    var resp = await client!.PostAsync($"api/v1/stores/{storeId}/invoices", content);

    if (!resp.IsSuccessStatusCode)
    {
        // Surface the BTCPay error body so it appears in logs / the browser console.
        var errBody = await resp.Content.ReadAsStringAsync();
        return Results.Problem($"BTCPay error: {resp.StatusCode} {errBody}", statusCode: (int)resp.StatusCode);
    }

    // BUG FIX (vs. the original code):
    // The original code expected the invoice to be nested under a "data" key:
    //   if (!root.TryGetProperty("data", out var data)) ...
    //
    // The BTCPay Greenfield API v1 returns the invoice object *directly* at the
    // response root — there is no "data" wrapper. That bug caused every invoice
    // creation to fail with "Unexpected BTCPay response shape." even when BTCPay
    // returned a valid 200 response. The fix reads "id" and "checkoutLink" from
    // the root element instead.
    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var root = doc.RootElement;

    var invoiceId = root.TryGetProperty("id", out var idProp) ? idProp.GetString() : null;
    string? checkoutUrl = null;
    if (root.TryGetProperty("checkoutLink", out var cl)) checkoutUrl = cl.GetString();

    if (string.IsNullOrEmpty(invoiceId))
        return Results.Problem("Unexpected BTCPay response: missing invoice id.", statusCode: 500);

    // Return only what the Blazor front-end needs; the full invoice object is not exposed.
    return Results.Ok(new { invoiceId, checkoutUrl });
});

// ---------------------------------------------------------------------------
// GET /api/payments/invoice/{invoiceId}
//
// NEW endpoint added as part of the BTCPay integration.
//
// The Blazor Shop page polls this endpoint every 5 seconds after opening the
// BTCPay checkout modal. When the status becomes "Settled" (or "Processing"),
// the modal is closed and a confirmation message is shown. If the invoice
// "Expires" or becomes "Invalid", an expiry message is shown instead.
//
// BTCPay invoice statuses (Greenfield v1):
//   New        — created, waiting for payment
//   Processing — payment seen on-chain but not yet confirmed
//   Settled    — payment fully confirmed
//   Expired    — payment window passed without payment
//   Invalid    — manually marked invalid or partially paid past expiry
// ---------------------------------------------------------------------------
app.MapGet("/api/payments/invoice/{invoiceId}", async (string invoiceId, IConfiguration config) =>
{
    var storeId = config["BTCPAY_STORE_ID"] ?? Environment.GetEnvironmentVariable("BTCPAY_STORE_ID");
    if (string.IsNullOrWhiteSpace(storeId))
        return Results.Problem("BTCPAY_STORE_ID is not configured.", statusCode: 500);

    var (client, configError) = CreateBTCPayClient(config);
    if (configError is not null) return configError;
    using var _ = client;

    // Greenfield v1 endpoint: GET /api/v1/stores/{storeId}/invoices/{invoiceId}
    var resp = await client!.GetAsync($"api/v1/stores/{storeId}/invoices/{invoiceId}");
    if (!resp.IsSuccessStatusCode)
    {
        var errBody = await resp.Content.ReadAsStringAsync();
        return Results.Problem($"BTCPay error: {resp.StatusCode} {errBody}", statusCode: (int)resp.StatusCode);
    }

    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var root = doc.RootElement;

    // "status" is the primary lifecycle state (see values above).
    // "additionalStatus" carries extra detail such as "PaidLate" or "MarkedInvalid".
    var status = root.TryGetProperty("status", out var s) ? s.GetString() : "Unknown";
    var additionalStatus = root.TryGetProperty("additionalStatus", out var a) ? a.GetString() : null;

    return Results.Ok(new { invoiceId, status, additionalStatus });
});

app.Run();

// ---------------------------------------------------------------------------
// CreateInvoiceRequest — record that maps the JSON body sent by the Blazor
// front-end. The nullable ReturnUrl lets the checkout page know where to send
// the user after a completed (or cancelled) payment.
// ---------------------------------------------------------------------------
record CreateInvoiceRequest(decimal Amount, string Currency, string OrderId, string? ReturnUrl = null);
