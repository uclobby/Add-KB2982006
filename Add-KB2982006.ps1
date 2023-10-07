
<#PSScriptInfo

.VERSION 1.1

.GUID 45c0577f-debb-428c-9c3e-69012474e67c

.AUTHOR David Paulino

.COMPANYNAME UC Lobby

.COPYRIGHT

.TAGS Lync LyncServer SkypeForBusiness SfBServer WindowsUpdate

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
  Version 1.0: 2017/11/23 - Initial release.
  Version 1.1: 2023/10/07 - Updated to publish in PowerShell Gallery.

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Script to add the KB2982006 when we cannot install it. 

#> 

[CmdletBinding()]
param(
    [string]$MsuFile,
    [string]$CabFile
)

function CheckKB($KB){
    try {
        Get-Hotfix $KB -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

$KB = "KB2982006"
$url = "http://hotfixv4.microsoft.com/Windows%208.1/Windows%20Server%202012%20R2/sp1/Fix514814/9600/free/478232_intl_x64_zip.exe"
$tmpPath = [System.IO.Path]::Combine($pwd.Path,$KB)
$zipFile = [System.IO.Path]::Combine($tmpPath,"78232_intl_x64_zip.exe")

#Check if KB2982006 is already installed.
if(!(CheckKB $KB)){
    Write-Host "KB2982006 is missing!" -ForegroundColor Yellow
    if([string]::IsNullOrEmpty($CabFile)) {
        $CabFile = [System.IO.Path]::Combine($tmpPath,"Windows8.1-KB2982006-x64.cab")
    }
    #Check if we already have the cab file.
    if (Test-Path $CabFile) {
        $skipExpand = $true
    } else {
        $skipExpand = $false
    }
    if(!$skipExpand) {
        if([string]::IsNullOrEmpty($MsuFile)) {
            $MsuFile = [System.IO.Path]::Combine($tmpPath,"Windows8.1-KB2982006-x64.msu")
        }
        if (Test-Path $MsuFile) {
            $skipDownload = $true
            $skipExpand = $false
        } else {
            $skipDownload = $false
            $skipExpand = $false
        }
        #Checking if the Temp Folder already exists
        if (!(Test-Path $tmpPath -PathType Container) -and (!$skipDownload -or !$skipExpand)) {
            New-Item -ItemType Directory -Force -Path $tmpPath | Out-Null
        }
        #Check if we already have the KB2982006 zip file
        if(!(Test-Path $zipFile) -and !$skipDownload){
            try {
                Write-Host "Downloading file..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $url -OutFile $zipFile -ErrorAction Stop
            } catch {
                Write-Host "An error occurred while downloading KB2982006." -ForegroundColor Red
                exit
            }
        }
        #Check if we already have the .msu file
        if (!(Test-Path $MsuFile) -and !$skipDownload){
            Write-Host "Extracting 78232_intl_x64_zip.exe file..." -ForegroundColor Cyan
            Add-Type -assembly "system.io.compression.filesystem"
            [io.compression.zipfile]::ExtractToDirectory($zipFile, $tmpPath)
        }
        #Expand the KB2982006 .msu file if we dont have the .cab
        if (!(Test-Path $CabFile) -and !$skipExpand){
            Write-Host "Extracting Windows8.1-KB2982006-x64.msu file..." -ForegroundColor Cyan
            &Expand -F:* $msuFile  $tmpPath | Out-Null
        }
    }
    try {
        Write-Host "Adding the KB2982006..." -ForegroundColor Cyan
        Add-WindowsPackage -Online -PackagePath $cabFile -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "An error occurred while adding KB2982006." -ForegroundColor Red
        exit
    }
    if(CheckKB $KB){
        Write-Host "Sucessfully added KB2982006, please return to the SfB Deployment Wizard and run Step 2." -ForegroundColor Green
    } else {
       Write-Host "KB2982006 wasn't added." -ForegroundColor Yellow
    }
} else {
    Write-Host "KB2982006 is already installed." -ForegroundColor Green
}