# Get the user ID using the filter for UPN
$username = Read-Host -Prompt "Please enter the UPN of the user whose device you need to update"
$user = Get-MgUser -Filter "startswith(userPrincipalName,'$username')"

# Get a list of devices owned by the user
$devices = Get-MgUserOwnedDevice -UserId $user.Id

# Check if any devices were found
if ($devices.Count -eq 0) {
    Write-Host "No devices found for user ${username}."
} else {
    Write-Host "Devices owned by user ${username}:"
    $devices | ForEach-Object -Begin { $i = 0 } -Process {
        # Retrieve detailed information about each device
        $deviceDetails = Get-MgDevice -DeviceId $_.Id
        Write-Host "${i}: Device ID: $($_.Id), Device Name: $($deviceDetails.DisplayName), Manufacturer: $($deviceDetails.Manufacturer)"
        $i++
    }
    # Prompt to select a device
    $selection = Read-Host -Prompt "Enter the number of the device you want to select"

    # Validate the selection
    if ($selection -ge 0 -and $selection -lt $devices.Count) {
        $selectedDevice = $devices[$selection]
        $deviceDetails = Get-MgDevice -DeviceId $selectedDevice.Id

        # Check if detailed information is retrieved
        if ($deviceDetails) {
            Write-Host "You selected:"
            Write-Host "Device ID: $($deviceDetails.Id), Device Name: $($deviceDetails.DisplayName), Manufacturer: $($deviceDetails.Manufacturer), Model: $($deviceDetails.Model)"
                        # Update the device's extensionAttribute1
                        $params = @{
                            extensionAttributes = @{
                                extensionAttribute1 = "PAW Access"
                            }
                        }
                        Update-MgDevice -DeviceId $deviceDetails.Id -BodyParameter $params
                        Write-Host "extensionAttribute1 updated to 'PAW Access' for $($deviceDetails.DisplayName) device ID: $($deviceDetails.Id)"
                    } else {
                        Write-Host "Failed to retrieve detailed information for the selected device."
                    }
                } else {
                    Write-Host "Invalid selection."
                }
            }