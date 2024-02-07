@description('Name of the deployment. Used to ensure unique resource names. Default: "digital".')
param deploymentName string = 'digital'

@description('The Azure Region to deploy the resources into.')
param location string = resourceGroup().location

@description('Specifies the resource tags.')
param tags object

@description('Enable soft delete.  Set to "true" for prod')
param enableSoftDelete bool = true

@description('The SKU of the vault to be created.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('The SSL certificate to be stored in the Key Vault.')
param sslCertValue string

@description('The ID of the subnet on which to create the private endpoints.')
param virtualNetworkId string

@description('Private endpoint subnet id')
param privateEndpointSubnetId string

var keyVaultName = '${deploymentName}-kv-${uniqueString(resourceGroup().id)}'
var sslCertName = '${deploymentName}-key-${uniqueString(resourceGroup().id)}'
var identityName = '${deploymentName}-mi-${uniqueString(resourceGroup().id)}'
var privateEndpointName = '${deploymentName}-kv-${uniqueString(resourceGroup().id)}'
var privateDnsZoneName = 'privatelink.vaultcore.azure.net'
var pvtEndpointDnsGroupName = '${privateEndpointName}/keyvault-endpoint-zone'
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultSecretsUserRoleDefinitionId,userIdentity.id,keyVault.id)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: true
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: 90
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource sslCertSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: sslCertName
  parent: keyVault
  properties: {
    value: sslCertValue
    contentType: 'application/x-pkcs12'
    attributes: {
      enabled: true
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

output keyvaultName string = keyVault.name
output keyvaultId string = keyVault.id
output keyvaultUri string = keyVault.properties.vaultUri
