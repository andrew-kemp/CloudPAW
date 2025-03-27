# Function to check if a module is installed
function Install-ModuleIfNotInstalled {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    }
}

# Install and import the necessary modules to complete the setup
Install-ModuleIfNotInstalled -ModuleName "Microsoft.Graph"
Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Device.ReadWrite.All"

$adminName = Read-Host -Prompt "Enter the admin' everyday user name"
$searchName = "$adminName"

# Find the user object for the admin
$adminUser = Get-MgUser -Filter "startswith(userPrincipalName,'$searchName')"

if ($adminUser) {
    # Find the device whose primary owner is the admin user
    $device = Get-MgDevice -Filter "startswith(displayName,'$adminUser.displayName')"

    if ($device) {
        # Get the registered owner of the device
        $owner = Get-MgDeviceRegisteredOwner -DeviceId $device.Id | Where-Object { $_.userPrincipalName -eq $adminUser.userPrincipalName }

        if ($owner) {
            $params = @{
                extensionAttributes = @{
                    extensionAttribute1 = "PAW Access"
                }
            }

            Update-MgDevice -DeviceId $device.Id -BodyParameter $params
            Write-Host "Device extension attribute updated successfully."
        } else {
            Write-Host "No device found for the specified admin user."
        }
    } else {
        Write-Host "No device found for the specified admin user."
    }
} else {
    Write-Host "Admin user not found."
}