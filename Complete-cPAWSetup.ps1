# Install and import the necessary modules to complete the setup
Install-Module Microsoft.Graph -Scope CurrentUser -Force
Install-Module -Name Az -Scope CurrentUser -Force
Install-Module -Name Az.DesktopVirtualization -Scope CurrentUser -Force
#Import-Module Microsoft.Graph
#Import-Module Az
#Import-Module Az.DesktopVirtualization


# Prompt for the resource group name
#$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group and session host prefix? eg: cPAW"


# Prompt for the resource group name
$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group and session host prefix? or press enter to use the default cPAW"

# Set default value if input is empty
if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    $resourceGroupName = "cPAW"
}

Write-Output "Resource Group Name: $resourceGroupName"


# Connect to Microsoft Graph using device code authentication with Directory scope
Connect-MgGraph -Scopes "Directory.ReadWrite.All"

# Connect to your Azure account
Connect-AzAccount

# Define group names
$userGroupName = "_User-$resourceGroupName-Users"
$adminGroupName = "_User-$resourceGroupName-Admins"
$deviceGroupName = "_Device-$resourceGroupName"

# Define the service principal name for Azure Virtual Desktop
$avdServicePrincipalName = "Azure Virtual Desktop"

# Create AVD Users group
$userGroup = New-MgGroup -DisplayName $userGroupName -MailEnabled:$false -SecurityEnabled:$true -MailNickname "usercpawusers"

# Create AVD Admins group
$adminGroup = New-MgGroup -DisplayName $adminGroupName -MailEnabled:$false -SecurityEnabled:$true -MailNickname "usercpawadmins"

# Create Dynamic Device group
# Define the group body
$groupBody = @{
    displayName = "$deviceGroupName"
    mailEnabled = $false
    mailNickname = "dynamicdevicegroup"
    securityEnabled = $true
    groupTypes = @("DynamicMembership")
    membershipRule = "(device.displayName -startsWith `"$resourceGroupName`")"
    membershipRuleProcessingState = "On"
}
# Create the group
$group = New-MgGroup -BodyParameter $groupBody
Write-Output "Group created with ID: $($group.Id)"

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



# Assign "Virtual Machine User Login" role to cPAW-User group
New-AzRoleAssignment -ObjectId $userGroup.Id -RoleDefinitionName "Virtual Machine User Login" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

# Assign "Virtual Machine User Login" role to cPAW-Admin group
New-AzRoleAssignment -ObjectId $adminGroup.Id -RoleDefinitionName "Virtual Machine User Login" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

# Assign "Virtual Machine Administrator Login" role to cPAW-Admin group
New-AzRoleAssignment -ObjectId $adminGroup.Id -RoleDefinitionName "Virtual Machine Administrator Login" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

# Retrieve the service principal object ID
$avdServicePrincipal = Get-AzADServicePrincipal -DisplayName $avdServicePrincipalName
$avdServicePrincipalId = $avdServicePrincipal.Id

# Assign "Desktop Virtualization Power On Contributor" role to the Azure Virtual Desktop service principal
New-AzRoleAssignment -ObjectId $avdServicePrincipalId -RoleDefinitionName "Desktop Virtualization Power On Contributor" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"


# Create the application group name using the resource group name prefix
$appGroupName = "$resourceGroupName-AppGroup"

# Retrieve the object IDs of the user groups
$userGroupId = (Get-AzADGroup -DisplayName $userGroupName).Id
$adminGroupId = (Get-AzADGroup -DisplayName $adminGroupName).Id

# Retrieve the resource ID of the application group
$appGroupPath = (Get-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $resourceGroupName).Id

# Assign the cPAW-User group to the application group
New-AzRoleAssignment -ObjectId $userGroupId -RoleDefinitionName "Desktop Virtualization User" -Scope $appGroupPath

# Assign the cPAW-Admin group to the application group
New-AzRoleAssignment -ObjectId $adminGroupId -RoleDefinitionName "Desktop Virtualization User" -Scope $appGroupPath

# Retrieve the session desktop application
$sessionDesktop = Get-AzWvdDesktop -ResourceGroupName $resourceGroupName -ApplicationGroupName $appGroupName -Name "SessionDesktop"

# Update the display name
$sessionDesktop.FriendlyName = "Privileged Access Desktop"
Update-AzWvdDesktop -ResourceGroupName $resourceGroupName -ApplicationGroupName $appGroupName -Name "SessionDesktop" -FriendlyName "Privileged Access Desktop"

