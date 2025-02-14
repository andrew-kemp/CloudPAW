param (
    [string]$RegistrationKey
)

# Import the necessary module
Import-Module -Name Az.DesktopVirtualization

# Define the host pool name and resource group
$hostPoolName = "YourHostPoolName"
$resourceGroupName = "YourResourceGroupName"

# Join the session host to the host pool
$sessionHostName = $env:COMPUTERNAME
$joinResult = Register-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -SessionHostName $sessionHostName -RegistrationInfoToken $RegistrationKey

if ($joinResult) {
    Write-Output "Successfully joined $sessionHostName to the host pool $hostPoolName."
} else {
    Write-Error "Failed to join $sessionHostName to the host pool $hostPoolName."
}