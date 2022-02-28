#User Migration Project Start
$OldComputername = Read-Host -Prompt 'What is your old computer name?'
$NewComputerName = Read-Host -Prompt 'What is your new computer name?'
$Username = Read-Host -Prompt 'What is the exact user name of the account we are copying today?'
#Testing Connections and User Folder
Try {
Test-Connection -ComputerName $OldComputername -Count 1 -ErrorAction Stop | Select-Object Address, IPV4Address
Write-Host "$OldComputerName is Online Proceeding" -ForegroundColor Green    
}
Catch [System.Net.NetworkInformation.PingException] {
Write-Host "$OldComputername is Offline Stopping" -ForegroundColor Red
break
}

Try {
Test-Connection -ComputerName $NewComputername -Count 1 -ErrorAction Stop | Select-Object Address, IPV4Address
Write-Host "$NewComputerName is Online Proceeding" -ForegroundColor Green
}
Catch [System.Net.NetworkInformation.PingException] {
Write-Host "$NewComputername is Offline Stopping" -ForegroundColor Red
break
}

if (Test-Path -Path \\$Oldcomputername\c$\Users\$Username\) {
Write-Host "$Username User Folder Found Proceeding" -ForegroundColor Green
}
else {
Write-Host "$Username User Folder Not Found Stopping" -ForegroundColor Red
break
}
#Creating New Destination Folders
If (New-Item -Path \\$NewComputername\C$\Temp\ -ItemType Directory -Name $Username) {
Write-Host "$Username Folder Was Successfully Created" -ForegroundColor Green
}
else {
Write-Host "$Username Folder cannot be created" -ForegroundColor Red
}

If (New-Item -Type Directory -Path \\$NewComputername\C$\Temp\$Username\ -Name '\Appdata\Local\Google\Chrome\User Data\Default' -Force) {
Write-Host "Google Chrome Bookmarks Directory Was Successfully Created" -ForegroundColor Green
}
Else {
Write-Host "Creating Google Chrome Bookmarks Directory Failed" -ForegroundColor Red
}

If (New-Item -Path \\$NewComputername\C$\Temp\$Username\Appdata\ -ItemType Directory -Name '\Roaming\Microsoft\') {
Write-Host "Outlook Signature Directory was Successfully Created" -ForegroundColor Green
}
Else {
Write-Host "Creating Outlook Signature Directory Failed" -ForegroundColor Red
}

If (New-Item -Path \\$NewComputername\C$\Temp\$Username\ -ItemType Directory -Name Desktop) {
Write-Host "Desktop Directory Was Succesfully Created" -ForegroundColor Green
}
Else {
Write-Host "Creating Desktop Directory Failed" -ForegroundColor Red
}

If (New-Item -Path \\$NewComputername\C$\Temp\$Username\ -ItemType Directory -Name Downloads) {
Write-Host "Download Directory Was Successfully Created" -ForegroundColor Green
}
Else {
Write-Host "Creating Download Directory Failed" -ForegroundColor Red
}

If (New-Item -Path \\$NewComputername\C$\Temp\$Username\ -ItemType Directory -Name Favorites) {
Write-Host "Favorites Directory Was Succesfully Created" -ForegroundColor Green
}
Else {
Write-Host "Creating Favorites Directory Failed" -ForegroundColor Red
}

#Start of Copying Over Items
Try
{
Get-ChildItem \\$OldComputername\C$\Users\$Username\AppData\Local\Google\Chrome\User Data\Default\bookmarks* | Copy-Item -Destination \\$NewComputerName\C$\Temp\$Username\AppData\Local\Google\Chrome\User Data\Default\
Write-Host "Google Chrome Bookmarks Successfully Transferred" -ForegroundColor Green
}
Catch {
Write-Host "Google Chrome Bookmarks Failed to Transfer!" -ForegroundColor Red
}

Try
{
robocopy \\$OldComputername\C$\Users\$Username\Downloads\ \\$NewComputerName\C$\Temp\$Username\Downloads /MT:8 /E /R:1 /W:1
Write-Host "Downloads Successfully Transferred" -ForegroundColor Green
}
Catch {
Write-Host "Downloads Failed to Transfer" -ForegroundColor Red
}

Try
{
robocopy \\$OldComputername\C$\Users\$Username\Desktop\ \\$NewComputerName\C$\Temp\$Username\Desktop  /MT:8 /E /R:1 /W:1
Write-Host "Desktop Successfully Transferred" -ForegroundColor Green
}
Catch {
Write-Host "Desktop Failed to Transfer" -ForegroundColor Red
}

Try
{
robocopy \\$OldComputername\C$\Users\$Username\Favorites\ \\$NewComputerName\C$\Temp\$Username\Favorites  /MT:8 /E /R:1 /W:1
Write-Host "Favorites Successfully Transferred" -ForegroundColor Green
}
Catch {
Write-Host "Favorites Failed to Transfer" -ForegroundColor Red
}

Try
{
robocopy \\$OldComputername\C$\Users\$Username\Appdata\Roaming\Microsoft\Signatures\ \\$NewComputerName\C$\Temp\$Username\Appdata\Roaming\Microsoft\Signatures\ /MT:8 /E /R:1 /W:1
Write-Host "Outlook Signatures Successfully Transferred" -ForegroundColor Green
}
Catch {
Write-Host "Outlook Signatures Failed to Transfer" -ForegroundColor Red
}
Write-Host "Exiting Script" -ForegroundColor Cyan