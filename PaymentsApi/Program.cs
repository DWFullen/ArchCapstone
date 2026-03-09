using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// CORS: in development allow any origin. In production restrict to your Blazor host.
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAllDev", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

app.UseCors("AllowAllDev");

// Helper: build an authenticated HttpClient for BTCPay Greenfield API
static (HttpClient? client, IResult? error) CreateBTCPayClient(IConfiguration config)
{
    var btcpayBase = config["BTCPAY_URL"] ?? Environment.GetEnvironmentVariable("BTCPAY_URL");
    var apiKey = config["BTCPAY_API_KEY"] ?? Environment.GetEnvironmentVariable("BTCPAY_API_KEY");

    if (string.IsNullOrWhiteSpace(btcpayBase) || string.IsNullOrWhiteSpace(apiKey))
        return (null, Results.Problem("BTCPay configuration is missing. Set BTCPAY_URL, BTCPAY_STORE_ID and BTCPAY_API_KEY.", statusCode: 500));

    var client = new HttpClient { BaseAddress = new Uri(btcpayBase.TrimEnd('/') + "/") };
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("token", apiKey);
    return (client, null);
}

// POST /api/payments/create-invoice
// Creates a new BTCPay invoice using the Greenfield v1 API.
app.MapPost("/api/payments/create-invoice", async (HttpContext http, IConfiguration config) =>
{
    var req = await JsonSerializer.DeserializeAsync<CreateInvoiceRequest>(
        http.Request.Body,
        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

    if (req is null)
        return Results.BadRequest("Invalid payload");

    var storeId = config["BTCPAY_STORE_ID"] ?? Environment.GetEnvironmentVariable("BTCPAY_STORE_ID");
    if (string.IsNullOrWhiteSpace(storeId))
        return Results.Problem("BTCPAY_STORE_ID is not configured.", statusCode: 500);

    var (client, configError) = CreateBTCPayClient(config);
    if (configError is not null) return configError;
    using var _ = client;

    var payload = new
    {
        amount = req.Amount,
        currency = req.Currency,
        metadata = new { orderId = req.OrderId },
        checkout = new { redirectUrl = req.ReturnUrl }
    };

    var json = JsonSerializer.Serialize(payload);
    using var content = new StringContent(json, Encoding.UTF8, "application/json");
    var resp = await client!.PostAsync($"api/v1/stores/{storeId}/invoices", content);

    if (!resp.IsSuccessStatusCode)
    {
        var errBody = await resp.Content.ReadAsStringAsync();
        return Results.Problem($"BTCPay error: {resp.StatusCode} {errBody}", statusCode: (int)resp.StatusCode);
    }

    // BTCPay Greenfield API v1 returns the invoice object directly (no `data` wrapper).
    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var root = doc.RootElement;

    var invoiceId = root.TryGetProperty("id", out var idProp) ? idProp.GetString() : null;
    string? checkoutUrl = null;
    if (root.TryGetProperty("checkoutLink", out var cl)) checkoutUrl = cl.GetString();

    if (string.IsNullOrEmpty(invoiceId))
        return Results.Problem("Unexpected BTCPay response: missing invoice id.", statusCode: 500);

    return Results.Ok(new { invoiceId, checkoutUrl });
});

// GET /api/payments/invoice/{invoiceId}
// Returns the current status of a BTCPay invoice.
app.MapGet("/api/payments/invoice/{invoiceId}", async (string invoiceId, IConfiguration config) =>
{
    var storeId = config["BTCPAY_STORE_ID"] ?? Environment.GetEnvironmentVariable("BTCPAY_STORE_ID");
    if (string.IsNullOrWhiteSpace(storeId))
        return Results.Problem("BTCPAY_STORE_ID is not configured.", statusCode: 500);

    var (client, configError) = CreateBTCPayClient(config);
    if (configError is not null) return configError;
    using var _ = client;

    var resp = await client!.GetAsync($"api/v1/stores/{storeId}/invoices/{invoiceId}");
    if (!resp.IsSuccessStatusCode)
    {
        var errBody = await resp.Content.ReadAsStringAsync();
        return Results.Problem($"BTCPay error: {resp.StatusCode} {errBody}", statusCode: (int)resp.StatusCode);
    }

    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var root = doc.RootElement;

    var status = root.TryGetProperty("status", out var s) ? s.GetString() : "Unknown";
    var additionalStatus = root.TryGetProperty("additionalStatus", out var a) ? a.GetString() : null;

    return Results.Ok(new { invoiceId, status, additionalStatus });
});

app.Run();

record CreateInvoiceRequest(decimal Amount, string Currency, string OrderId, string? ReturnUrl = null);
