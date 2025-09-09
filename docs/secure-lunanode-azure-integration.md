# Secure Integration: LunaNode BTCPay Server & Azure

## Overview
This guide summarizes secure options for connecting a LunaNode-hosted BTCPay Server to Azure resources (e.g., Container App, Function App) for payment processing and automation.

---

## Integration Scenarios

### 1. Simple & Secure API Integration (Recommended for Most)
- **Use Case:** Only need to call BTCPay Server's HTTP API from Azure (no direct DB access).
- **Steps:**
  1. **HTTPS Only:** Ensure BTCPay API is accessible via HTTPS.
  2. **IP Allowlisting:** Restrict BTCPay API to accept requests only from Azure's outbound IP(s).
  3. **API Key Security:** Store BTCPay API keys in Azure Key Vault. Never hardcode secrets.
  4. **Firewall:** Block all other inbound traffic to BTCPay except from Azure.
- **No VPN or DB migration required.**

### 2. Full Hybrid Network (Advanced)
- **Use Case:** Need direct access to BTCPay's PostgreSQL DB or plan to migrate workloads to Azure.
- **Steps:**
  1. **Private Network on LunaNode:** Move DB to a private subnet, restrict access.
  2. **Azure VNet:** Place Azure resources in a private VNet/subnet.
  3. **Site-to-Site VPN:** Set up VPN between LunaNode and Azure VNet for secure, private connectivity.
  4. **Firewall/NSG:** Restrict all endpoints to only allow traffic from trusted IPs/subnets.
  5. **Key Vault:** Store all secrets in Azure Key Vault.
  6. **(Optional) Migrate DB:** Use pg_dump to migrate DB to Azure PostgreSQL if moving all workloads.

---

## Security Best Practices
- **Always use HTTPS/TLS** for all API and DB connections.
- **Restrict access** using firewall rules and NSGs on both LunaNode and Azure.
- **Store secrets** (API keys, connection strings) in Azure Key Vault.
- **Never expose backend endpoints or credentials** to the public or client-side code.
- **Log and monitor** all access and actions for auditing.

---

## Decision Table
| Scenario                | When to Use?                | Key Steps                      |
|-------------------------|-----------------------------|-------------------------------|
| API-only Integration    | Most integrations           | HTTPS, IP allowlist, Key Vault |
| Full Hybrid (VPN/DB)    | Direct DB or migration      | VPN, private subnets, Key Vault|

---

## Quick Checklist
- [ ] Use HTTPS for all connections
- [ ] Restrict BTCPay API to Azure IPs
- [ ] Store all secrets in Key Vault
- [ ] Never expose backend endpoints
- [ ] Use VPN only if direct DB access is needed

---

For most projects, API-only integration with strong network and secret controls is sufficient and much simpler to maintain.
