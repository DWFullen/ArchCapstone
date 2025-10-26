PaymentsApi - Minimal API for creating BTCPay invoices

This small project exposes a single endpoint used by the Blazor client:

- POST /api/payments/create-invoice

It calls your BTCPay Server (Greenfield API) to create an invoice and returns a JSON payload with invoiceId and checkoutUrl.

Configuration
- Set the following environment variables (recommended) or place them in appsettings.Development.json for local dev:
  - BTCPAY_URL (e.g. https://btcpay.example.com)
  - BTCPAY_STORE_ID
  - BTCPAY_API_KEY (keep this secret)

Run locally (PowerShell):

```powershell
$env:BTCPAY_URL = 'https://btcpay.example.com'
$env:BTCPAY_STORE_ID = 'your-store-id'
$env:BTCPAY_API_KEY = 'your-api-key'
dotnet run --project .\PaymentsApi\PaymentsApi.csproj
```

Security
- The project enables permissive CORS for development. In production, restrict CORS to your site and store secrets in a secure store (Azure Key Vault, GitHub Secrets, etc.).
