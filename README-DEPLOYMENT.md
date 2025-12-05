# Azure Container App Deployment

This directory contains scripts and configurations to deploy the ASP.NET Core Weather API to Azure Container Apps.

## 📋 Prerequisites

Before running the deployment script, ensure you have:

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Docker Desktop** - [Install Docker](https://www.docker.com/products/docker-desktop) (must be running)
3. **Azure Subscription** - Active Azure account with appropriate permissions

## 🚀 Quick Start

### Option 1: Deploy with Default Settings

```powershell
cd c:\Develop\WeatherApi\asp_core\ASP_Core\ASP_Core
.\deploy-to-aca.ps1
```

This will create:

- Resource Group: `rg-weatherapi` in `eastus`
- Container Registry: `acrweatherapi`
- Container Apps Environment: `env-weatherapi`
- Container App: `weatherapi`

### Option 2: Deploy with Custom Settings

```powershell
.\deploy-to-aca.ps1 `
    -ResourceGroup "my-custom-rg" `
    -Location "westus" `
    -ContainerRegistry "myacr" `
    -Environment "my-env" `
    -AppName "myapp" `
    -ImageTag "v1.0.0"
```

### Option 3: Deploy to Current Production (Working Command)

```powershell
# Current production deployment - uses existing resources
.\deploy-to-aca.ps1 `
    -Environment "weatherapi-env" `
    -ResourceGroup "rg-weatherapi-prod-new" `
    -ContainerRegistry "weatherapi18375"
```

This deploys to the live environment at: **https://weatherapi.orangepond-7a8caa48.eastus.azurecontainerapps.io**

## 📝 Script Parameters

| Parameter           | Description                                       | Default          | Required |
| ------------------- | ------------------------------------------------- | ---------------- | -------- |
| `ResourceGroup`     | Azure Resource Group name                         | `rg-weatherapi`  | No       |
| `Location`          | Azure region                                      | `eastus`         | No       |
| `ContainerRegistry` | Container Registry name (must be globally unique) | `acrweatherapi`  | No       |
| `Environment`       | Container Apps Environment name                   | `env-weatherapi` | No       |
| `AppName`           | Container App name                                | `weatherapi`     | No       |
| `ImageTag`          | Docker image tag                                  | `latest`         | No       |

## 🔧 What the Script Does

1. **Prerequisites Check**

   - Verifies Azure CLI is installed
   - Verifies Docker is installed and running
   - Checks Azure login status

2. **Azure Resources Setup**

   - Creates Resource Group (if needed)
   - Creates Azure Container Registry (if needed)
   - Enables admin access on ACR

3. **Container Build & Push**

   - Builds Docker image from Dockerfile
   - Logs into Azure Container Registry
   - Pushes image to ACR

4. **Container Apps Deployment**

   - Creates Container Apps Environment (if needed)
   - Creates or updates Container App
   - Configures ingress on port 80
   - Sets auto-scaling (1-3 replicas)

5. **Output**
   - Displays application URL
   - Offers to open app in browser

## 📂 Files

- **`Dockerfile`** - Multi-stage Docker build configuration for ASP.NET Core 8.0
- **`.dockerignore`** - Excludes unnecessary files from Docker context
- **`deploy-to-aca.ps1`** - Main deployment script

## 🌐 Common Azure Regions

- `eastus` - East US
- `westus` - West US
- `westeurope` - West Europe
- `eastasia` - East Asia
- `australiaeast` - Australia East

## 💡 Tips

### Container Registry Naming

The Container Registry name must be:

- Globally unique across Azure
- 5-50 characters
- Only lowercase letters and numbers
- No hyphens or special characters

If you get a naming conflict, try: `acrweatherapi<uniqueid>`

### Cost Optimization

- The script creates a **Basic SKU** ACR (lowest cost tier)
- Container App uses **0.5 CPU / 1GB RAM** with **1-3 replicas**
- Delete resources when not needed: `az group delete --name <resource-group>`

### Viewing Logs

```powershell
# Stream logs from your container app
az containerapp logs show `
    --name weatherapi `
    --resource-group rg-weatherapi `
    --follow
```

### Updating the App

Simply run the script again with the same parameters. It will:

- Build a new Docker image
- Push to ACR
- Update the Container App with zero downtime

## 🔍 Troubleshooting

### "Docker daemon is not running"

- Start Docker Desktop and wait for it to fully initialize
- Check Docker icon in system tray shows "running"

### "Failed to create Azure Container Registry" (name conflict)

- Change the `ContainerRegistry` parameter to a unique name
- Example: `.\deploy-to-aca.ps1 -ContainerRegistry "acrweatherapi2024"`

### "Not logged in to Azure"

- The script will initiate login automatically
- Follow browser prompts to authenticate

### Build Errors

- Ensure you're in the correct directory containing `Dockerfile`
- Check that `ASP_Core.csproj` exists
- Verify .NET 8 SDK is referenced in Dockerfile

## 📱 Accessing Your App

After successful deployment, the script displays your app URL:

```
Application URL: https://weatherapi.<unique-id>.<region>.azurecontainerapps.io
```

You can also retrieve it later:

```powershell
az containerapp show `
    --name weatherapi `
    --resource-group rg-weatherapi `
    --query properties.configuration.ingress.fqdn `
    --output tsv
```

## 🧹 Cleanup

To delete all resources:

```powershell
az group delete --name rg-weatherapi --yes --no-wait
```

## 📚 Additional Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## ✅ Current Deployment

The Weather API is currently deployed and running:

**Live URL:** https://weatherapi.orangepond-7a8caa48.eastus.azurecontainerapps.io

**Deployment Command Used:**

```powershell
.\deploy-to-aca.ps1 -Environment "weatherapi-env" -ResourceGroup "rg-weatherapi-prod-new" -ContainerRegistry "weatherapi18375"
```

**Configuration:**

- **Resource Group:** `rg-weatherapi-prod-new` (East US)
- **Container Registry:** `weatherapi18375.azurecr.io`
- **Container Apps Environment:** `weatherapi-env`
- **Container App:** `weatherapi`

> **Note:** This deployment uses existing resources. The Container Registry is in a different resource group (`rg-weatherapi-prod-eastus2`) and the script correctly finds and uses it.

### Reusing Existing Resources

If you have existing Azure resources, you can specify them:

```powershell
# Use existing environment and registry
.\deploy-to-aca.ps1 `
    -Environment "your-existing-env" `
    -ResourceGroup "your-resource-group" `
    -ContainerRegistry "your-acr-name"
```

The script will:

- ✅ Find the ACR even if it's in a different resource group
- ✅ Use the existing Container Apps Environment
- ✅ Create or update the Container App in the specified resource group
