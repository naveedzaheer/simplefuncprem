export APP_PE_DEMO_RG=nz2807win-funcdemo-rg
export LOCATION=eastus2  
export DEMO_VNET=nz2807win-funcdemo-vnet
export DEMO_VNET_CIDR=10.1.0.0/16
export DEMO_VNET_APP_SUBNET=app_subnet
export DEMO_VNET_APP_SUBNET_CIDR=10.1.1.0/24
export DEMO_VNET_PL_SUBNET=pl_subnet
export DEMO_VNET_PL_SUBNET_CIDR=10.1.2.0/24

export DEMO_FUNC_PLAN=nz2807win-prem-func-plan
export DEMO_APP_STORAGE_ACCT=nz2807winappsstore
export DEMO_FUNC_STORAGE_ACCT=nz2807winfuncstore
export DEMO_FUNC_NAME=nz2807win-demofunc-app
export DEMO_APP_STORAGE_CONFIG="FileStore"

export DEMO_APP_VM=pldemovm
export DEMO_APP_VM_ADMIN=azureuser
export DEMO_VM_IMAGE=MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest
export DEMO_VM_SIZE=Standard_DS2_v2
export DEMO_APP_KV=nz2807win-demo-kv1

export KV_SECRET_APP_MESSAGE="APP-MESSAGE"
export KV_SECRET_APP_MESSAGE_VALUE="This is a test app message"
export KV_SECRET_APP_MESSAGE_VAR="APP_MESSAGE"
export KV_SECRET_APP_KV_NAME_VAR="KV_NAME"

# Create Resource Group
az group create -l $LOCATION -n $APP_PE_DEMO_RG

# Create VNET and App Service delegated Subnet
az network vnet create -g $APP_PE_DEMO_RG -n $DEMO_VNET --address-prefix $DEMO_VNET_CIDR \
 --subnet-name $DEMO_VNET_APP_SUBNET --subnet-prefix $DEMO_VNET_APP_SUBNET_CIDR

# Create Subnet to create PL, VMs etc.
az network vnet subnet create -g $APP_PE_DEMO_RG --vnet-name $DEMO_VNET -n $DEMO_VNET_PL_SUBNET \
    --address-prefixes $DEMO_VNET_PL_SUBNET_CIDR

# Create VM to host
# - DNS
# - NodeJS
# - VS Code
# - Azure CLI
# az vm create -n $DEMO_APP_VM -g $APP_PE_DEMO_RG --image MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest \
#    --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET --public-ip-sku Standard --size $DEMO_VM_SIZE --admin-username $DEMO_APP_VM_ADMIN

# Capture public IP of the jump/DNS box
# 52.188.33.128

# Install VS Code - https://code.visualstudio.com/download
# Setup Local environment to create Functions - https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli?tabs=bash%2Cbrowser&pivots=programming-language-javascript#configure-your-local-environment
# Setup DNS server
# Windows DNS Server - https://www.wintelpro.com/install-and-configure-dns-on-windows-server-2019/


################ Complete the VM Setup before moving next #######################

# Create the storage account to be used by all the functions for housekeeping
az storage account create --name $DEMO_FUNC_STORAGE_ACCT --location $LOCATION --resource-group $APP_PE_DEMO_RG --sku Standard_LRS --kind StorageV2

# Create the storage account to be used by the function with storage Blob trigger
az storage account create --name $DEMO_APP_STORAGE_ACCT --location $LOCATION --resource-group $APP_PE_DEMO_RG --sku Standard_LRS --kind StorageV2

# Create Blob container for trigger
az storage container create --account-name $DEMO_APP_STORAGE_ACCT --name datafiles --auth-mode login

# Create Table Store Table for results
az storage table create --name FileLogs --account-name $DEMO_APP_STORAGE_ACCT 

# Create Premium Function Plan
az functionapp plan create --name $DEMO_FUNC_PLAN --location $LOCATION --resource-group $APP_PE_DEMO_RG \
    --min-instances 1 --sku EP1

# Create NodeJS Function App
az functionapp create --name $DEMO_FUNC_NAME --storage-account $DEMO_FUNC_STORAGE_ACCT --plan $DEMO_FUNC_PLAN \
  --resource-group $APP_PE_DEMO_RG --runtime node

# "enabledHostNames": [
#    "nz2807win-demofunc-app.azurewebsites.net",
#    "nz2807win-demofunc-app.scm.azurewebsites.net"
#  ]

# "outboundIpAddresses": "168.62.51.220,13.92.179.222,52.168.2.55,13.92.181.253,168.62.180.253",
# "possibleOutboundIpAddresses": "40.71.11.143,40.117.230.15,104.211.5.249,168.62.181.40,52.168.3.5,168.62.51.220,13.92.179.222,52.168.2.55,13.92.181.253,168.62.180.253",

# Assign MSI for Premium Function App
# Please save the output and take a note of the ObjecID and save it as $APP_MSI
az functionapp identity assign -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME

# Capture identity from output
export APP_MSI="7a31e467-0ed8-4656-aa43-b3dca8fe29aa"

# Use Azure Function CLI Tools to deploy the app
func azure functionapp publish $DEMO_FUNC_NAME

# Create Key Vault
az keyvault create --location $LOCATION --name $DEMO_APP_KV --resource-group $APP_PE_DEMO_RG --enable-soft-delete true

# Set Key Vault Secrets
# Please  take a note of the Secret Full Path and save it as KV_SECRET_DB_UID_FULLPATH
az keyvault secret set --vault-name $DEMO_APP_KV --name "$KV_SECRET_APP_MESSAGE" --value "$KV_SECRET_APP_MESSAGE_VALUE"

# Capture the URI of the secret we've created
export KV_RESOURCE_ID="https://nz2807win-linux-demo-kv.vault.azure.net/secrets/APP-MESSAGE/177df624dcfb495f9799984667456ed6"

# Capture the KV URI
# az keyvault show --name $DEMO_APP_KV --resource-group $APP_PE_DEMO_RG
export KV_URI="/subscriptions/03228871-7f68-4594-b208-2d8207a65428/resourceGroups/nz2807win-funcdemo-rg/providers/Microsoft.KeyVault/vaults/nz2807win-demo-kv1"

# Set Policy for Web App to access secrets
az keyvault set-policy -g  $APP_PE_DEMO_RG --name $DEMO_APP_KV --object-id $APP_MSI --secret-permissions get list --verbose

# Get the connection string for App Storage Account for trigger
az storage account show-connection-string -g $APP_PE_DEMO_RG -n $DEMO_APP_STORAGE_ACCT

# Create Web App variable
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings $KV_SECRET_APP_MESSAGE_VAR="$KV_SECRET_APP_MESSAGE"
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings $KV_SECRET_APP_KV_NAME_VAR="$DEMO_APP_KV"
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME \
    --settings $DEMO_APP_STORAGE_CONFIG="DefaultEndpointsProtocol=https;AccountName=nz2807winappsstore;AccountKey=pnUinyeWkA8twfugV0I++4rXiAHdPdfvY8mPQ8WfU6fnEUvPvojdSaZ535srq5OUGHHhV+gD9bxgtL5fIBPeXw==;EndpointSuffix=core.windows.net"

# Set Private DNS Zone Settings
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings "WEBSITE_DNS_SERVER"="168.63.129.16"
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings "WEBSITE_VNET_ROUTE_ALL"="1"
#
# Create Private Links
#
# Prepare the Subnet
az network vnet subnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET_PL_SUBNET --vnet-name $DEMO_VNET --disable-private-endpoint-network-policies
az network vnet subnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET_PL_SUBNET --vnet-name $DEMO_VNET --disable-private-link-service-network-policies

# Create Key Vault Private Link
# Get the Resource ID of the Key Vault from the Portal, assign it to KV_RESOURCE_ID and create private link
az network private-endpoint create -g $APP_PE_DEMO_RG -n kvpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$KV_URI" --connection-name kvpeconn -l $LOCATION --group-id "vault"

# Create App Storage Private Links
# Get the Resource ID of the App Storage from the Portal, assign it to APP_STORAGE_RESOURCE_ID and create private link
export APP_STORAGE_RESOURCE_ID="/subscriptions/03228871-7f68-4594-b208-2d8207a65428/resourceGroups/nz2807win-funcdemo-rg/providers/Microsoft.Storage/storageAccounts/nz2807winappsstore"
az network private-endpoint create -g $APP_PE_DEMO_RG -n funcblobpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$APP_STORAGE_RESOURCE_ID" --connection-name funcblobpeconn -l $LOCATION --group-id "blob"
az network private-endpoint create -g $APP_PE_DEMO_RG -n functablepe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$APP_STORAGE_RESOURCE_ID" --connection-name functableconn -l $LOCATION --group-id "table"

# Creating Forward Lookup Zones in the DNS server you created above
# You may be using root hints for DNS resolution on your custom DNS server.
# Please add 168.63.129.16 as default forwarder on you custom DNS server.
# https://docs.microsoft.com/en-us/powershell/module/dnsserver/set-dnsserverforwarder?view=win10-ps

#   Create the zone for: vault.azure.net
#       Create an A Record for the Key Vault with the name and its private endpoint address

# Switch to custom DNS on VNET
# export DEMO_APP_VM_IP="10.0.2.4"
# az network vnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET --dns-servers $DEMO_APP_VM_IP

# Private DNS Zones
export PRIVATE_KV_IP="10.1.2.4"
export AZUREKEYVAULT_ZONE=privatelink.vaultcore.azure.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREKEYVAULT_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREKEYVAULT_ZONE -n $DEMO_APP_KV -a $PRIVATE_KV_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZUREKEYVAULT_ZONE --name kvdnsLink --registration-enabled false

export PRIVATE_BLOB_IP="10.1.2.5"
export AZUREBLOB_ZONE=privatelink.blob.core.windows.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREBLOB_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREBLOB_ZONE -n $DEMO_APP_STORAGE_ACCT -a $PRIVATE_BLOB_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZUREBLOB_ZONE --name blobdnsLink --registration-enabled false

export PRIVATE_TABLE_IP="10.1.2.6"
export AZURETABLE_ZONE=privatelink.table.core.windows.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZURETABLE_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZURETABLE_ZONE -n $DEMO_APP_STORAGE_ACCT -a $PRIVATE_TABLE_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZURETABLE_ZONE --name tablednsLink --registration-enabled false

#
# Change KV firewall - allow only PE access
# Verify it's locked down (click on Secrets from browser)
#

# Attach Web App to the VNET (VNET integration)
az functionapp vnet-integration add -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --vnet $DEMO_VNET --subnet $DEMO_VNET_APP_SUBNET

#enable virtual network triggers
az resource update -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME/config/web --set properties.functionsRuntimeScaleMonitoringEnabled=1 --resource-type Microsoft.Web/sites

# Now restart the webapp
az functionapp restart -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME
# ...and verify it still has access to KV

# Get the webapp resource id
az functionapp show -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME

export FUNC_APP_RESOURCE_ID="/subscriptions/fbd6916d-a76d-48f0-9b03-f1d9610d7970/resourceGroups/nz2807win-pedemo-rg/providers/Microsoft.Web/sites/nz2807win-simplejava-app"

# Create Web App Private Link
az network private-endpoint create -g $APP_PE_DEMO_RG -n funcpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id $FUNC_APP_RESOURCE_ID --connection-name funcpeconn -l $LOCATION --group-id "sites"

# The remaining private DNS for app's frontend can be handled via private DNS zones
export PRIVATE_APP_IP="10.0.2.6"

export AZUREWEBSITES_ZONE=azurewebsites.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREWEBSITES_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREWEBSITES_ZONE -n $DEMO_FUNC_NAME -a $PRIVATE_APP_IP

export AZUREWEBSITES_SCM_ZONE=scm.azurewebsites.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREWEBSITES_SCM_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREWEBSITES_SCM_ZONE -n $DEMO_FUNC_NAME -a $PRIVATE_APP_IP

# Link zones to VNET
az network private-dns link vnet create -g $APP_PE_DEMO_RG -n funcpe-link -z $AZUREWEBSITES_ZONE -v $DEMO_VNET -e False
az network private-dns link vnet create -g $APP_PE_DEMO_RG -n funcpe-link -z $AZUREWEBSITES_SCM_ZONE -v $DEMO_VNET -e False




