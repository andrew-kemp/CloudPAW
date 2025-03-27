# Variables
$resourceGroupName = "cPAW"
$automationAccountName = "cPAW-Automation"
$location = "UKSouth"
$vmNames = @("cPAW-0", "cPAW-1")
$shutdownTime = "19:00"

# Create Automation Account
az automation account create --resource-group $resourceGroupName --name $automationAccountName --location $location

# Deploy Start/Stop VMs Solution
$solutionName = "StartStopVmsDuringOffHours"
az automation solution create --resource-group $resourceGroupName --automation-account-name $automationAccountName --name $solutionName

# Configure Shutdown Schedule
foreach ($vmName in $vmNames) {
    az vm auto-shutdown -g $resourceGroupName -n $vmName --time $shutdownTime --timezone "UTC"
}

# Assign VMs to the Schedule
$runbookName = "StopAzureVms"
foreach ($vmName in $vmNames) {
    az automation runbook create --resource-group $resourceGroupName --automation-account-name $automationAccountName --name $runbookName --vm-name $vmName --schedule-name "ShutdownSchedule"
}
