# Try-Catch error handling

Try {
# Import modules
Import-Module ActiveDirectory
#Set Default Domain Controller
$PSDefaultParameterValues = @{"*-AD*:Server"="DC1.test.net"}

Do {
# Collect data from the prompt for new user creation
Write-Host "Please enter the details for the new user."
$GivenName = Read-Host "First Name"
$Surname = Read-Host "Last Name"
$Username = Read-Host "Short Username"

# Check for duplicate SamAccountName
$UserQuery = Get-ADUser -LDAPFilter "(SamAccountName=$Username)"
If ($Null -ne $UserQuery) {
Do {
 Write-Host "ERROR: Duplicate short username found, please try again!"
$Username = Read-Host "Short Username"
$UserQuery = Get-ADUser -LDAPFilter "(SamAccountName=$Username)"
} Until ($Null -eq $UserQuery)
}
#Collect temp password and template user to clone user groups
$TempPassword = Read-Host "Temporary Password" | ConvertTo-SecureString -AsPlainText -Force
$DrivePath = "\\DC1\Users\$Username\Documents"
$DriveLetter = "P:"


# Check for Template
Do{($TemplateQuery = Read-Host "Enter Template Name")
Try{
$Template = Get-ADUser $TemplateQuery -ErrorAction Stop
Write-Host "$Template is Valid"
}Catch{
Write-Warning "Enter Valid Name"
}
}Until($Template -ne $null)

#Template Info Gathering
$TemplateParameters = Get-AdUser $Template -Property Department, Description, Office | Select-Object Department, Description, Office
$Department = $TemplateParameters.Department
$Description = $TemplateParameters.Description
$Title = $TemplateParameters.Title
$Office = $TemplateParameters.Office

#Check if Department is Null or Not
If($Null -eq $Department) {
Do {
Write-Host "Template Department is Blank"
$Department = Read-Host "Enter Department"
} Until ($Department -ne $Null)
}

#Check if Description is Null or Not
If($Null -eq $Description) {
Do {
Write-Host "Template Description is Blank"
$Description = Read-Host "Enter Description"
} Until ($Description -ne $Null)
}

#Check if Title is Null or Not
If($Null -eq $Title) {
Do {
Write-Host "Template Title is Blank"
$Title = Read-Host "Enter Title"
} Until ($Title -ne $Null)
}

#Check if Office is Null or Not
If($Null -eq $Office) {
Do {
Write-Host "Template Office is Blank"
$Office = Read-Host "Enter Office"
} Until ($Office -ne $Null)
}

# Check for Manager Name
Do{($ManagerQuery = Read-Host "Enter Managers Name")
Try{
$Manager = Get-ADUser $ManagerQuery -ErrorAction Stop
Write-Host "$Manager is Valid"
}Catch{
Write-Warning "Enter Valid Name"
}
}Until($Manager -ne $null)

# Compile and collect name, email, logon hours
$Name = "$GivenName $Surname"
$Email = "$Username@test.net"
$LogonHours = Get-AdUser $Template -Property LogonHours | Select-Object LogonHours
[array]$HoursValue = $LogonHours.logonhours

# Confirm syntax of the commands with the User
Write-Host "New-ADUser command syntax:`n
New-ADUser -path `"OU=CodeTestingOU,DC=Test,DC=net`" `
-Instance `"$Template`" `
-Name `"$Name`" `
-SamAccountName `"$Username`" `
-UserPrincipalName `"$Email`" `
-EmailAddress `"$Email`" `
-GivenName `"$GivenName`" `
-Surname `"$Surname`" `
-DisplayName `"$Name`" `
-HomeDirectory `"$DrivePath`" `
-AccountPassword `"$TempPassword`" `
-Manager `"$Manager`" `
-Department `"$Department`" `
-Title `"$Title`" `
-Description `"$Description`" `
-Office `"$Office`" `
-Enabled `$True `
-ChangePasswordAtLogon `$True `
`n"

# Show Logonhours syntax if the value is not null
If ($Null -ne $HoursValue) {
Write-Host "Set-ADUser command syntax for logon hours:`
Set-ADUser -identity $Username -replace @{logonhours = $HoursValue}`n"
}

$Confirmation = Read-Host "Do You Want To Proceed? (Y/N)"
If ($Confirmation -eq 'y') {
# Create the new user in AD in the specified OU
Write-Host "Creating the new user in the `"CodeTestingOU`" OU in local AD."
New-Item -Path "\\DC1\Users\" -Name "$Username\Documents" -ItemType "Directory" -Force
New-ADUser -path "OU=CodeTestingOU,DC=Test,DC=net" `
-Instance $Template `
-Name $Name `
-SamAccountName $Username `
-UserPrincipalName $Email `
-EmailAddress $Email `
-GivenName $GivenName `
-Surname $Surname `
-DisplayName $Name `
-AccountPassword $TempPassword `
-Manager $Manager `
-Department $Department `
-Description $Description `
-Title $Title `
-Office $Office `
-Enabled $True `
-ChangePasswordAtLogon $True `
# Check to see if Logon Hours for the template user are null, and if not then clone for the new user
If ($Null -eq $HoursValue) {
Write-Host "There are no logon hours defined for this template user."
}
Else {
Write-Host "Setting logon hours from the template user."
Set-ADUser -identity $Username -replace @{logonhours = $HoursValue}
}

# Wait for AD replication
Write-Host "Waiting for replication in local AD. (15s)"
Start-Sleep -s 15

#Setting Home Directory Permissions
$Acl = Get-Acl \\DC1\Users\$Username\
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("$Username", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl \\DC1\Users\$Username\ $Acl

# Wait for Permissions to Sync
Write-Host "Waiting for Permissions to Sync"
Start-Sleep -s 15

#Setting Home Directory
Set-Aduser -Identity $Username -HomeDirectory \\DC1\Users\$Username\Documents -Homedrive P: -Confirm:$False;

# Start an AD Sync Cycle on
Write-Host "Syncing local AD to Azure AD."
Invoke-Command -ComputerName DC1 -ScriptBlock {Start-ADSyncSyncCycle}

# Wait for the sync to finish
Write-Host "Waiting for sync to Azure AD. (30s)"
Start-Sleep -s 30

# Wait for Exchange Online to catch up
Write-Host "Waiting for Exchange Online. (15s)"
Start-Sleep -s 15

# Copy group membership from the template and add O365 licensing group


# Sync Azure AD again to update licensing
Invoke-Command -ComputerName DC1 -ScriptBlock {Start-ADSyncSyncCycle}

$Confirmation = Read-Host "Operation complete! Would you like to provision another user? (Y/N)"
}
Else {
Write-Host "Exiting script."
Exit-PSSession
Exit
}
}
Until ($Confirmation -ne "y")
Write-Host "Exiting script."
Exit-PSSession
Exit
}
Catch {
Write-Host "An error occurred:"
Write-Host $_
}
