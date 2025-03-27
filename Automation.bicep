param DefaultPrefix string = 'cPAW'

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-05-15-preview' = {
  name: '${DefaultPrefix}-AutomationAccount'
  location: resourceGroup().location
  properties: {
    disableLocalAuth: true
    publicNetworkAccess: false
    sku: {
      name: 'Basic'
      capacity: 1
    }
  }
  tags: {
    environment: 'production'
  }
}

resource startStopSolution 'Microsoft.Automation/automationAccounts@2023-05-15-preview' = {
  name: 'StartStopVmsDuringOffHours'
  parent: automationAccount
  properties: {
    // Add any specific properties for the solution here
  }
}

output solutionName string = startStopSolution.name
