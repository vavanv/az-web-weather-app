<#
.SYNOPSIS
    Deploys an ASP.NET Core application to Azure Container Apps with remote ACR build.

.DESCRIPTION
    This script builds a Docker image directly in Azure Container Registry (ACR),
    and deploys it to Azure Container Apps. It creates all required Azure resources
    if they don't already exist. Unlike deploy-to-aca.ps1, this script builds the
    image remotely in ACR, eliminating the need for local Docker.

.PARAMETER ResourceGroup
    The name of the Azure Resource Group. Default: "weather-rg"

.PARAMETER Location
    The Azure region for resources. Default: "eastus"

.PARAMETER ContainerRegistry
    The name of the Azure Container Registry. Default: "arcforweatherapiweb"

.PARAMETER Environment
    The name of the Container Apps Environment. Default: "weatherapi-env"

.PARAMETER AppName
    The name of the Container App. Default: "weather-web"

.PARAMETER ImageTag
    The Docker image tag. Default: "latest"

.EXAMPLE
    .\remote.ps1

.EXAMPLE
    .\remote.ps1 -ResourceGroup "my-rg" -Location "westus" -AppName "myapp"

.EXAMPLE
    .\remote.ps1 -ImageTag "v1.0.0"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "weather-rg",

    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory=$false)]
    [string]$ContainerRegistry = "arcforweatherapiweb",

    [Parameter(Mandatory=$false)]
    [string]$Environment = "weatherapi-env",

    [Parameter(Mandatory=$false)]
    [string]$AppName = "weather-web",

    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest"
)

# Error handling
$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n==== $Message ====" -ForegroundColor Magenta
}

# Verify Azure CLI is installed
try {
    Write-Step "Verifying Prerequisites"
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    Write-Success "Azure CLI version: $($azVersion.'azure-cli')"
}
catch {
    Write-Error "Azure CLI is not installed or not in PATH"
    Write-Info "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Note: Docker is NOT required for remote builds
Write-Info "Remote build mode: Docker installation not required"

# Check if logged in to Azure
Write-Step "Checking Azure Login Status"
$account = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Not logged in to Azure"
    Write-Info "Initiating Azure login..."
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Azure login failed"
        exit 1
    }
}

$accountInfo = az account show --output json | ConvertFrom-Json
Write-Success "Logged in as: $($accountInfo.user.name)"
Write-Info "Subscription: $($accountInfo.name) ($($accountInfo.id))"

# Create Resource Group if it doesn't exist
Write-Step "Setting up Resource Group"
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Info "Creating resource group: $ResourceGroup in $Location"
    az group create --name $ResourceGroup --location $Location --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create resource group"
        exit 1
    }
    Write-Success "Resource group created"
}
else {
    Write-Success "Resource group already exists: $ResourceGroup"
}

# Create Azure Container Registry if it doesn't exist
Write-Step "Setting up Azure Container Registry"
$ErrorActionPreference = "Continue"
# First check if ACR exists anywhere
$acrInfo = az acr show --name $ContainerRegistry 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
$ErrorActionPreference = "Stop"

if ($LASTEXITCODE -eq 0 -and $acrInfo) {
    Write-Success "Azure Container Registry already exists: $ContainerRegistry"
    Write-Info "ACR is in resource group: $($acrInfo.resourceGroup)"
} else {
    Write-Info "Creating Azure Container Registry: $ContainerRegistry in $ResourceGroup"
    az acr create `
        --resource-group $ResourceGroup `
        --name $ContainerRegistry `
        --sku Basic `
        --admin-enabled true `
        --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create Azure Container Registry"
        exit 1
    }
    Write-Success "Azure Container Registry created"
}

# Get ACR login server
$acrLoginServer = "$ContainerRegistry.azurecr.io"
Write-Success "ACR Login Server: $acrLoginServer"

# Build Docker image remotely in ACR
Write-Step "Building Docker Image in ACR (Remote Build)"
$imageName = "${AppName}:$ImageTag"
Write-Info "Image name: $acrLoginServer/$imageName"
Write-Info "Building image remotely in Azure Container Registry..."

az acr build `
    --registry $ContainerRegistry `
    --image $imageName `
    --file Dockerfile `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Error "ACR build failed"
    exit 1
}
Write-Success "Docker image built successfully in ACR"

# Get ACR credentials for Container App deployment
Write-Step "Retrieving ACR Credentials"
$acrCredentials = az acr credential show --name $ContainerRegistry --output json | ConvertFrom-Json
$acrUsername = $acrCredentials.username
$acrPassword = $acrCredentials.passwords[0].value

# Create Container Apps Environment if it doesn't exist
Write-Step "Setting up Container Apps Environment"
$ErrorActionPreference = "Continue"
$null = az containerapp env show --name $Environment --resource-group $ResourceGroup 2>&1
$ErrorActionPreference = "Stop"
if ($LASTEXITCODE -ne 0) {
    Write-Info "Creating Container Apps Environment: $Environment"
    az containerapp env create `
        --name $Environment `
        --resource-group $ResourceGroup `
        --location $Location `
        --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create Container Apps Environment"
        exit 1
    }
    Write-Success "Container Apps Environment created"
}
else {
    Write-Success "Container Apps Environment already exists: $Environment"
}

# Deploy or update Container App
Write-Step "Deploying Container App"
$fullImageName = "$acrLoginServer/$imageName"
$ErrorActionPreference = "Continue"
$null = az containerapp show --name $AppName --resource-group $ResourceGroup 2>&1
$ErrorActionPreference = "Stop"

if ($LASTEXITCODE -ne 0) {
    Write-Info "Creating new Container App: $AppName"
    az containerapp create `
        --name $AppName `
        --resource-group $ResourceGroup `
        --environment $Environment `
        --image $fullImageName `
        --registry-server $acrLoginServer `
        --registry-username $acrUsername `
        --registry-password $acrPassword `
        --target-port 8080 `
        --ingress external `
        --min-replicas 1 `
        --max-replicas 3 `
        --cpu 0.5 `
        --memory 1.0Gi `
        --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create Container App"
        exit 1
    }
    Write-Success "Container App created successfully"
}
else {
    Write-Info "Updating existing Container App: $AppName"
    # First configure the registry
    Write-Info "Configuring registry credentials..."
    az containerapp registry set `
        --name $AppName `
        --resource-group $ResourceGroup `
        --server $acrLoginServer `
        --username $acrUsername `
        --password $acrPassword `
        --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to configure registry credentials"
        exit 1
    }

    # Then update the container image
    Write-Info "Updating container image..."
    az containerapp update `
        --name $AppName `
        --resource-group $ResourceGroup `
        --image $fullImageName `
        --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to update Container App"
        exit 1
    }
    Write-Success "Container App updated successfully"
}

# Get the app URL
Write-Step "Deployment Complete"
$appInfo = az containerapp show `
    --name $AppName `
    --resource-group $ResourceGroup `
    --output json | ConvertFrom-Json

$appUrl = "https://$($appInfo.properties.configuration.ingress.fqdn)"
Write-Success "Application URL: $appUrl"

Write-Host "`n" -NoNewline
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Deployment successful!                                        " -ForegroundColor Green
Write-Host "                                                                " -ForegroundColor Green
Write-Host "  App Name: $($AppName.PadRight(52)) " -ForegroundColor Green
Write-Host "  URL: $($appUrl.PadRight(56)) " -ForegroundColor Green
Write-Host "  Build Type: Remote (ACR)                                      " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# Optional: Open the URL in browser
$openBrowser = Read-Host "Open app in browser? (Y/N)"
if ($openBrowser -eq "Y" -or $openBrowser -eq "y") {
    Start-Process $appUrl
}
