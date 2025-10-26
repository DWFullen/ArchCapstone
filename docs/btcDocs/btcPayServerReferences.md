# Main Site
https://btcpayserver.org/

# Deployment Options
- [BTCPayServer Deployment Documentation](https://docs.btcpayserver.org/Deployment/)

# API Guide
- [Greenfield API – Notifications (Current User)](https://docs.btcpayserver.org/API/Greenfield/v1/#tag/Notifications-(Current-User))

# GitHub
- [BTCPayServer GitHub Repository](https://github.com/btcpayserver)

# Creating a Secure Connection

To securely connect your Azure Container Apps to a BTCPayServer instance hosted on LunaNode, follow these steps:

## 1. Configure BTCPayServer on LunaNode

- **Generate a Greenfield API Key:**
    1. Log in to your BTCPayServer instance on LunaNode.
    2. Navigate to **Account > Manage Account > API Keys**.
    3. Create a new API key. For production, restrict permissions to only what your app needs. For testing, "Unrestricted access" is acceptable.
    4. Save the generated API key securely for later use in Azure.

- **Expose BTCPayServer Securely with HTTPS:**
    - Use the domain provided by LunaNode (e.g., `btcpayXXXXXX.lndyn.com`) or configure a custom domain (e.g., `btcpay.your-domain.com`) by creating an A record in your DNS provider.
    - BTCPayServer will automatically configure SSL/TLS with Let's Encrypt for your domain.

## 2. Configure Azure Container App

- **Store the BTCPayServer API Key in Azure Key Vault:**
    1. Create an Azure Key Vault resource.
    2. Add a new secret containing your BTCPayServer API key.
    3. Create a Managed Identity for your Azure Container App.
    4. Assign the Managed Identity permissions to read secrets from the Key Vault.

- **Enable Secure Communication:**
    - Ensure your app uses the HTTPS endpoint of your BTCPayServer instance and includes the API key in the Authorization header.
    - Enable ingress for your container app if it needs to receive external traffic. Set `allowInsecure` to `false` to enforce HTTPS-only access.

- **Application Workflow Example:**
    1. On startup, use the Managed Identity to obtain a token for Azure Key Vault.
    2. Retrieve the BTCPayServer API key from Key Vault.
    3. When a payment is needed, call the BTCPayServer Greenfield API over HTTPS, including the API key in the Authorization header.
    4. Present the invoice data to the user.

## 3. Best Practices for Production

- **Virtual Network Integration:** Integrate your Container Apps Environment with a custom virtual network for secure, private communication.
- **IP Security Restrictions:** Configure IP restrictions on BTCPayServer to only allow traffic from your Azure Container Apps (requires a static IP on LunaNode).
- **Web Application Firewall (WAF):** Use Azure Application Gateway with WAF for public endpoints to protect against common web vulnerabilities.


https://github.com/btcpayserver/btcpayserver-doc/blob/master/docs/Development/GreenFieldExample.md