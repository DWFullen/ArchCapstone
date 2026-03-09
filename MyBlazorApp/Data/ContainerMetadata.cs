using Azure;
using Azure.Data.Tables;

public class ContainerMetadata : ITableEntity
{
    public string PartitionKey { get; set; } = default!;
    public string RowKey { get; set; } = default!;
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }

    // Custom properties
    public string ImageReference { get; set; } = default!;
    public string ApprovalStatus { get; set; } = "Pending";
    public DateTime LastAccessed { get; set; }
    public DateTime CreatedDate { get; set; }
    public string Tags { get; set; } = default!;
    public string Version { get; set; } = "1.0";
}