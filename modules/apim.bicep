@description('Name of the deployment. Used to ensure unique resource names. Default: "digital".')
param deploymentName string = 'digital'

@description('The DNS name of the API Management service. Must be a valid domain name.')
param dnsname string

@description('The Azure Region to deploy the resources into.')
param location string = resourceGroup().location

@description('Specifies the resource tags.')
param tags object

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
param skuCount int = 1

@description('The ID of the user assigned identity to use for the API Management service.')
param identityResourceId string

@description('The client ID of the user assigned identity to use for the API Management service.')
param identityClientId string

@description('The ID of the key vault to use for the API Management service.')
param keyvaultid string

@description('The ID of the subnet to delegate to APIM.')
param apimSubnetId string

param apiServiceUrl string

var apiManagementServiceName = '${deploymentName}-apim-${uniqueString(resourceGroup().id)}'
var apiName = '${deploymentName}-api-${uniqueString(resourceGroup().id)}'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: apiManagementServiceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: apiManagementServiceName
    }
  }
}

#disable-next-line BCP081
resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${identityResourceId}': {}
    }
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External'
    publicIpAddressId: publicIp.id
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: dnsname
        keyVaultId: keyvaultid
        identityClientId: identityClientId
        defaultSslBinding: true
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }
}

#disable-next-line BCP081
resource publishedApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  name: apiName
  parent: apiManagementService
  properties: {
    apiRevision: '1'
    path: '/openai'
    displayname: 'APIM - Open AI API'
    description: 'APIM - Open AI API'
    protocols: [
      'https'
    ]
    serviceUrl: apiServiceUrl
    import: {
      contentFormat: 'swagger-link-json'
      contentValue: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2023-05-15/inference.json'
    }
  }
}

/*

resource "azurerm_api_management_api" "apim_open_ai_api" {
  name                = "apim-open-ai-api"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "APIM - Open AI API"
  path                = "/openai"
  protocols           = ["https"]
  service_url         = azurerm_cognitive_account.openai_account.endpoint
 
  import {
    content_format = "swagger-link-json"
    content_value  = "raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2023-05-15/inference.json"
  }
}

*/
