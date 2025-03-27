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
$devicename = Read-Host -Prompt "Enter the name of Device you want to allow connections to the PAW"

$Accessdevice = Get-MgDevice -Filter "startswith(displayName,'$devicename')"


$params = @{
    extensionAttributes = @{
        extensionAttribute1 = "PAW Access"
    }
}


    Update-MgDevice -DeviceId $device.Id -BodyParameter $params
