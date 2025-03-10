param StorageAccountName string = 'cpawstorage'
param vNetName string = 'cPAW-vNet'
param SubnetName string = 'cPAW-Subnet'
param ProfileShareName string = 'profiles'
param RedirXMLSourceFolder string ='Redirections'
param domainName string = 'ad.domain.com'
param domainGUID string ='enter domain GUID here'
var location = resourceGroup().location


// Reference the vNet and Subnet for the Private EndPoint
resource vNet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vNetName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: SubnetName
  parent: vNet
}

resource ProfileStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: StorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: ProfileShareName
  parent: ProfileStorage
  location: location
  
  properties: {
    shareQuota: 100
  }
}
