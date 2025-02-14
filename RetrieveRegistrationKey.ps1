param (
    [string]$HostPoolName,
    [string]$ResourceGroupName,
    [string]$KeyVaultName,
    [string]$SecretName
)

# Import the necessary modules
Import-Module -Name Az.DesktopVirtualization
Import-Module -Name Az.KeyVault

# Retrieve the registration key
$registrationInfo = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $HostPoolName
$registrationKey = $registrationInfo.RegistrationInfo.Token

# Store the registration key in Azure Key Vault
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue (ConvertTo-SecureString $registrationKey -AsPlainText -Force)