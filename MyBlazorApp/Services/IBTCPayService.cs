using MyBlazorApp.Models;

namespace MyBlazorApp.Services;

// ---------------------------------------------------------------------------
// IBTCPayService
//
// WHY this interface exists:
//   The original Shop.razor component made raw HttpClient calls directly in
//   the component's @code block. That approach mixed UI logic with HTTP/API
//   concerns and made both sides harder to reason about. Extracting the BTCPay
//   calls into a service interface:
//     1. Keeps the Razor component focused on display and user interaction.
//     2. Makes the BTCPay logic independently testable (mock the interface).
//     3. Centralises the API base URL resolution in one place.
// ---------------------------------------------------------------------------
public interface IBTCPayService
{
    /// <summary>
    /// Creates a new invoice on BTCPay Server and returns the invoice id and
    /// the hosted checkout URL where the customer should be sent to pay.
    /// Returns null if the backend API call fails.
    /// </summary>
    Task<CreateInvoiceResult?> CreateInvoiceAsync(decimal amount, string currency, string orderId, string? returnUrl = null);

    /// <summary>
    /// Fetches the current lifecycle status of an existing BTCPay invoice.
    /// Used by the payment-status poll loop in Shop.razor.
    /// Returns null if the invoice cannot be retrieved (e.g. network error).
    /// </summary>
    Task<InvoiceStatusResult?> GetInvoiceStatusAsync(string invoiceId);
}
