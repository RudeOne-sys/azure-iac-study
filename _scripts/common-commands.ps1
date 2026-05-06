# ─────────────────────────────────────────
# DEPLOY COMMANDS
# ─────────────────────────────────────────

# Trigger dev deployment manually (from dev branch)
gh workflow run deploy-infrastructure.yml

# Watch any pipeline run
gh run watch

# ─────────────────────────────────────────
# TEARDOWN COMMANDS
# ─────────────────────────────────────────

# Teardown both environments
gh workflow run teardown.yml --field environment=both --field confirm=CONFIRM

# Teardown dev only
gh workflow run teardown.yml --field environment=dev --field confirm=CONFIRM

# Teardown prod only
gh workflow run teardown.yml --field environment=prod --field confirm=CONFIRM

# Teardown dev manually via Azure CLI
az group delete --name rg-iac-dev --yes
az group create --name rg-iac-dev --location southafricanorth

# Teardown prod manually via Azure CLI
az group delete --name rg-iac-prod --yes
az group create --name rg-iac-prod --location southafricanorth

# ─────────────────────────────────────────
# PULL REQUEST COMMANDS
# ─────────────────────────────────────────

# Create PR from dev to main
gh pr create --base main --head dev --title "feat: " --body ""

# Merge open PR
gh pr merge --merge --delete-branch=false

# List open PRs
gh pr list

# ─────────────────────────────────────────
# GIT COMMANDS
# ─────────────────────────────────────────

# Add, commit and push
git add .
git commit -m "feat: "
git push

# Pull latest with merge (no prompts)
git pull origin dev --no-rebase --no-edit

# Check branch status
git status
git branch

# Switch to dev branch
git checkout dev

# Switch to main branch
git checkout main

# ─────────────────────────────────────────
# AZURE CLI COMMANDS
# ─────────────────────────────────────────

# Login and set subscription
az login
az account set --subscription (az account show --query id -o tsv)

# Confirm active subscription
az account show --output table

# Check resource groups
az group list --output table

# List all resources in dev
az resource list --resource-group rg-iac-dev --output table

# List all resources in prod
az resource list --resource-group rg-iac-prod --output table

# View deployment history for dev
az deployment group list `
  --resource-group rg-iac-dev `
  --query "[].{name:name, state:properties.provisioningState, timestamp:properties.timestamp, mode:properties.mode}" `
  --output table

# View deployment history for prod
az deployment group list `
  --resource-group rg-iac-prod `
  --query "[].{name:name, state:properties.provisioningState, timestamp:properties.timestamp, mode:properties.mode}" `
  --output table

# ─────────────────────────────────────────
# BICEP TESTING - NO DEPLOYMENT NEEDED
# ─────────────────────────────────────────

# Lint only - syntax check, no Azure connection needed
az bicep build --file deployments/storage.bicep
az bicep build --file deployments/compute.bicep
az bicep build --file deployments/hubSpoke.bicep
az bicep build --file deployments/nsg.bicep
az bicep build --file deployments/firewall.bicep
az bicep build --file deployments/loadBalancing.bicep
az bicep build --file deployments/hybridConnectivity.bicep
az bicep build --file deployments/privateEndpoints.bicep

# Lint all templates at once
Get-ChildItem deployments/*.bicep | ForEach-Object { az bicep build --file $_.FullName }

# ─────────────────────────────────────────
# WHAT-IF COMMANDS - VALIDATES WITHOUT DEPLOYING
# ─────────────────────────────────────────

# Storage What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/storage.bicep `
  --parameters environments/dev/storage.parameters.json `
  --mode Incremental

# Compute What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/compute.bicep `
  --parameters environments/dev/compute.parameters.json `
  --mode Incremental

# Hub & Spoke What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/hubSpoke.bicep `
  --parameters environments/dev/hubSpoke.parameters.json `
  --mode Incremental

# NSG What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/nsg.bicep `
  --parameters environments/dev/nsg.parameters.json `
  --mode Incremental

# Firewall What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/firewall.bicep `
  --parameters environments/dev/firewall.parameters.json `
  --mode Incremental

# Load Balancing What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/loadBalancing.bicep `
  --parameters environments/dev/loadBalancing.parameters.json `
  --mode Incremental

# Hybrid Connectivity What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/hybridConnectivity.bicep `
  --parameters environments/dev/hybridConnectivity.parameters.json `
  --mode Incremental

# Private Endpoints What-If DEV
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/privateEndpoints.bicep `
  --parameters environments/dev/privateEndpoints.parameters.json `
  --mode Incremental

# Complete mode What-If (shows what WOULD be deleted - use with caution)
az deployment group what-if `
  --resource-group rg-iac-dev `
  --template-file deployments/storage.bicep `
  --parameters environments/dev/storage.parameters.json `
  --mode Complete

# ─────────────────────────────────────────
# SINGLE TEMPLATE DEPLOY - TEST IN ISOLATION
# ─────────────────────────────────────────

# Deploy storage only to dev
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/storage.bicep `
  --parameters environments/dev/storage.parameters.json `
  --mode Incremental `
  --name "storage-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy compute only to dev
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/compute.bicep `
  --parameters environments/dev/compute.parameters.json `
  --mode Incremental `
  --name "compute-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy hub & spoke only to dev
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/hubSpoke.bicep `
  --parameters environments/dev/hubSpoke.parameters.json `
  --mode Incremental `
  --name "hubspoke-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy NSGs only to dev
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/nsg.bicep `
  --parameters environments/dev/nsg.parameters.json `
  --mode Incremental `
  --name "nsg-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy firewall only to dev (takes 8-10 mins)
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/firewall.bicep `
  --parameters environments/dev/firewall.parameters.json `
  --mode Incremental `
  --name "firewall-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy load balancing only to dev (takes 6-8 mins)
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/loadBalancing.bicep `
  --parameters environments/dev/loadBalancing.parameters.json `
  --mode Incremental `
  --name "lb-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy hybrid connectivity only to dev (takes 25-45 mins)
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/hybridConnectivity.bicep `
  --parameters environments/dev/hybridConnectivity.parameters.json `
  --mode Incremental `
  --name "vpn-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Deploy private endpoints only to dev
az deployment group create `
  --resource-group rg-iac-dev `
  --template-file deployments/privateEndpoints.bicep `
  --parameters environments/dev/privateEndpoints.parameters.json `
  --mode Incremental `
  --name "pe-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# ─────────────────────────────────────────
# FEDERATED CREDENTIAL COMMANDS
# ─────────────────────────────────────────

# Set object ID variable
$objectId = "e808f8fa-4714-496f-b2fd-9f76272c8f16"

# List federated credentials
az ad app federated-credential list --id $objectId --query "[].{name:name, subject:subject}"

# Get current federated credential IDs
az ad app federated-credential list --id $objectId --query "[].{name:name, id:id}"

# ─────────────────────────────────────────
# SERVICE PRINCIPAL COMMANDS
# ─────────────────────────────────────────

# Get SP app ID
az ad sp list --display-name "sp-github-iac" --query "[0].appId" -o tsv

# Get current subscription ID
az account show --query id -o tsv

# Get current tenant ID
az account show --query tenantId -o tsv

# Grant SP subscription level contributor (required for RG creation)
$subId = (az account show --query id -o tsv)
$appId = (az ad sp list --display-name "sp-github-iac" --query "[0].appId" -o tsv)
az role assignment create `
  --assignee $appId `
  --role Contributor `
  --scope /subscriptions/$subId