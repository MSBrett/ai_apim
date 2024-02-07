@description('The name of the certificate to create in the key vault.')
param certificatename string

@description('The DNS name of the certificate to create in the key vault. This is the name that will be used to access the certificate.')
param dnsname string

@description('The name of the key vault')
param vaultname string

@description('The location of the key vault and the identity')
param location string

param identityResourceId string

param identityPrincipalId string

var rbacRoles = [
  'a4417e6f-fecd-4de8-b567-7b0420556985' // key-vault-certificates-officer - https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-certificates-officer
  'b86a8fe4-44ce-4948-aee5-eccb2c155cd7' // key-vault-secrets-officer - https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer
]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: vaultname
}

// Assign access to the identity
resource identityRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in rbacRoles: {
  name: guid(keyVault.id, role, identityResourceId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}]

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'uploadSettings'
  kind: 'AzurePowerShell'
  // chinaeast2 is the only region in China that supports deployment scripts
  location: startsWith(location, 'china') ? 'chinaeast2' : location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityResourceId}': {}
    }
  }
  dependsOn: [
    identityRoleAssignments
  ]
  properties: {
    azPowerShellVersion: '8.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'certificatename'
        value: certificatename
      }
      {
        name: 'dnsname'
        value: dnsname
      }
      {
        name: 'vaultname'
        value: vaultname
      }
    ]
    scriptContent: loadTextContent('./scripts/create-cert.ps1')
  }
}

