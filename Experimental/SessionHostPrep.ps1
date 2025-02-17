#CLoud Kerberos
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
New-ItemProperty -Path $RegPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1 -PropertyType DWord
#Clean up Apps
$UWPAppstoRemove = @(
"Microsoft.BingNews",
"Microsoft.GamingApp",
"Microsoft.MicrosoftSolitaireCollection",
"Microsoft.WindowsCommunicationsApps",
"Microsoft.WindowsFeedbackHub",
"Microsoft.XboxGameOverlay",
"Microsoft.XboxGamingOverlay",
"Microsoft.XboxIdentityProvider",
"Microsoft.XboxSpeechToTextOverlay",
"Microsoft.YourPhone",
"Microsoft.ZuneMusic",
"Microsoft.ZuneVideo",
"MicrosoftTeams",
"Microsoft.OutlookForWindows",
"Microsoft.Windows.DevHome",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.MicrosoftStickyNotes",
"Microsoft.People",
"Microsoft.ScreenSketch",
"microsoft.windowscommunicationsapps",
"Microsoft.WindowsFeedbackHub",
"Microsoft.WindowsMaps"
"Microsoft.WindowsSoundRecorder"
"Microsoft.Xbox.TCUI"
"Microsoft.Windows.AugLoop.CBS"
"Microsoft.Windows.CapturePicker"
"Microsoft.Windows.NarratorQuickStart"
"Microsoft.Windows.ParentalControls"
"Microsoft.Windows.PeopleExperienceHost"
"Microsoft.Windows.PinningConfirmationDialog"
"Microsoft.Windows.PrintQueueActionCenter"
"Microsoft.Windows.StartMenuExperienceHost"
"Microsoft.Windows.XGpuEjectDialog"
"Microsoft.WindowsAppRuntime.CBS.1.6"
"Microsoft.WindowsAppRuntime.CBS"
"Microsoft.XboxGameCallableUI"
"Windows.CBSPreview"
"Clipchamp.Clipchamp"
"Microsoft.BingSearch"
"Microsoft.BingWeather"
"Microsoft.GetHelp"
"Microsoft.MicrosoftOfficeHub"
"Microsoft.MicrosoftStickyNotes"
"Microsoft.OutlookForWindows"
"Microsoft.Paint"
"Microsoft.PowerAutomateDesktop"
"Microsoft.RawImageExtension"
"Microsoft.ScreenSketch"
"Microsoft.StorePurchaseApp"
"Microsoft.Todos"
"Microsoft.WebMediaExtensions"
"Microsoft.WebpImageExtension"
"Microsoft.Windows.DevHome"
"Microsoft.Windows.Photos"
"Microsoft.WindowsAlarms"
"Microsoft.WindowsCalculator"
"Microsoft.WindowsCamera"
"Microsoft.WindowsSoundRecorder"
"Microsoft.WindowsStore"
"Microsoft.Xbox.TCUI"
"MicrosoftCorporationII.QuickAssist"
"MSTeams"
"*Microsoft.Getstarted*"

)
# Remove preinstalled Microsoft Store applications for all users and from the Windows image
foreach ($UWPApp in $UWPAppstoRemove) {
Get-AppxPackage -Name $UWPApp -AllUsers | Remove-AppxPackage -AllUsers -verbose
Get-AppXProvisionedPackage -Online | Where-Object DisplayName -eq $UWPApp | Remove-AppxProvisionedPackage -Online -verbose
}
