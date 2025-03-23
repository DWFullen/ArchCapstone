using Azure.Data.Tables;
using Microsoft.Extensions.Configuration;

public class ContainerRegistryService : IContainerRegistryService
{
    private readonly TableClient _tableClient;

    public ContainerRegistryService(IConfiguration configuration)
    {
        var connectionString = configuration["StorageConnectionString"];
        _tableClient = new TableClient(connectionString, "ContainerRegistry");
    }

    public async Task<ContainerMetadata> GetContainerAsync(string containerType, string containerName)
    {
        return await _tableClient.GetEntityAsync<ContainerMetadata>(
            partitionKey: containerType,
            rowKey: containerName
        );
    }

    public async Task<IEnumerable<ContainerMetadata>> ListContainersAsync(string containerType)
    {
        var query = _tableClient.QueryAsync<ContainerMetadata>(
            filter: $"PartitionKey eq '{containerType}'"
        );

        var results = new List<ContainerMetadata>();
        await foreach (var container in query)
        {
            results.Add(container);
        }
        return results;
    }

    public async Task UpdateContainerAsync(ContainerMetadata container)
    {
        container.LastAccessed = DateTime.UtcNow;
        await _tableClient.UpsertEntityAsync(container);
    }

    public async Task DeleteContainerAsync(string containerType, string containerName)
    {
        await _tableClient.DeleteEntityAsync(containerType, containerName);
    }

    public async Task<bool> ApproveContainerAsync(string containerType, string containerName)
    {
        var container = await GetContainerAsync(containerType, containerName);
        container.ApprovalStatus = "Approved";
        await UpdateContainerAsync(container);
        return true;
    }
}