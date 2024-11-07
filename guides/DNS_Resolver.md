# Let's get it going manually... 

First, let's set some parameters

### vars
```
UNIQUE="chi2"
LOCATION=westus2
```

### create our vnets

Create rg
`az group create --resource-group rg-$UNIQUE-dev --location $LOCATION`

Keep rg handy
```
RG="rg-$UNIQUE-dev"
```

Create 'on-prem vnet'
`az network vnet create -g $RG -n vnet-1-$UNIQUE --address-prefix 10.0.0.0/22 --subnet-name sn-1-$UNIQUE`

Create vnet2 - make sure your address space doesn't overlap 
`az network vnet create -g $RG -n vnet-2-$UNIQUE --address-prefix 10.1.0.0/22 --subnet-name sn-2-$UNIQUE`

### peer the vnets

get the full id of on-prem and vnet-2

`VNET1ID=$(az network vnet show --resource-group $RG --name vnet-1-$UNIQUE --query "id" -o tsv | tr -d '"')`

`VNET2ID=$(az network vnet show --resource-group $RG --name vnet-2-$UNIQUE --query "id" -o tsv | tr -d '"')`

peer vnet onprem to 2 
```
az network vnet peering create --name peer-2-$UNIQUE-1 -g $RG --vnet-name vnet-1-$UNIQUE --remote-vnet $VNET2ID --allow-vnet-access
```
peer vnet 2 to onprem
```
az network vnet peering create --name peer-2-$UNIQUE-1 -g $RG --vnet-name vnet-2-$UNIQUE --remote-vnet $VNET1ID --allow-vnet-access
```


## create bastion subnet, ip and resource

```
az network public-ip create -g $RG --name BastionPublicIp --sku Standard --location $LOCATION

az network vnet subnet create --name AzureBastionSubnet --resource-group $RG --vnet-name vnet-1-$UNIQUE --address-prefixes 10.0.1.0/26 --private-endpoint-network-policies Disabled --private-link-service-network-policies Disabled

az network bastion create --name bh-$UNIQUE --public-ip-address BastionPublicIP --resource-group $RG --vnet-name vnet-1-$UNIQUE --location $LOCATION

```

## create web app

```
az appservice plan create --name $UNIQUE-app-plan --resource-group $RG --location $LOCATION --sku S1

az webapp create --name webapp-$UNIQUE --resource-group $RG --plan $UNIQUE-app-plan --runtime "DOTNET|6.0"
```

## create private endpoint
get web app id
```
WEBAPPID=$(az webapp show -g $RG --name webapp-$UNIQUE --query "id" -o tsv | tr -d '"')
```
```
az network vnet subnet create --name sn-$UNIQUE-app --resource-group $RG --vnet-name vnet-2-$UNIQUE --address-prefixes 10.1.1.0/26 --private-endpoint-network-policies Disabled --private-link-service-network-policies Disabled

az network private-endpoint create --connection-name pep-$UNIQUE-web --name pep-app-$UNIQUE -g $RG --subnet sn-$UNIQUE-app --group-id sites --location $LOCATION --nic-name nic-pep-app-$UNIQUE --vnet-name vnet-2-$UNIQUE --private-connection-resource-id $WEBAPPID
```

## create a private resolver and dns-zone

az network private-dns zone create -g $RG -n privatelink.azurewebsites.net

az network private-dns link vnet create --name vnet-privatelink-$UNIQUE-websites --registration-enabled false --resource-group $RG --virtual-network $VNET2ID --zone-name privatelink.azurewebsites.net

## create vm 

*make sure you set 'Yoursecret1234'*

```
az network nsg create --name nsg-$UNIQUE-jb --resource-group $RG --location $LOCATION 

az network nic create --name $UNIQUE-nicjb --location $LOCATION --vnet-name vnet-1-$UNIQUE --network-security-group nsg-$UNIQUE-jb --subnet sn-1-$UNIQUE --resource-group $RG

az vm create --name $UNIQUE-jump --resourge-group $RG --location $LOCATION --image "MicrosoftWindowsDesktop:windows-11:win11-23h2-pro:22631.3007.240105" --admin-username $UNIQUE-user --nics $UNIQUE-nicjb --os-disk-name $UNIQUE-disk --admin-password Yoursecret1234
```

# archive

az vm create `
    --name $JumpboxVmName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --image $JumpboxVmImage `
    --admin-username $JumpboxAdminUsername `
    --admin-password $JumpboxAdminPassword `
    --nics $JumpboxNicName `
    --os-disk-name $JumpboxOsDiskName


az vm create --name ${VmName} --resource-group ${ResourceGroupName} --location ${Location} --image Ubuntu2204 --nics ${NicName}

az network private-dns link vnet create --name vnet-timinhou-dev-westeurope-privatelink-azurewebsites-net --registration-enabled false --resource-group rg-timinhou-dev-hub --virtual-network /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/rg-timinhou-dev-eu/providers/Microsoft.Network/virtualNetworks/vnet-timinhou-dev-westeurope --zone-name privatelink.azurewebsites.net


az network private-dns zone create -g rg-timinhou-dev-hub -n privatelink.azurewebsites.net


az network private-endpoint create --connection-name sc-pep-app-timinhou-dev --name pep-app-timinhou-dev --private-connection-resource-id /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/rg-timinhou-dev-us/providers/Microsoft.Web/sites/app-timinhou-dev-us -g rg-timinhou-dev-us --subnet snet-apps-timinhou-dev-eastus --group-id sites --location eastus --nic-name nic-pep-app-$UNIQUE --no-wait false --vnet-name vnet-timinhou-dev-eastus


az network bastion create --name MyBastionHost --public-ip-address BastionPublicIP --resource-group rg-timinhou-dev-eu --vnet-name vnet-timinhou-dev-westeurope --location westeurope


az network public-ip create --resource-group rg-timinhou-dev-eu --name BastionPublicIP --sku Standard --location westeurope



`az network vnet peering create --name peer-$UNIQUE- -g rg-timinhou-dev-hub --vnet-name vnet-timinhou-dev-swedencentral --remote-vnet /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/rg-timinhou-dev-eu/providers/Microsoft.Network/virtualNetworks/vnet-timinhou-dev-westeurope --allow-vnet-access`

`az network vnet peering create --name peer-$UNIQUE- -g rg-timinhou-dev-hub --vnet-name vnet-timinhou-dev-swedencentral --remote-vnet /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/rg-timinhou-dev-eu/providers/Microsoft.Network/virtualNetworks/vnet-timinhou-dev-westeurope --allow-vnet-access --query "[].id"`




az network vnet create -g $UNIQUE -n MyVnet --address-prefix 10.0.0.0/16 --subnet-name dev --subnet-prefixes 10.0.0.0/24


az network vnet create --resource-group rg-timinhou-dev-eu --name vnet-timinhou-dev-westeurope --address-prefix 10.0.4.0/24


az network vnet create --resource-group rg-$PREFIX-dev-eu --name vnet-$PREFIX-dev-westeurope --address-prefix 10.0.0.0/24

