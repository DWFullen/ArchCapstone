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

app.MapPost("/api/payments/create-invoice", async (HttpContext http) =>
{
    var req = await JsonSerializer.DeserializeAsync<CreateInvoiceRequest>(http.Request.Body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
    if (req is null)
        return Results.BadRequest("Invalid payload");

    // Read config from appsettings or environment variables
    var btcpayBase = builder.Configuration["BTCPAY_URL"] ?? Environment.GetEnvironmentVariable("BTCPAY_URL");
    var storeId = builder.Configuration["BTCPAY_STORE_ID"] ?? Environment.GetEnvironmentVariable("BTCPAY_STORE_ID");
    var apiKey = builder.Configuration["BTCPAY_API_KEY"] ?? Environment.GetEnvironmentVariable("BTCPAY_API_KEY");

    if (string.IsNullOrWhiteSpace(btcpayBase) || string.IsNullOrWhiteSpace(storeId) || string.IsNullOrWhiteSpace(apiKey))
        return Results.Problem("BTCPay configuration is missing. Set BTCPAY_URL, BTCPAY_STORE_ID and BTCPAY_API_KEY.", statusCode: 500);

    using var client = new HttpClient { BaseAddress = new Uri(btcpayBase) };
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("token", apiKey);

    var payload = new
    {
        amount = req.Amount,
        currency = req.Currency,
        metadata = new { orderId = req.OrderId },
        checkout = new
        {
            redirectUrl = req.ReturnUrl
        }
    };

    var json = JsonSerializer.Serialize(payload);
    using var content = new StringContent(json, Encoding.UTF8, "application/json");
    var resp = await client.PostAsync($"/api/v1/stores/{storeId}/invoices", content);
    if (!resp.IsSuccessStatusCode)
    {
        var body = await resp.Content.ReadAsStringAsync();
        return Results.Problem($"BTCPay error: {resp.StatusCode} {body}", statusCode: (int)resp.StatusCode);
    }

    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var root = doc.RootElement;
    // Greenfield responses can vary across versions; this reads common fields under `data`
    if (!root.TryGetProperty("data", out var data))
        return Results.Problem("Unexpected BTCPay response shape.", statusCode: 500);

    var invoiceId = data.GetProperty("id").GetString();
    string? checkoutUrl = null;
    if (data.TryGetProperty("checkoutLink", out var cl)) checkoutUrl = cl.GetString();
    else if (data.TryGetProperty("url", out var u)) checkoutUrl = u.GetString();

    return Results.Ok(new { invoiceId, checkoutUrl });
});

app.Run();

record CreateInvoiceRequest(decimal Amount, string Currency, string OrderId, string? ReturnUrl = null);
