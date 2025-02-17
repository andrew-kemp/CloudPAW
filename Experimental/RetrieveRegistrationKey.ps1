param (
    [string]$RegistrationKey,
    [string]$HostPoolName,
    [string]$ResourceGroupName,
    [string]$ModulesURL
)

# Import the necessary module
Import-Module -Name Az.DesktopVirtualization

# Download and import the configuration module
Invoke-WebRequest -Uri $ModulesURL -OutFile 'Configuration.zip'
Expand-Archive -Path 'Configuration.zip' -DestinationPath 'Configuration'
Import-Module -Name 'Configuration'

# Join the session host to the host pool
$sessionHostName = $env:COMPUTERNAME
$joinResult = Register-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SessionHostName $sessionHostName -RegistrationInfoToken $RegistrationKey

if ($joinResult) {
    Write-Output "Successfully joined $sessionHostName to the host pool $HostPoolName."
} else {
    Write-Error "Failed to join $sessionHostName to the host pool $HostPoolName."
}
