## User Request
Break down the following large tasks into a detailed action plan:
- Secure the Connection between Luna Node and Azure Application
- Write code in the function app to capture an HTTP response from BTCPay Server when a transaction is processed, then send an email with a file from the storage account to the user who purchased it, securely.
- Update the Web Application with the API for the BTCPay server to enable BTC payments.

---

## Action Plan

### 1. Secure the Connection between Luna Node and Azure Application
- [ ] 1.1 Identify all Azure endpoints/services Luna Node must access (Function App, Storage, etc.)
  - [ ] CAE 48.216.147.214
  - [ ] 
- [ ] 1.2 Document Luna Node’s public IP(s) and required ports/protocols
- [ ] 1.3 Restrict Azure endpoints to allow only Luna Node’s IP (NSG, firewall, or access rules)
- [ ] 1.4 Evaluate and, if feasible, set up VPN or Azure Private Link for private connectivity
- [ ] 1.5 Ensure all endpoints enforce HTTPS/TLS
- [ ] 1.6 Store any shared secrets/API keys in Azure Key Vault
- [ ] 1.7 Test connectivity and verify only Luna Node can access protected endpoints

### 2. Function App: Capture BTCPay HTTP Response, Email File from Storage
- [ ] 2.1 Design HTTP-triggered Azure Function endpoint for BTCPay webhook/callback
- [ ] 2.2 Implement request validation (e.g., BTCPay signature or shared secret)
- [ ] 2.3 Parse transaction details from BTCPay webhook payload
- [ ] 2.4 Map transaction to purchased file in Azure Storage
- [ ] 2.5 Use Azure SDK to securely access/download the file
- [ ] 2.6 Integrate with secure email service (SendGrid, Microsoft Graph, etc.)
- [ ] 2.7 Send file as email attachment to purchaser (do not expose direct storage URLs)
- [ ] 2.8 Log all actions securely for auditing
- [ ] 2.9 Test end-to-end: simulate BTCPay webhook, verify email delivery

### 3. Update Web App: Integrate BTCPay API for BTC Payments
- [ ] 3.1 Add “Pay with Bitcoin” option to web app UI
- [ ] 3.2 Implement backend logic to create BTCPay invoices via API (do not expose API keys client-side)
- [ ] 3.3 Display payment request (QR code, address) to user
- [ ] 3.4 Poll or listen for payment confirmation (via BTCPay API or webhook)
- [ ] 3.5 On payment confirmation, trigger file delivery process (call function app/backend)
- [ ] 3.6 Ensure all sensitive operations and API keys are handled server-side
- [ ] 3.7 Test full payment and delivery workflow

---

## Task Tracking

- [ ] 1.1 Identify all Azure endpoints/services Luna Node must access
- [ ] 1.2 Document Luna Node’s public IP(s) and required ports/protocols
- [ ] 1.3 Restrict Azure endpoints to allow only Luna Node’s IP
- [ ] 1.4 Evaluate and, if feasible, set up VPN or Azure Private Link
- [ ] 1.5 Ensure all endpoints enforce HTTPS/TLS
- [ ] 1.6 Store any shared secrets/API keys in Azure Key Vault
- [ ] 1.7 Test connectivity and verify only Luna Node can access endpoints
- [ ] 2.1 Design HTTP-triggered Azure Function endpoint for BTCPay webhook
- [ ] 2.2 Implement request validation for BTCPay webhook
- [ ] 2.3 Parse transaction details from webhook payload
- [ ] 2.4 Map transaction to purchased file in Azure Storage
- [ ] 2.5 Use Azure SDK to securely access/download file
- [ ] 2.6 Integrate with secure email service
- [ ] 2.7 Send file as email attachment to purchaser
- [ ] 2.8 Log all actions securely
- [ ] 2.9 Test end-to-end webhook and email delivery
- [ ] 3.1 Add “Pay with Bitcoin” option to web app UI
- [ ] 3.2 Implement backend logic to create BTCPay invoices via API
- [ ] 3.3 Display payment request to user
- [ ] 3.4 Poll or listen for payment confirmation
- [ ] 3.5 On payment confirmation, trigger file delivery process
- [ ] 3.6 Ensure all sensitive operations and API keys are server-side
- [ ] 3.7 Test full payment and delivery workflow