param logicAppName string = 'vmAutoShutdownLogicApp'
param resourceGroupName string
param location string = resourceGroup().location

resource vms 'Microsoft.Compute/virtualMachines@2021-07-01' existing = [for vm in listResources(resourceGroupName, 'Microsoft.Compute/virtualMachines'): {
  name: vm.name
}]

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [19]
              minutes: [0]
            }
            timeZone: 'GMT Standard Time'
          }
        }
      }
      actions: {
        foreachVM: {
          type: 'Foreach'
          foreach: vms
          actions: {
            deallocateVM: {
              type: 'Http'
              inputs: {
                method: 'POST'
                uri: 'https://management.azure.com${foreachVM.properties.resourceId}/deallocate?api-version=2021-07-01'
                headers: {
                  Authorization: 'Bearer @{listKeys(resourceId('Microsoft.Web/connections', 'azurevm'), '2016-06-01').primaryKey}'
                }
              }
            }
          }
        }
      }
    }
  }
}