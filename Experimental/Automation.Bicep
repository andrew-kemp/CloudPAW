param resourceGroupName string = 'cPAW'
param automationAccountName string = '${resourceGroupName}-Automation'
param runbookName string = 'ShutdownVMsRunbook'
param scheduleName string = 'DailyShutdownSchedule'
param location string = resourceGroup().location

resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2020-01-13-preview' = {
  parent: automationAccount
  name: runbookName
  location: location
  properties: {
    runbookType: 'PowerShellWorkflow'
    logVerbose: true
    logProgress: true
    description: 'Runbook to shutdown VMs in a resource group'
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/<username>/<repository>/main/ShutdownVMsRunbook.ps1'
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2020-01-13-preview' = {
  parent: automationAccount
  name: scheduleName
  properties: {
    startTime: utcNow().addMinutes(10) // Ensure the start time is at least 5 minutes from now
    expiryTime: '9999-12-31T23:59:59Z'
    interval: 1
    frequency: 'Day'
    timeZone: 'GMT Standard Time'
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2020-01-13-preview' = {
  parent: automationAccount
  name: '${runbookName}-${scheduleName}'
  properties: {
    runbook: {
      name: runbookName
    }
    schedule: {
      name: scheduleName
    }
  }
}
