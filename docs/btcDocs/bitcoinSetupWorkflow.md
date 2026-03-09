bash
bash
bash
csharp
bash
bash
ruby

# Bitcoin Testnet Setup & Blazor Integration Workflow

## 🧱 Step 1: Set Up a Bitcoin Testnet Wallet

You need a wallet that supports Testnet and HD (hierarchical deterministic) address generation. Recommended options:

- **Electrum** (start with `electrum --testnet`)
- **Bitcoin Core** (run with `-testnet` flag)
- **Sparrow Wallet** (simple UI + Testnet support)

> **Tip:** Keep your xpub (extended public key) handy if using an HD wallet.

---

## ⚙️ Step 2: Install and Run a Bitcoin Testnet Node (Optional but Recommended)

Running your own node allows you to:
- Monitor transactions
- Fetch balances and block data

**Install Bitcoin Core and run:**
```bash
bitcoind -testnet -daemon
```

**Check status:**
```bash
bitcoin-cli -testnet getblockchaininfo
```
Let it fully sync with the Testnet blockchain.

---

## 🔧 Step 3: Generate Addresses in Blazor (.NET)

You can use a .NET Bitcoin library like **NBitcoin** (supports Testnet, HD wallets, address generation, transaction building, and more).

**Install NBitcoin via NuGet:**
```bash
dotnet add package NBitcoin
```

**Sample C# code to generate a new Testnet address:**
```csharp
using NBitcoin;

var network = Network.TestNet;
var key = new Key(); // Generates a new private key
var address = key.PubKey.GetAddress(ScriptPubKeyType.Legacy, network);

Console.WriteLine($"New Testnet Address: {address}");
```
You can generate one per order for tracking payments.

---

## 📡 Step 4: Monitor for Incoming Payments

You have a few options:

### A. Use your own node
- Use `bitcoin-cli` or JSON-RPC to monitor addresses:
    ```bash
    bitcoin-cli -testnet getreceivedbyaddress "your_testnet_address"
    ```
- Or subscribe to wallet events with RPC:
    ```bash
    bitcoin-cli -testnet listtransactions
    ```
- Enable RPC in `bitcoin.conf`:
    ```ini
    testnet=1
    server=1
    rpcuser=youruser
    rpcpassword=yourpassword
    ```

### B. Use a third-party Testnet API (for dev only)
- Blockstream Testnet Explorer API
- Mempool.space Testnet API

**Example:**
```
https://blockstream.info/testnet/api/address/your_testnet_address/txs
```

---

## 🧪 Step 5: Send Testnet Coins to Test Address

Use a faucet to get free Testnet BTC:
- https://testnet-faucet.com
- https://bitcoinfaucet.uo1.net/

---

## 🌐 Step 6: Blazor UI Integration

**Backend (ASP.NET Core):**
- Create a controller or service to:
    - Generate a new address per order
    - Store it with the order record
    - Poll address or node for payments
    - Mark order as paid on sufficient confirmations

**Frontend (Blazor):**
- Display the payment address and QR code:
    ```html
    <img src="https://api.qrserver.com/v1/create-qr-code/?data=bitcoin:{address}&size=200x200" />
    <p>Send BTC to: <strong>@address</strong></p>
    ```

---

## ✅ Summary Checklist

| Task                   | Status                |
|------------------------|-----------------------|
| Bitcoin Testnet wallet | Electrum or Sparrow   |
| Bitcoin node (optional)| bitcoind -testnet     |
| C# library             | NBitcoin              |
| Address generation     | Per-order addresses   |
| Blockchain monitoring  | RPC or public API     |
| Faucet BTC             | Test payments         |
| Blazor UI              | Show address & QR, handle status |

