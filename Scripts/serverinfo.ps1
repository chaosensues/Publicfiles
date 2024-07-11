#Author:  Forrest Fawcett
#Purpose:  Collect baseline information for Windows Systems

function get-extip {
    (Invoke-WebRequest ifconfig.me/ip).Content
}

If(Test-path c:\temp) {} else{New-Item -ItemType directory -Path c:\temp}
Set-Location C:\Temp

#create folder with date
$date = Get-Date
$date = $date.ToString("yyyy-MM-dd")
$datafolder = ".\Data\$env:COMPUTERNAME $date"
If(Test-path $datafolder) {Remove-item $datafolder -Recurse}
New-Item -ItemType directory -Path $datafolder
$SummaryFile = "$datafolder\$env:COMPUTERNAME.txt"
New-Item -Path $SummaryFile -ItemType file 

#create file with server info
$network = Get-WmiObject Win32_NetworkAdapterConfiguration 
$network = $network.IpAddress
Write-Output $date  > $SummaryFile


#Produce Version Info Report
"System Info" | Out-File $SummaryFile -append
"___________" | Out-File $SummaryFile -append
systeminfo | Select-string "Host Name","OS Name","OS Version","OS COnfiguration","Original Install Date","System Manufacturer","System Model","Total Physical Memory" | Out-File $SummaryFile -append
"CPU Info" | Out-File $SummaryFile -append
Get-WmiObject -Class Win32_Processor -ComputerName. | Select-Object -property Name,NumberofCores,Numberoflogicalprocessors | Out-File $SummaryFile -append
"Network" | Out-File $SummaryFile -append
Write-Output $network | Out-File $SummaryFile -append
try {
    $extip = get-extip
    "External IP:  $extip" | Out-File $SummaryFile -append
}
catch {
    "I was not able to find the external IP" | Out-File $SummaryFile -append
}
" " | Out-File $SummaryFile -append

#Get installed software and create list in txt
"Software" | Out-File $SummaryFile -append

Write-Host "Collecting Installed Software"
Get-WmiObject -Class Win32_Product | Select-Object -Property Name, Version | Out-File $SummaryFile -append

#Get installed role and create list in txt
"Server Roles" | Out-File $SummaryFile -append
"____________" | Out-File $SummaryFile -append
Write-Host "Collecting Server Roles"
Import-module servermanager ; Get-WindowsFeature | where-object {$_.Installed -eq $True} | Select-Object -Property DisplayName | Out-File $SummaryFile -append

#retrieve enabled GPOs for domain
$gpm = Get-WindowsFeature | Where-Object {$_.DisplayName -like "Group Policy Management" -and $_.Installed -eq $True} 
if ($gpm.InstallState -like "Installed") {
    "Enabled Group Policies" | Out-File $SummaryFile -append
    "______________________" | Out-File $SummaryFile -append
    Write-Host "Collecting Group Policy Info"
    get-gpo -all | where-object {$_.GpoStatus -like "AllSettingsEnabled"} | select-object  DisplayName | Out-File $SummaryFile -append
}

#get services status
"Running Services" | Out-File $SummaryFile -append
"___________" | Out-File $SummaryFile -append
Write-Host "Collecting Services"
Get-Service | where-object {$_.Status -eq "Running"} | Select-Object -Property DisplayName, Status | Out-File $SummaryFile -append

"Stopped Services" | Out-File $SummaryFile -append
"___________" | Out-File $SummaryFile -append
Get-Service | where-object {$_.Status -eq "Stopped"} | Select-Object -Property DisplayName, Status | Out-File $SummaryFile -append

#get list of printers
"Shared Printers" | Out-File $SummaryFile -append
"________________" | Out-File $SummaryFile -append
Write-Host "Collecting Shared Printers"
get-printer | where-object {$_.Shared -eq $True} | Select-Object name, shared | Out-File $SummaryFile -append

#get list of shares
"SMB Shares" | Out-File $SummaryFile -append
"___________" | Out-File $SummaryFile -append
Write-Host "Collecting Share Info"
get-smbshare|  Select-Object name, description | Out-File $SummaryFile -append

Write-host "Data collection is complete.  Summary file is: $SummaryFile"