BTCPayServer url
https://btcpay263134.lndyn.com/

On LunaNode VM:

Add a firewall rule (or equivalent Network Security Group) to whitelist inbound traffic from:
The public IP ranges of your Azure Container App Environment (CAE)
The VNet/subnet ranges for your Azure Storage Account and Function App

On Azure side:

Ensure your Azure resources (Storage Account, Function App, CAE) allow inbound traffic from your LunaNode VM’s public IP.
If using private endpoints, you may need a VPN or ExpressRoute for direct private connectivity.