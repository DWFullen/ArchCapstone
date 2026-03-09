namespace MyBlazorApp.Models;

/// <summary>Result returned by <see cref="Services.IBTCPayService.CreateInvoiceAsync"/>.</summary>
public record CreateInvoiceResult(string InvoiceId, string? CheckoutUrl);

/// <summary>Result returned by <see cref="Services.IBTCPayService.GetInvoiceStatusAsync"/>.</summary>
public record InvoiceStatusResult(string InvoiceId, string Status, string? AdditionalStatus)
{
    /// <summary>Returns true when the invoice has been settled (paid).</summary>
    public bool IsPaid => Status is "Settled" or "Processing";

    /// <summary>Returns true when the invoice has expired or been invalidated.</summary>
    public bool IsExpiredOrInvalid => Status is "Expired" or "Invalid";
}
