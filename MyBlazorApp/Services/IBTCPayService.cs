using MyBlazorApp.Models;

namespace MyBlazorApp.Services;

public interface IBTCPayService
{
    /// <summary>Creates a new BTCPay invoice and returns its id and hosted checkout URL.</summary>
    Task<CreateInvoiceResult?> CreateInvoiceAsync(decimal amount, string currency, string orderId, string? returnUrl = null);

    /// <summary>Returns the current status of an existing invoice.</summary>
    Task<InvoiceStatusResult?> GetInvoiceStatusAsync(string invoiceId);
}
