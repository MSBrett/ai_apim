targetScope = 'subscription'

@description('Contact DL for security center alerts')
param securityCenterContactEmail string = 'abuse@microsoft.com'

param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceRg string
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceLocation string

param policyDefinitionID string = '/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8'

resource mcsbAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'Microsoft Cloud Security Benchmark'
  scope: subscription()
  properties: {
    policyDefinitionId: policyDefinitionID
    description: 'Microsoft Cloud Security Benchmark'
    displayName: 'Microsoft Cloud Security Benchmark'
  }
}

resource mdc_arm 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'Arm'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'PerSubscription'
  }
}

resource mdc_CosmosDbs 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'CosmosDbs'
  properties: {
    pricingTier: 'Standard'
  }
}

resource mdc_SqlServers 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'SqlServers'
  properties: {
    pricingTier: 'Standard'
  }
}

resource mdc_SqlServerVirtualMachines 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'SqlServerVirtualMachines'
  properties: {
    pricingTier: 'Standard'
  }
}

resource mdc_AppServices 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'AppServices'
  properties: {
    pricingTier: 'Standard'
  }
}

resource mdc_OpenSourceRelationalDatabases 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'OpenSourceRelationalDatabases'
  properties: {
    pricingTier: 'Standard'
  }
}

resource mdc_api 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'Api'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'P1'
  }
}

resource mdc_keyVaults 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'KeyVaults'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'PerKeyVault'
  }
}

resource mdc_containers 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'Containers'
  properties: {
    pricingTier: 'Standard'
    extensions: [
      {
        name: 'ContainerRegistriesVulnerabilityAssessments'
        isEnabled: 'True'
      }
    ]
  }
}

resource mdc_servers 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'P2'
  }
}

resource mdc_storage 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'StorageAccounts'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'DefenderForStorageV2'
    extensions: [
      {
        //additionalExtensionProperties: {}
        isEnabled: 'false'
        name: 'SensitiveDataDiscovery'
      }
      {
        isEnabled: 'true'
        name: 'OnUploadMalwareScanning'
      }
    ]
  }
}

resource mdc_cspm 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'CloudPosture'
  properties: {
    pricingTier: 'Standard'
    extensions: [
      {
        //additionalExtensionProperties: {}
        isEnabled: 'true'
        name: 'AgentlessDiscoveryForKubernetes'
      }
      {
        //additionalExtensionProperties: {}
        isEnabled: 'true'
        name: 'ContainerRegistriesVulnerabilityAssessments'
      }
      {
        //additionalExtensionProperties: {}
        isEnabled: 'false'
        name: 'SensitiveDataDiscovery'
      }
      {
        //additionalExtensionProperties: {}
        isEnabled: 'True'
        name: 'EntraPermissionsManagement'
      }
      {
        //additionalExtensionProperties: {}
        isEnabled: 'True'
        name: 'AgentlessVmScanning'
      }
    ]
  }
  
}

resource mdc_contact 'Microsoft.Security/securityContacts@2020-01-01-preview' = {
  name: 'default'
  properties: {
    emails: securityCenterContactEmail
    alertNotifications: {
      state: 'On'
      minimalSeverity: 'Low'
    }
    notificationsByRole: {
      state: 'On'
      roles: [
          'Owner'
      ]
    }
  }
}


