targetScope='subscription'

@description('Name of the hub. Used to ensure unique resource names. Default: "digital".')
param resourceGroupName string = 'digital'

@description('Azure Region the resource group will be created in.')
param location string

@description('Optional. Tags to apply to all resources. We will also add the cm-resource-parent tag for improved cost roll-ups in Cost Management.')
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
