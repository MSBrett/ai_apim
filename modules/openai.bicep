// Parameters
@description('Name of the deployment. Used to ensure unique resource names. Default: "digital".')
param deploymentName string = 'digital'

@description('The Azure Region to deploy the resources into.')
param location string = resourceGroup().location

@description('Specifies the resource tags.')
param tags object

@description('Specifies the resource model definition representing SKU.')
param sku object = {
  name: 'S0'
  capacity: 10
}

@description('Specifies the identity of the OpenAI resource.')
param identity object = {
  type: 'SystemAssigned'
}

@allowed([
  'Enabled'
  'Disabled'
])
@description('Specifies the public network access for the OpenAI resource. Default: "Disabled".')
param publicNetworkAccess string = 'Disabled'

@allowed([
  true
  false
])
@description('Specifies whether the outbound network access is restricted. Default: true.')
param restrictOutboundNetworkAccess bool = true

@description('Specifies the OpenAI deployments to create.')
param deployments array = [
  {
    name: 'text-embedding-ada-002'
    version: '2'
    raiPolicyName: ''
    capacity: 10
    scaleType: 'Standard'
  }
  {
    name: 'gpt-35-turbo'
    version: '0613'
    raiPolicyName: ''
    capacity: 10
    scaleType: 'Standard'
  }
]

@description('Specifies the workspace id of the Log Analytics used to monitor the Application Gateway.')
param logAnalyticsWorkspaceId string

@allowed([
  'NoAutoUpgrade'
  'OnceCurrentVersionExpired'
  'OnceNewDefaultVersionAvailable'
])
@description('Deployment model version upgrade option. see https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/2023-05-01/accounts/deployments?pivots=deployment-language-bicep#deploymentproperties')
param versionUpgradeOption string = 'OnceNewDefaultVersionAvailable'

@description('The ID of the subnet on which to create the private endpoints.')
param virtualNetworkId string

@description('Private endpoint subnet id')
param privateEndpointSubnetId string

// Variables
var openAIServiceName = '${deploymentName}-aoai-${uniqueString(resourceGroup().id)}'
var privateEndpointName = '${deploymentName}-aoai-${uniqueString(resourceGroup().id)}'
var privateDnsZoneName = 'privatelink.openai.azure.com'
var pvtEndpointDnsGroupName = '${privateEndpointName}/openai-endpoint-zone'
var diagnosticSettingsName = 'diagnosticSettings'

var openAiLogCategories = [
  'Audit'
  'RequestResponse'
  'Trace'
]
var openAiMetricCategories = [
  'AllMetrics'
]
var openAiLogs = [for category in openAiLogCategories: {
  category: category
  enabled: true
}]
var openAiMetrics = [for category in openAiMetricCategories: {
  category: category
  enabled: true
}]

// Resources
resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIServiceName
  location: location
  sku: sku
  kind: 'OpenAI'
  identity: identity
  tags: tags
  properties: {
    customSubDomainName: openAIServiceName
    publicNetworkAccess: publicNetworkAccess
    restrictOutboundNetworkAccess: restrictOutboundNetworkAccess
  }
}

@batchSize(1)
resource model 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  name: deployment.name
  sku: {
    capacity: deployment.capacity
    name: deployment.scaleType
  }
  parent: openAI
  properties: {
    model: {
      format: 'OpenAI'
      name: deployment.name
      version: deployment.version
    }
    raiPolicyName: deployment.raiPolicyName
    versionUpgradeOption: versionUpgradeOption
  }
}]

resource openAiDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  scope: openAI
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: openAiLogs
    metrics: openAiMetrics
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
          privateLinkServiceId: openAI.id
          groupIds: [
            'account'
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

// Outputs
output resourceId string = openAI.id
output resourceName string = openAI.name
output principalId string = openAI.identity.principalId
output endpoint string = openAI.properties.endpoint
