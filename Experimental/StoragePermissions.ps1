# Connect to Azure
#Connect-AzAccount

# Retrieve the subscription ID dynamically
$subscriptions = Get-AzSubscription
$subscriptions | ForEach-Object { Write-Host "$($_.Name) - $($_.Id)" }
$subscriptionList = $subscriptions | ForEach-Object { "$($_.Name) - $($_.Id)" }

# Display the subscription list with numbers
for ($i = 0; $i -lt $subscriptionList.Count; $i++) {
    Write-Host "$i. $($subscriptionList[$i])"
}

# Prompt for the subscription number
$subscriptionNumber = Read-Host -Prompt "Enter the number of the subscription from the list above"
$selectedSubscription = $subscriptions[$subscriptionNumber]
$subscriptionId = $selectedSubscription.Id

# Set the context to the selected subscription
Set-AzContext -SubscriptionId $subscriptionId

# Prompt for Resource Group Name
$resourceGroupName = Read-Host -Prompt "Enter Resource Group Name (Press Enter for 'cPAW')"
if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    $resourceGroupName = "cPAW"
}

# Prompt for Storage Account Prefix
$storageAccountPrefix = Read-Host -Prompt "Enter Storage Account Prefix (Press Enter for 'cpawstorage')"
if ([string]::IsNullOrWhiteSpace($storageAccountPrefix)) {
    $storageAccountPrefix = "cpawstorage"
}

# Find the storage account in the resource group
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName | Where-Object { $_.StorageAccountName -like "$storageAccountPrefix*" }

if ($null -eq $storageAccount) {
    Write-Host "No storage account found with the prefix '$storageAccountPrefix' in the resource group '$resourceGroupName'."
    exit
}

# Prompt for Group Name
$groupName = Read-Host -Prompt "Enter Group Name (Press Enter for '_user-cPAW-Users')"
if ([string]::IsNullOrWhiteSpace($groupName)) {
    $groupName = "_user-cPAW-Users"
}

# Get the Object ID of the group
$group = Get-AzADGroup -DisplayName $groupName
if ($null -eq $group) {
    Write-Host "No group found with the name '$groupName'."
    exit
}
$groupObjectId = $group.Id
Write-Host "Group Object ID: $groupObjectId"

# Add the role assignment to the storage account
New-AzRoleAssignment -ObjectId $groupObjectId -RoleDefinitionName "Storage File Data SMB Share Contributor" -Scope $storageAccount.Id

Write-Host "Role assignment completed successfully."