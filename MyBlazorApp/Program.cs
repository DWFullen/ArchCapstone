using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using MyBlazorApp;
using MyBlazorApp.Services;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

// The default HttpClient is scoped to the Blazor app's own origin so that
// relative URLs like "/api/…" resolve correctly when the app is deployed.
builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) });
builder.Services.AddScoped<IContainerRegistryService, ContainerRegistryService>();

// Register the BTCPay service added as part of the payment integration.
// IBTCPayService is injected into Shop.razor and wraps all PaymentsApi HTTP calls,
// keeping payment logic out of the component and the BTCPay API key off the client.
builder.Services.AddScoped<IBTCPayService, BTCPayService>();

await builder.Build().RunAsync();
