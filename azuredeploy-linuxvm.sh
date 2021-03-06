#az login

# list subs
az account list --query "[].{Id:id,IsDefault:isDefault,Name:name,TenantId:tenantId}"

# set to ed mpn sub
az account set --subscription b669cd3e-4bff-4d41-bdd4-c32be7c0829b

# params
RESOURCEGROUP="az303-arm-linux"
LOCATION=eastus
DNS_LABEL_PREFIX=mydeployment-$RANDOM
USERNAME=azureuser
PASSWORD=abc1234ABC#wert

# create the resource group
az group create --name $RESOURCEGROUP --location $LOCATION

# validate
az deployment group validate \
  --resource-group $RESOURCEGROUP \
  --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-simple-linux/azuredeploy.json" \
  --parameters adminUsername=$USERNAME \
  --parameters authenticationType=password \
  --parameters adminPasswordOrKey=$PASSWORD \
  --parameters dnsLabelPrefix=$DNS_LABEL_PREFIX

  az deployment group validate \
  --resource-group $RESOURCEGROUP \
  --template-file azuredeploy-simplelinx.json \
  --parameters adminUsername=$USERNAME \
  --parameters authenticationType=password \
  --parameters adminPasswordOrKey=$PASSWORD \
  --parameters dnsLabelPrefix=$DNS_LABEL_PREFIX

# deploy
az deployment group create \
  --name MyDeployment \
  --resource-group $RESOURCEGROUP \
  --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-simple-linux/azuredeploy.json" \
  --parameters adminUsername=$USERNAME \
  --parameters authenticationType=password \
  --parameters adminPasswordOrKey=$PASSWORD \
  --parameters dnsLabelPrefix=$DNS_LABEL_PREFIX

  az deployment group create \
  --resource-group $RESOURCEGROUP \
  --template-file azuredeploy-simplelinx.json \
  --parameters adminUsername=$USERNAME \
  --parameters authenticationType=password \
  --parameters adminPasswordOrKey=$PASSWORD \
  --parameters dnsLabelPrefix=$DNS_LABEL_PREFIX

# verify. provides a json block that can be used as params
az deployment group show \
  --name MyDeployment \
  --resource-group $RESOURCEGROUP

# list the vms
az vm list \
  --resource-group $RESOURCEGROUP \
  --output table

# enable the custom script extension
az vm extension set \
  --resource-group $RESOURCEGROUP \
  --vm-name simpleLinuxVM \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --settings '{"fileUris":["https://raw.githubusercontent.com/MicrosoftDocs/mslearn-welcome-to-azure/master/configure-nginx.sh"]}' \
  --protected-settings '{"commandToExecute": "./configure-nginx.sh"}'


## OR alter the template, then redeploy. thats what the best way is
az deployment group validate \
--resource-group $RESOURCEGROUP \
--template-file azuredeploy-simplelinx.json \
--parameters adminUsername=$USERNAME \
--parameters authenticationType=password \
--parameters adminPasswordOrKey=$PASSWORD \
--parameters dnsLabelPrefix=$DNS_LABEL_PREFIX

az deployment group create \
--resource-group $RESOURCEGROUP \
--template-file azuredeploy-simplelinx.json \
--parameters adminUsername=$USERNAME \
--parameters authenticationType=password \
--parameters adminPasswordOrKey=$PASSWORD \
--parameters dnsLabelPrefix=$DNS_LABEL_PREFIX

IPADDRESS=$(az vm show \
  --name simpleLinuxVM \
  --resource-group $RESOURCEGROUP \
  --show-details \
  --query [publicIps] \
  --output tsv)

echo $IPADDRESS
curl $IPADDRESS

## Generalize the vm
ssh $USERNAME@$IPADDRESS

# prepare for generization
sudo waagent -deprovision+user
# say yes. then extension
$ exit

#deallocate the virtual machine.
vmname=simpleLinuxVM
az vm deallocate \
    --name $vmname \
    --resource-group $RESOURCEGROUP

#generalize the virtual machine.
vmname=simpleLinuxVM
az vm generalize \
    --name $vmname \
    --resource-group $RESOURCEGROUP

# create a new image
az image create \
    --name MyVMIMage \
    --source $vmname \
    --resource-group $RESOURCEGROUP

# create a new vm
az vm create \
  --name MyVMFromImage \
  --computer-name MyVMFromImage \
  --image MyVMImage \
  --admin-username azureuser \
  --generate-ssh-keys \
  --resource-group $RESOURCEGROUP

# update the default web page with the server name.
az vm extension set \
  --publisher Microsoft.Azure.Extensions \
  --name CustomScript \
  --vm-name MyVMFromImage \
  --settings '{"commandToExecute":"hostname > /var/www/html/index.html"}' \
  --resource-group $RESOURCEGROUP

az vm open-port \
  --name MyVMFromImage \
  --port 80 \
  --resource-group $RESOURCEGROUP

# echo http://$(az vm list-ip-addresses \
#                 --name MyVMFromImage \
#                 --query "[].virtualMachine.network.publicIpAddresses[*].ipAddress" \
#                 --output tsv)

newpip="138.91.121.119"

ssh -o StrictHostKeyChecking=no $newpip