# Set your Azure subscription context (if not already done)
Connect-AzAccount -UseDeviceAuthentication

# Replace with your unique Key Vault name
$KeyVaultName = "kv2320242"

# Replace with your secret names (e.g., APIKEY and ClientSecret)
$SecretNameAPIKEY = "APIKEY"
$SecretNameClientSecret = "ClientSecret"

# Prompt user for new secret values
$NewAPIKEY = Read-Host "Enter the new APIKEY value:" -AsSecureString
$NewClientSecret = Read-Host "Enter the new ClientSecret value:" -AsSecureString

# Update secrets in Key Vault
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameAPIKEY -SecretValue $NewAPIKEY
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameClientSecret -SecretValue $NewClientSecret

Write-Host "Secrets updated successfully!"