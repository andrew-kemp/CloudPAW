param location string = 'uksouth'
param sessionHostPrefix string = 'cPAW'


//Deploy the Hostpool
resource HostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' = {
  name: '${sessionHostPrefix}-HostPool'
  location: location
  properties: {
    friendlyName: '${sessionHostPrefix} Host Pool'
    description: '${sessionHostPrefix} Virual Privileged Access Workstaiotn Host Pool for privielged users to securely access the Microsoft Admin centers from'
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    maxSessionLimit: 5
    personalDesktopAssignmentType: 'Automatic'
    startVMOnConnect: true
    preferredAppGroupType: 'Desktop'
    customRdpProperty: 'enablecredsspsupport:i:0;authentication level:i:2;enablerdsaadauth:i:1;'
  }
}

//Deploy the vPAW Desktop Application Group
resource AppGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-07-12' = {
  name: '${sessionHostPrefix}-AppGroup'
  location: location
  properties: {
    description: '${sessionHostPrefix} Application Group'
    friendlyName: '${sessionHostPrefix} Desktop Application Group'
    hostPoolArmPath: HostPool.id
    applicationGroupType: 'Desktop'
  }
}

//Deploy the vPAW Workspace 
resource Workspace 'Microsoft.DesktopVirtualization/workspaces@2021-07-12' = {
  name: '${sessionHostPrefix}-Workspace'
  location: location
  properties: {
    description: '${sessionHostPrefix} Workspace for Privileged Users'
    friendlyName: '${sessionHostPrefix} Workspace'
   applicationGroupReferences: [
    AppGroup.id
   ]
    
}
}

