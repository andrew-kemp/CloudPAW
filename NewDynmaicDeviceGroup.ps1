# Prompt for the prefix
$prefix = Read-Host -Prompt "Enter the prefix for device display names (default: cPAW)"
if ([string]::IsNullOrWhiteSpace($prefix)) {
    $prefix = "cPAW"
}

# Define the group properties
$group = @{
    displayName = "$prefix Dynamic Device Group"
    mailEnabled = $false
    mailNickname = "$prefix-dynamicdevicegroup"
    securityEnabled = $true
    groupTypes = @("DynamicMembership")
    membershipRule = "(device.displayName -startsWith '$prefix')"
    membershipRuleProcessingState = "On"
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All"

# Create the dynamic device group
New-MgGroup -BodyParameter $group
