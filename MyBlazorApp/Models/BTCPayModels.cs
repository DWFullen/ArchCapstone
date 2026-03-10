namespace MyBlazorApp.Models;

// ---------------------------------------------------------------------------
// BTCPayModels — lightweight data-transfer records used by IBTCPayService and
// the Shop.razor component.  Using records (instead of classes) gives value
// equality for free, which simplifies any future unit-test assertions.
// ---------------------------------------------------------------------------

/// <summary>
/// Returned by <see cref="Services.IBTCPayService.CreateInvoiceAsync"/> when
/// PaymentsApi successfully creates an invoice on BTCPay Server.
///
/// InvoiceId  — the BTCPay invoice identifier, used for status polling.
/// CheckoutUrl — the hosted payment page URL that is loaded in the iframe modal.
/// </summary>
public record CreateInvoiceResult(string InvoiceId, string? CheckoutUrl);

/// <summary>
/// Returned by <see cref="Services.IBTCPayService.GetInvoiceStatusAsync"/> when
/// PaymentsApi fetches the current state of an existing invoice.
///
/// BTCPay Greenfield invoice lifecycle statuses:
///   New        — invoice created, waiting for customer to pay
///   Processing — payment broadcast on-chain but awaiting confirmations
///   Settled    — payment fully confirmed; consider the order paid
///   Expired    — the payment window elapsed before the customer paid
///   Invalid    — manually invalidated or a partial payment expired
/// </summary>
public record InvoiceStatusResult(string InvoiceId, string Status, string? AdditionalStatus)
{
    /// <summary>
    /// Returns true when payment is confirmed or in-progress enough to fulfil
    /// the order.  Shop.razor uses this to close the modal and show a success
    /// message without waiting for full on-chain confirmation.
    /// </summary>
    public bool IsPaid => Status is "Settled" or "Processing";

    /// <summary>
    /// Returns true when the invoice can no longer be paid.
    /// Shop.razor uses this to stop polling and show an expiry message.
    /// </summary>
    public bool IsExpiredOrInvalid => Status is "Expired" or "Invalid";
}
