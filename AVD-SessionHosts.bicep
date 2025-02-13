param location string = 'uksouth'
param sessionHostPrefix string = 'cPAW'
param numberOfHosts int = 2
@secure()
param adminPassword string
param adminUsername string = 'cPAW-Admin'
param hostPoolRegistrationInfoToken string = 'Enter HostPool Registration Key here'


var modulesURL = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_1.0.02797.442.zip'

// Reference the HostPool
resource HostPool 'Microsoft.DesktopVirtualization/hostpools@2021-07-12' existing = {
  name: '${sessionHostPrefix}-HostPool'
}

// Deploy the network infrastructure
resource vNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${sessionHostPrefix}-vNet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.250.0/24'
      ]
    }
    subnets: [
      {
        name: '${sessionHostPrefix}-Subnet'
        properties: {
          addressPrefix: '192.168.250.0/24'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, numberOfHosts): {
  name: '${sessionHostPrefix}-${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vNet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}]

resource VM 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, numberOfHosts): {
  name: '${sessionHostPrefix}-${i}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B4ms'
    }
    osProfile: {
      computerName: '${sessionHostPrefix}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-24h2-avd'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
}]

// Schedule daily shutdown at 19:00 GMT
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOfHosts): {
  name: '${sessionHostPrefix}-${i}-shutdown'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '19:00'
    }
    timeZoneId: 'GMT Standard Time'
    notificationSettings: {
      status: 'Disabled'

    }
    targetResourceId: VM[i].id
  }
  dependsOn: [
  VM[i]
]
}]

resource entraIdJoin 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: 'AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    settings: {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } 
  }
}]


resource RegistryFix 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/andrew-kemp/CloudPAW/refs/heads/main/Enable-CloudKerberos.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Enable-CloudKerberos.ps1'
    }
  }
  dependsOn: [
    entraIdJoin
  ]
}]

resource RemoveApps 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/andrew-kemp/CloudPAW/refs/heads/main/Remove-WindowsApps.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Remove-WindowsApps.ps1'
    }
  }
  dependsOn: [
    RegistryFix
  ]
}]



// Join the SessionHosts to the HostPool
resource dcs 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: '${sessionHostPrefix}-${i}-DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.76'
    settings: {
      modulesUrl: modulesURL
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: HostPool.name
        aadJoin: true
      }
    }
    protectedSettings: {
      properties: {
        registrationInfoToken: hostPoolRegistrationInfoToken
      }
    }
  }
  dependsOn: [
    RemoveApps
  ]
}]

