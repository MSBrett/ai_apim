
@description('The location of the key vault and the identity')
param location string

var identityName = 'id-${uniqueString(resourceGroup().id)}'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output resourceId string = identity.id
output resourceName string = identity.name
output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
output tenantId string = identity.properties.tenantId

