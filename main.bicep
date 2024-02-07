targetScope='subscription'

// Parameters
@description('Name of the deployment. Used to ensure unique resource names. Default: "digital".')
param deploymentName string = 'digital'

@description('DNS alias for the APIM instance')
param dnsname string = 'digital.contoso.com'

@description('Optional. Azure location where all resources should be created. See https://aka.ms/azureregions. Default: Same as deployment.')
param location string

@description('Optional. Tags to apply to all resources. We will also add the cm-resource-parent tag for improved cost roll-ups in Cost Management.')
param tags object = {}

@description('Contact DL for security center alerts')
param securityCenterContactEmail string = 'abuse@microsoft.com'

@description('Optional. Deploy Azure Security Center. Default: false.')
param deploySecurityCenter bool = false

@description('Virtual Network Address Prefix')
param virtualNetworkAddressPrefix string = '10.2.0.0/23'

@description('Log Analytics Workspace Id')
param logAnalyticsWorkspaceId string = '/subscriptions/cab7feeb-759d-478c-ade6-9326de0651ff/resourceGroups/Observability/providers/Microsoft.OperationalInsights/workspaces/fdpoworkspace'

@description('Log Analytics Workspace Resource Group')
param logAnalyticsWorkspaceRg string= 'Observability'

@description('Log Analytics Workspace Name')
param logAnalyticsWorkspaceName string = 'fdpoworkspace'

@description('Log Analytics Workspace Location')
param logAnalyticsWorkspaceLocation string = 'westus'

@description('The base64 encoded SSL certificate in PFX format to be stored in Key Vault. CN and SAN must match the custom hostname of API Management Service.')
@secure()
param sslCertValue string

@description('Publisher email for API Management Service.')
param publisherEmail string = 'abuse@microsoft.com'

@description('Publisher name for API Management Service.')
param publisherName string = 'Microsoft'

@allowed([
  'Prod'
  'NonProd'
])
@description('Deployment model version upgrade option. see https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/2023-05-01/accounts/deployments?pivots=deployment-language-bicep#deploymentproperties')
param environmentType string = 'NonProd'

// Variables
var resourceGroupName = toLower('${deploymentName}')

// Modules
module securityCenter 'modules/securityCenter.bicep' = if (deploySecurityCenter) {
  name: 'securityCenter'
  scope: subscription()
  params: {
    securityCenterContactEmail: securityCenterContactEmail
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    logAnalyticsWorkspaceLocation: logAnalyticsWorkspaceLocation
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceRg: logAnalyticsWorkspaceRg
  }
}

module rg 'modules/resourcegroup.bicep' = {
  name: 'resourcegroup'
  scope: subscription()
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

module vnet 'modules/virtualNetwork.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'virtualNetwork'
  dependsOn: [ rg ]
  params: {
    deploymentName: deploymentName
    location: location
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
  }
}

module keyVault 'modules/keyVault.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'keyVault'
  dependsOn: [ vnet ]
  params: {
    deploymentName: deploymentName
    location: location
    tags: tags
    enableSoftDelete: environmentType == 'Prod' ? true : false
    sslCertValue: sslCertValue
    virtualNetworkId: vnet.outputs.virtualNetworkId
    privateEndpointSubnetId: '${vnet.outputs.virtualNetworkId}/subnets/services'
  }
}

module identity 'modules/identity.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'identity'
  dependsOn: [ keyVault ]
  params: {
    location: location
  }
}

module certificate './modules/certificate.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'certificate'
  dependsOn: [ identity ]
  params: {
    location: location
    certificatename: deploymentName
    dnsname: dnsname
    vaultname: keyVault.outputs.keyvaultName
    identityPrincipalId: identity.outputs.principalId
    identityResourceId: identity.outputs.resourceId
  }
}

module openAI 'modules/openai.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'openAI'
  dependsOn: [ identity ]
  params: {
    deploymentName: deploymentName
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    virtualNetworkId: vnet.outputs.virtualNetworkId
    privateEndpointSubnetId: '${vnet.outputs.virtualNetworkId}/subnets/services'
  }
}

module apiManagement 'modules/apim.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'apiManagement'
  dependsOn: [ openAI ]
  params: {
    deploymentName: deploymentName
    location: location
    tags: tags
    sku: 'Premium'  // environmentType == 'Prod' ? 'Premium' : 'Developer'
    apimSubnetId: '${vnet.outputs.virtualNetworkId}/subnets/ApiManagement'
    publisherEmail: publisherEmail
    publisherName: publisherName
    keyvaultid: '${keyVault.outputs.keyvaultUri}secrets/${deploymentName}/'
    dnsname: dnsname
    identityResourceId: identity.outputs.resourceId
    identityClientId: identity.outputs.clientId
  }
}
