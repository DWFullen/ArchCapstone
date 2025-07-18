using MyBlazorApp.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MyBlazorApp.Services
{
    public interface IContainerRegistryService
    {
        Task<ContainerMetadata> GetContainerAsync(string containerType, string containerName);
        Task<IEnumerable<ContainerMetadata>> ListContainersAsync(string containerType);
        Task UpdateContainerAsync(ContainerMetadata container);
        Task DeleteContainerAsync(string containerType, string containerName);
        Task<bool> ApproveContainerAsync(string containerType, string containerName);
    }
}