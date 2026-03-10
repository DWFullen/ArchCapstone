PaymentsApi - Minimal API for creating and querying BTCPay invoices

This small project exposes endpoints used by the Blazor client:

- POST /api/payments/create-invoice  — Creates a new BTCPay invoice
- GET  /api/payments/invoice/{id}    — Returns the current status of an invoice

It calls your BTCPay Server (Greenfield API v1) and returns a JSON payload with
`invoiceId`, `checkoutUrl` (for create) or `status` / `additionalStatus` (for get).

## BTCPay Greenfield API

The [BTCPay Server Greenfield API](https://docs.btcpayserver.org/API/Greenfield/v1/) is a
REST API protected by an API key. This project reads the following values at runtime:

| Variable            | Description                                           |
|---------------------|-------------------------------------------------------|
| `BTCPAY_URL`        | Base URL of your BTCPay instance (e.g. `https://btcpay.example.com`) |
| `BTCPAY_STORE_ID`   | The store identifier found in BTCPay → Store Settings |
| `BTCPAY_API_KEY`    | An API key with `btcpay.store.cancreateinvoice` permission |

## Configuration

Set the values above as environment variables (recommended for production) **or** add them
to `appsettings.Development.json` for local development:

```json
{
  "BTCPAY_URL": "https://btcpay.example.com",
  "BTCPAY_STORE_ID": "your-store-id",
  "BTCPAY_API_KEY": "your-api-key"
}
```

## Run locally (PowerShell)

```powershell
$env:BTCPAY_URL      = 'https://btcpay.example.com'
$env:BTCPAY_STORE_ID = 'your-store-id'
$env:BTCPAY_API_KEY  = 'your-api-key'
dotnet run --project .\PaymentsApi\PaymentsApi.csproj
```

## Security

- Enable permissive CORS only during local development. In production restrict the
  `AllowAllDev` policy to your Blazor host's origin.
- Store secrets in a secure store (Azure Key Vault, GitHub Secrets, etc.) — never commit
  them to source control.
- Generate your API key in BTCPay → Account → Manage API Keys, granting only the
  `btcpay.store.cancreateinvoice` and `btcpay.store.canviewinvoices` permissions.

