$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
New-ItemProperty -Path $RegPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1 -PropertyType DWord
