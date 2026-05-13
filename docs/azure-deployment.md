# Deploy to Azure App Service, Azure SQL Database, and Blob Storage

This project’s **API** is the Node.js app in `backend/`. Deploy that folder (or its contents) as the App Service site root so `package.json` and `npm start` resolve correctly. The **React Native** app in `frontend/` stays on users’ devices; point it at your App Service URL after deployment.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in: `az login`
- Node.js 18+ locally (for testing before deploy)

## 1. Resource group and region

Pick a region (examples use `eastus`; change if you prefer).

```bash
az group create --name rg-vet-booking --location eastus
```

## 2. Azure SQL Database

Create a logical server and database. Replace passwords and names as needed.

```bash
# SQL admin login (not your Azure AD account name unless you use AAD-only later)
SQL_ADMIN="sqladmin"
SQL_PASSWORD="<generate-a-strong-password>"

az sql server create \
  --name vet-booking-sql-<unique-suffix> \
  --resource-group rg-vet-booking \
  --location eastus \
  --admin-user "$SQL_ADMIN" \
  --admin-password "$SQL_PASSWORD"

az sql db create \
  --resource-group rg-vet-booking \
  --server vet-booking-sql-<unique-suffix> \
  --name vet-booking-db \
  --service-objective Basic
```

Allow Azure services (optional but convenient for App Service):

```bash
az sql server firewall-rule create \
  --resource-group rg-vet-booking \
  --server vet-booking-sql-<unique-suffix> \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

**Apply schema:** connect with [Azure Data Studio](https://learn.microsoft.com/en-us/azure-data-studio/download-azure-data-studio) or `sqlcmd` and run `database/schema.sql` against `vet-booking-db`.

**Connection string for App Service** (SQL authentication example):

```
Server=tcp:vet-booking-sql-<unique-suffix>.database.windows.net,1433;Initial Catalog=vet-booking-db;Persist Security Info=False;User ID=<SQL_ADMIN>;Password=<SQL_PASSWORD>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

Store this as an App Service application setting (see section 5). When you add a SQL client to the API (for example `mssql`), read this value from the environment variable you choose (for example `SQL_CONNECTION_STRING`).

## 3. Azure Blob Storage

```bash
az storage account create \
  --name vetbookingstore<unique-suffix> \
  --resource-group rg-vet-booking \
  --location eastus \
  --sku Standard_LRS

# Private container for uploads (adjust name as you like)
az storage container create \
  --account-name vetbookingstore<unique-suffix> \
  --name uploads \
  --auth-mode login
```

Get a connection string for the storage account (for server-side use in App Service):

```bash
az storage account show-connection-string \
  --name vetbookingstore<unique-suffix> \
  --resource-group rg-vet-booking \
  --query connectionString -o tsv
```

Store the result as an application setting (for example `AZURE_STORAGE_CONNECTION_STRING`). Use the [Azure Storage Blob SDK](https://www.npmjs.com/package/@azure/storage-blob) in the API when you implement uploads.

**Security:** prefer [managed identity](https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity) plus role assignment to the storage account instead of a full connection string when your code supports it.

## 4. App Service (Linux, Node)

Create an App Service plan and web app targeting Node 20 LTS.

```bash
az appservice plan create \
  --name plan-vet-booking \
  --resource-group rg-vet-booking \
  --location eastus \
  --is-linux \
  --sku B1

az webapp create \
  --name vet-booking-api-<unique-suffix> \
  --resource-group rg-vet-booking \
  --plan plan-vet-booking \
  --runtime "NODE:20-lts"
```

## 5. Application settings (environment variables)

In the portal: **App Service → Configuration → Application settings**, or CLI:

```bash
APP_NAME="vet-booking-api-<unique-suffix>"

az webapp config appsettings set \
  --resource-group rg-vet-booking \
  --name "$APP_NAME" \
  --settings \
    NODE_ENV=production \
    WEBSITES_NODE_DEFAULT_VERSION=~20 \
    JWT_SECRET="<use-a-long-random-secret>" \
    SQL_CONNECTION_STRING="<paste-adonet-style-connection-string>" \
    AZURE_STORAGE_CONNECTION_STRING="<paste-storage-connection-string>"
```

The API listens on `process.env.PORT`, which App Service sets automatically—do not override `PORT` in production unless you know you need to.

## 6. Deploy the API (backend folder only)

Oryx expects `package.json` at the **root of the deployed artifact**. Do **not** deploy the whole monorepo root unless you add a root-level `package.json` that starts the API.

**Option A — ZIP deploy from repo (PowerShell):**

```powershell
cd c:\Users\Admin\Desktop\ITEplss
.\scripts\package-backend.ps1
az webapp deploy --resource-group rg-vet-booking --name vet-booking-api-<unique-suffix> --src-path .\deploy-backend.zip --type zip
```

**Option B — GitHub Actions:** build a job that checks out the repo, `cd backend`, runs `npm ci --omit=dev`, zips the folder (including `node_modules` or run `npm install` on the server via Oryx—your choice), and uses [Azure/webapps-deploy](https://github.com/Azure/webapps-deploy) or `az webapp deploy`.

**Option C — VS Code:** install the “Azure App Service” extension, right-click `backend`, choose **Deploy to Web App**, and select the Linux Node app.

After deploy, open:

`https://vet-booking-api-<unique-suffix>.azurewebsites.net/health`

## 7. Point the mobile app at the API

Update the base URL in `frontend/src/services/api.js` to:

`https://<your-app-name>.azurewebsites.net/api/v1`

Rebuild the React Native app for device/emulator testing.

## 8. CORS (if the browser ever calls the API)

The React Native app does not rely on browser CORS. If you add a web client, configure CORS on App Service or in Express for your web origin.

## Checklist

| Step | Done |
|------|------|
| SQL server + database created | ☐ |
| `database/schema.sql` executed | ☐ |
| Storage account + container created | ☐ |
| App Service created (Linux Node 20) | ☐ |
| `JWT_SECRET`, SQL, and storage settings configured | ☐ |
| Deploy artifact = `backend/` root with `package.json` | ☐ |
| `/health` returns 200 | ☐ |
| Mobile app `api.js` base URL updated | ☐ |

## Notes on this codebase

- The API currently uses an **in-memory** store (`backend/src/data/store.js`). Azure SQL and Blob are ready from an infrastructure perspective; persisting data requires implementing a SQL client and blob uploads in the services layer (see `README.md` suggested next steps).
- Prefer **TLS** to SQL (`Encrypt=True`) and **secrets** in Key Vault for production hardening.
