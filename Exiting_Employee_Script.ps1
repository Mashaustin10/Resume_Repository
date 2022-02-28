#(NOTES) EXITING EMPLOYEE STEPS
# 1. DISABLE ACCOUNT
# 2. CHANGE DESCRIPTION FIELD TO TICKET NUMBER 
# 3. ADD DISABLED ACCOUNTS>SET DISABLED ACCOUNTS AS PRIMARY GROUP> REMOVE ALL OTHER USER GROUPS
# 4. MOVE ACCOUNT TO "OU=DisabledUsers,DC=Test,DC=net" OR FOR MAILBOX RETENTION "OU=MailRetentionOU,DC=Test,DC=net"

#Importing Active Directory Module
Import-Module ActiveDirectory

#Specify Default DC
$PSDefaultParameterValues = @{"*-AD*:Server"="DC1.TEST.net"}

#Prompting User for Data Input
Write-Host "WARNING:This Script Will Remove All User Groups, Move User to Another OU, Disable The User Account, and Change The AD Account Description, There is Going Back Once Changes Are Made" -ForegroundColor Red
$TargetUserName = Read-Host -Prompt "What is the Exiting Employees User Name?"
$TicketNumber = Read-Host -Prompt "Please Enter Ticket Number, This Will Be the New Description"
$OU = Read-Host -Prompt "Please Enter Exactly the Number Next to the OU The User Is Going Into 1.DisabledUsers 2.MailboxRetention"
$NormalDisabled = "OU=DisabledUsers,DC=Test,DC=net"
$MailBoxRetention = "OU=MailRetentionOU,DC=Test,DC=net"
$DisabledGroup = "CN=DisabledPrimaryGroup,OU=CodingTESTGROUPS,DC=Test,DC=net"

#Testing and Verifying Connection and That Account the Account Exists
try {
    Get-ADUser $TargetUserName -ErrorAction Stop
    Write-Host "$TargetUserName Found Proceeding" -ForegroundColor Green
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "$TargetUserName Not Found Stoppping Script" -ForegroundColor Red
    Break
 }

 #Disabling User Account
try {
    Disable-ADAccount -Identity $TargetUserName -Confirm -ErrorAction Stop
    Write-Host "$TargetUserName Successfully Disabled Proceeding" -ForegroundColor Green
}
catch {
    Write-Host "$TargetUserName Not Disabled Stopping Script" -ForegroundColor Red
   break
}

 #Inputting Ticket Number Into Account Description
 try {
    Set-ADUser $TargetUserName -Description "$TicketNumber"
    Write-Host "Set $TargetUserName Description as $TicketNumber Proceeding" -ForegroundColor Green
 }
 catch {
     Write-Host "Cannot Set $TargetUserName Description to $TicketNumber Please Adjust this Manually on Script Exit." -ForegroundColor Red
     
 }
 

 #Switching User to Assigned OU 1=DisabledUsers 2=MailBoxRetention
 switch ($OU) {
     1 {Get-ADUser -Identity $TargetUserName | Move-ADObject -TargetPath "$NormalDisabled" ; Write-Host "Adding $TargetUserName to $NormalDisabled" -ForegroundColor Green ; Break}
     2 {Get-ADUser -Identity $TargetUserName | Move-ADObject -TargetPath "$MailBoxRetention" ; Write-Host "Adding $TargetUserName to $MailBoxRetention" -ForegroundColor Green ; Break}
     Default {
         Write-Host "Incorrect OU Selection Please Check User Account Manually on Script Exit" -ForegroundColor Red
         
     }
 }

 #Add Disabled Users OU 
 try {
     Add-ADGroupMember -Identity "$DisabledGroup" -Members $TargetUserName
     Write-Host "Added Disabled Group to User $TargetUserName" -ForegroundColor Green
 }
 catch {
     Write-Host "Cannot Add Disabled Group to $TargetUserName, Double Check this you may need to add it manually." -ForegroundColor Red
     
     
 }

 #Change Primary Group
 try {
    $adGroup = Get-ADGroup -Identity $DisabledGroup
    $GroupID = $adGroup.SID.Value.Split('-')[-1]
    Get-ADUser $TargetUserName | Set-ADObject -Replace @{primaryGroupID=$GroupID}
    Write-Host "Changed Primary Group to DisabledOU" -ForegroundColor Green
 }
 catch {
     Write-Host "Failed to Change Primary Group to $DisabledGroup, Check the user after script has exited" -ForegroundColor Red
     
 }
 
 #Remove Previously Defaulted Group
 
    Get-ADPrincipalGroupMembership $TargetUserName| where {$_.name -ne "DisabledPrimaryGroup"}| ForEach-Object {Remove-ADGroupMember $_ -Members $TargetUserName -Confirm:$false -Ev Err -ErrorAction SilentlyContinue} 
    Write-Host "Removing $TargetUserName's Groups" -ForegroundColor Green

 

 #Pause for 2nd pass
 Write-Host "Pausing before 2nd pass 15 seconds" -ForegroundColor Green
 Start-Sleep -Seconds 15

  #Remove Previously Defaulted Group
  Get-ADPrincipalGroupMembership $TargetUserName| where {$_.name -ne "DisabledPrimaryGroup"}| ForEach-Object {Remove-ADGroupMember $_ -Members $TargetUserName -Confirm:$false -Ev Err -ErrorAction SilentlyContinue} 
    Write-Host "Running 2nd pass on $TargetUserName's Groups" -ForegroundColor Green

#Exit Statement
 Write-Host "Alright You Are Done, Please Take The Time To Double Check That Everything Is Correct For the User" -ForegroundColor Cyan
