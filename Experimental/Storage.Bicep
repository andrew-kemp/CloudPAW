param StorageAccountNamePrefix string = 'cpawstorage'
param ProfileShareName string = 'profiles'
param RedirShareName string = 'redirections'
param vNetName string = 'cPAW-vNet'
param SubnetName string = 'cPAW-Subnet'
var privateDnsZoneName = 'privatelink.file.core.windows.net'
param groupObjectId string = 'eg 00000000-0000-0000-0000-000000000000'

var location = resourceGroup().location



// Generate a unique string based on the resource group ID
var uniqueSuffix = uniqueString(resourceGroup().id)

// Combine the prefix with the unique suffix for the storage account name
var StorageAccountName = '${StorageAccountNamePrefix}${uniqueSuffix}'

// Reference the vNet and Subnet for the Private Endpoint
resource vNet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vNetName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: SubnetName
  parent: vNet
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: StorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled' 
    networkAcls: {
      bypass: 'None'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'AADKERB'
      defaultSharePermission: 'StorageFileDataSmbShareContributor'
    }
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource profileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: ProfileShareName
  parent: fileServices
  
  properties: {
    shareQuota: 100
    accessTier: 'TransactionOptimized'
  }
}

resource redirShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: RedirShareName
  parent: fileServices
  
  properties: {
    shareQuota: 100
    accessTier: 'TransactionOptimized'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${StorageAccountName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${StorageAccountName}-plsc'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${StorageAccountName}-pdz'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, 'Storage File Data SMB Share Contributor', groupObjectId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e7f6d5a2-4d38-4ba4-9f0e-0d0b4d5e5a7a') // Storage File Data SMB Share Contributor role ID
    principalId: groupObjectId
    principalType: 'Group'
  }
}
