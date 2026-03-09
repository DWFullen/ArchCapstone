namespace MyBlazorApp.Models;

public class ContainerMetadata
{
    public string RowKey { get; set; } = string.Empty;
    public string PartitionKey { get; set; } = string.Empty;
    public string ApprovalStatus { get; set; } = "Pending";
    public DateTime LastAccessed { get; set; } = DateTime.UtcNow;
    public string Version { get; set; } = "1.0";
    public string Tags { get; set; } = string.Empty;
}