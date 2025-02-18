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
//Create the NIc's for the VM's
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
//Create the VM's
resource VM 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, numberOfHosts): {
  name: '${sessionHostPrefix}-${i}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_d2as_v5'
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



//Join the VM's to Entra and Entroll in intune
resource entraIdJoin 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: '${sessionHostPrefix}-${i}-EntraJoinEntrollIntune'
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

//Install the Guest Attestation Extension

resource guestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: '${sessionHostPrefix}-${i}-guestAttestationExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn:[
    entraIdJoin
  ]
}]

//run some preperation on the VM's to remove any windows apps and also enable cloud kerberos
resource SessionPrep 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: '${sessionHostPrefix}-${i}-SessionPrep'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/andrew-kemp/CloudPAW/refs/heads/main/SessionHostPrep.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File SessionHostPrep.ps1'
    }
  }
  dependsOn: [
    guestAttestationExtension
  ]
}]


// Join the SessionHosts to the HostPool
resource dcs 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, numberOfHosts): {
  parent: VM[i]
  name: '${sessionHostPrefix}-${i}-JointoHostPool'
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
    SessionPrep
  ]
}]
