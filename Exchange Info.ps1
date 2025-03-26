# Define output paths
$csvPath = "C:\ExchangeAudit\"
$htmlPath = "C:\ExchangeAudit\Report.html"

# Create directories if they don't exist
if (!(Test-Path $csvPath)) {
    New-Item -Path $csvPath -ItemType Directory
}

# List all Exchange servers with their versions and roles
$servers = Get-ExchangeServer | Select-Object Name, Edition, AdminDisplayVersion, ServerRole
$servers | Export-Csv -Path "$csvPath\ExchangeServers.csv" -NoTypeInformation

# List all databases and which servers they are located on
$databases = Get-MailboxDatabase | Select-Object Name, Server
$databases | Export-Csv -Path "$csvPath\Databases.csv" -NoTypeInformation

# List all user mailboxes and sizes and database
$userMailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox | Select-Object DisplayName, Database, @{Name="Size";Expression={(Get-MailboxStatistics $_).TotalItemSize}}
$userMailboxes | Export-Csv -Path "$csvPath\UserMailboxes.csv" -NoTypeInformation

# List all shared mailboxes with sizes and database
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox | Select-Object DisplayName, Database, @{Name="Size";Expression={(Get-MailboxStatistics $_).TotalItemSize}}
$sharedMailboxes | Export-Csv -Path "$csvPath\SharedMailboxes.csv" -NoTypeInformation

# List all resource mailboxes with size and database
$resourceMailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox, EquipmentMailbox | Select-Object DisplayName, Database, @{Name="Size";Expression={(Get-MailboxStatistics $_).TotalItemSize}}
$resourceMailboxes | Export-Csv -Path "$csvPath\ResourceMailboxes.csv" -NoTypeInformation

# List all Exchange URLs
$urls = Get-ExchangeServer | Select-Object Name, @{Name="URLs";Expression={($_ | Get-ClientAccessServer).AutoDiscoverServiceInternalUri}}
$urls | Export-Csv -Path "$csvPath\ExchangeURLs.csv" -NoTypeInformation

# List all accepted domains
$acceptedDomains = Get-AcceptedDomain | Select-Object Name, DomainName
$acceptedDomains | Export-Csv -Path "$csvPath\AcceptedDomains.csv" -NoTypeInformation

# List all email address policies
$emailAddressPolicies = Get-EmailAddressPolicy | Select-Object Name, EnabledPrimarySMTPAddressTemplate, RecipientFilter
$emailAddressPolicies | Export-Csv -Path "$csvPath\EmailAddressPolicies.csv" -NoTypeInformation

# Generate HTML report
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Exchange Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Exchange Audit Report</h1>
    <h2>Exchange Servers</h2>
    $(Import-Csv "$csvPath\ExchangeServers.csv" | ConvertTo-Html -Fragment)
    <h2>Databases</h2>
    $(Import-Csv "$csvPath\Databases.csv" | ConvertTo-Html -Fragment)
    <h2>User Mailboxes</h2>
    $(Import-Csv "$csvPath\UserMailboxes.csv" | ConvertTo-Html -Fragment)
    <h2>Shared Mailboxes</h2>
    $(Import-Csv "$csvPath\SharedMailboxes.csv" | ConvertTo-Html -Fragment)
    <h2>Resource Mailboxes</h2>
    $(Import-Csv "$csvPath\ResourceMailboxes.csv" | ConvertTo-Html -Fragment)
    <h2>Exchange URLs</h2>
    $(Import-Csv "$csvPath\ExchangeURLs.csv" | ConvertTo-Html -Fragment)
    <h2>Accepted Domains</h2>
    $(Import-Csv "$csvPath\AcceptedDomains.csv" | ConvertTo-Html -Fragment)
    <h2>Email Address Policies</h2>
    $(Import-Csv "$csvPath\EmailAddressPolicies.csv" | ConvertTo-Html -Fragment)
</body>
</html>
"@

# Save HTML report
$htmlContent | Out-File -FilePath $htmlPath