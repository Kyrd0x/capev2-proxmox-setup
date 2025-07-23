# Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force

# todo :
# Admin perms to check
# Internet access to check
# enable machinery as argument, default kvm

# RDP
# Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0

# VMWare :
# https://web.archive.org/web/20200222145558/http://vknowledge.net/2014/04/17/how-to-fake-a-vms-guest-os-cpuid/
# Get-Service | Where-Object {$_.Name -like "*vmic*"} | Stop-Service -Force # to confirm
# Uncheck all VMware services in config
# check attached .vmx config file (4C/4T cpu imitation, etc.)

# Ensure running as admin
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run with elevated privileges."
    exit
}

# ================================ DISABLING PROTECTIONS ================================

Write-Output "Disabling protections..."

# Before
netsh interface teredo set state disabled

# 1. Turn off LLMNR (multicast name resolution) via registry
try {
    # Ensure the registry path exists
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force | Out-Null
    }
    
    # Set the registry value to disable LLMNR
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -Type DWord
    
    Write-Host "LLMNR disabled successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to disable LLMNR: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Enable "Restrict Internet communication"
try {
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "DisableInternetOpenWith" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "GroupPolicyRefreshTimeDC" -Value 0 -Type DWord
    
    Write-Host "Internet communication restrictions enabled successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to enable internet communication restrictions: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Disable Microsoft Defender Antivirus
try {
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord
    
    Write-Host "Microsoft Defender Antivirus disabled successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to disable Microsoft Defender Antivirus: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Disable Real-time Protection
try {
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
    
    Write-Host "Real-time Protection disabled successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to disable Real-time Protection: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Disable Microsoft Store via registry
try {
    # Create the registry path if it doesn't exist
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Force | Out-Null
    }
    
    # Disable the Microsoft Store
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "RemoveWindowsStore" -Value 1 -Type DWord
    
    Write-Host "Microsoft Store disabled successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to disable Microsoft Store: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable Defender real-time protection
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableScriptScanning $true
Set-MpPreference -DisableIntrusionPreventionSystem $true

# Disable Cloud-delivered protection
Set-MpPreference -MAPSReporting 0
Set-MpPreference -SubmitSamplesConsent 2

# Disable Automatic sample submission
Set-MpPreference -SubmitSamplesConsent 2

# Disable Ransomware protection (Controlled Folder Access)
Set-MpPreference -EnableControlledFolderAccess Disabled

# Disable Defender antivirus (legacy; might not fully disable on recent builds)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord

# Disable Firewall for all profiles (Domain, Private, Public)
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False

# ================================ SYSMON INSTALLATION ================================

Write-Output "Beginning Sysmon installation..."
# Set folders
$downloadFolder = Join-Path $env:USERPROFILE "Downloads"
$sysmonInstallPath = "C:\Program Files\Sysmon"

# URLs and filenames
$rawUrl_config_file = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$config_filename = "sysmonconfig-export.xml"
$rawUrl_sysmon = "https://download.sysinternals.com/files/Sysmon.zip"
$sysmon_filename = "Sysmon.zip"

# Paths
$config_fullPath = Join-Path $downloadFolder $config_filename
$sysmonZipPath = Join-Path $downloadFolder $sysmon_filename
$sysmonExtractPath = Join-Path $downloadFolder "SysmonExtracted"

# Download config
Invoke-WebRequest -Uri $rawUrl_config_file -OutFile $config_fullPath

# Download Sysmon zip
Invoke-WebRequest -Uri $rawUrl_sysmon -OutFile $sysmonZipPath

# Extract Sysmon
New-Item -ItemType Directory -Force -Path $sysmonExtractPath | Out-Null
Expand-Archive -Path $sysmonZipPath -DestinationPath $sysmonExtractPath -Force

# Create target folder in Program Files
New-Item -ItemType Directory -Force -Path $sysmonInstallPath | Out-Null

# Move Sysmon64.exe to Program Files
Copy-Item -Path (Join-Path $sysmonExtractPath "Sysmon64.exe") -Destination $sysmonInstallPath -Force

# Optionally copy the config file too (for reference or re-install)
Copy-Item -Path $config_fullPath -Destination $sysmonInstallPath -Force

# Install Sysmon service
$sysmonExe = Join-Path $sysmonInstallPath "Sysmon64.exe"
$configPath = Join-Path $sysmonInstallPath $config_filename
Start-Process -FilePath $sysmonExe -ArgumentList "-accepteula -i `"$configPath`"" -Verb RunAs -Wait

# Clean up downloaded files
Remove-Item -Path $config_fullPath, $sysmonZipPath, $sysmonExtractPath -Recurse -Force

# === WINGET INSTALLATION (if needed) ===

# Check if Nuget provider is installed
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Output "NuGet provider is not installed. Installing NuGet provider..."
    Install-PackageProvider -Name NuGet -Force
    Write-Output "NuGet provider has been successfully installed."
} else {
    Write-Output "NuGet provider is already installed. Skipping step."
}

# Check if winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "Winget is not installed. Installing via winget-install.ps1..."

    # https://github.com/asheroto/winget-install
    Install-Script winget-install -Force
    winget-install -Force

    Write-Output "Winget has been successfully installed via external script."
} else {
    Write-Output "Winget is already installed. Skipping step."
}

# =============================== PYTHON & AGENT INSTALLATION ================================

Write-Output "Starting Python configuration script..."

# Install Python 3.12.4 32-bit via winget
Write-Output "Installing Python 3.12.4 32-bit via winget..."
winget install --id Python.Python.3.12 --architecture x86 --version 3.12.4 --scope machine --silent

# Wait for install to finish
Start-Sleep -Seconds 10

# Define Python installation paths
$pythonPath = "C:\Program Files (x86)\Python312-32"

# Verify that Python is installed
$pythonExe = Join-Path $pythonPath "python.exe"
if (Test-Path $pythonExe) {
    Write-Output "Python was installed successfully."

    # Add Python to PATH for current session
    Write-Output "Paths added to PATH for this session: $pythonPath"
    
    # 3. Update pip
    Write-Output "Updating pip..."
    & $pythonExe -m ensurepip --upgrade
    & $pythonExe -m pip install --upgrade pip
    
    # 4. Install modules
    Write-Output "Installing Pillow & pywintrace & pywin32 ..."
    & $pythonExe -m pip install Pillow==9.5.0
    & $pythonExe -m pip install pywintrace
    & $pythonExe -m pip install pywin32
} else {
    Write-Error "Python installation failed or path is incorrect."
    Write-Error "Skipping modules install."
}

# 5. --- Setup agent

#  5.1. List of animals for discrete random name
$animals = @(
    "panda", "koala", "tiger", "eagle", "falcon", "otter", "lynx", "panther", "gecko", "wolf",
    "fox", "rabbit", "bear", "orca", "shark", "bat", "owl", "boar", "seal", "lizard"
)

# 5.2. Generate a random animal name and create a filename
$randomAnimal = Get-Random -InputObject $animals
$filename = "$randomAnimal.pyw"
$downloadFolder = Join-Path $env:USERPROFILE "Downloads"
$fullPath = Join-Path $downloadFolder $filename

# 5.3. Download agent.py file from GitHub (raw version)
$rawUrl = "https://raw.githubusercontent.com/kevoreilly/CAPEv2/master/agent/agent.py"
Invoke-WebRequest -Uri $rawUrl -OutFile $fullPath
Write-Output "File downloaded: $fullPath"

# 5.4. Create scheduled task
$taskName = "Updater_" + $randomAnimal  # nom discret
$action = New-ScheduledTaskAction -Execute "pythonw.exe" -Argument "`"$fullPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Force

Write-Output "Scheduled task '$taskName' created with elevated privileges."

# Clean files todo

# ----- VM MASKING -----

Write-Output "Starting VM service deactivation..."
Get-Service | Where-Object {$_.Name -like "*vmic*"} | Stop-Service -Force # to confirm

# ----- ENABLING RDP -----

# Write-Output "Enabling RDP..."

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'LimitBlankPasswordUse' -Value 0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LimitBlankPasswordUse' -Value 0

# ---- SETUP SOFTWARE ----

# Install tools via Ninite
Write-Output "Starting tool installation via Ninite..."

# Tools to install via Ninite
$apps = @(
    # Browsers
    "brave",
    "chrome",
    "edge",
    "firefox",
    # Utilities
    "notepadplusplus",
    "filezilla",
    "7zip",
    "git",
    "putty",
    "vlc",
    "zoom",
    "teamviewer15",
    # .NET Runtimes
    ".net4.8.1",
    ".net8",
    ".net9",
    ".neta8",
    ".neta9",
    ".netx8",
    ".netx9",
    # Java Runtimes
    "adoptjava8",
    "adoptjavax11",
    "adoptjavax17",
    "adoptjavax21",
    "adoptjavax8",
    "adoptjdk8",
    "adoptjdkx11",
    "adoptjdkx17",
    "adoptjdkx21",
    "adoptjdkx8",
    "correttojdk8",
    "correttojdkx11",
    "correttojdkx17",
    "correttojdkx21",
    "correttojdkx8",
    # VC++ Redistributables
    "vcredist05",
    "vcredist08",
    "vcredist10",
    "vcredist12",
    "vcredist13",
    "vcredist15",
    "vcredistarm15",
    "vcredistx05",
    "vcredistx08",
    "vcredistx10",
    "vcredistx12",
    "vcredistx13",
    "vcredistx15"
)

# Génération de l'URL Ninite à partir de la liste
$baseUrl = "https://ninite.com/"
$appString = ($apps -join "-")
$niniteUrl = "$baseUrl$appString/ninite.exe"

# Téléchargement et exécution de l'installeur
$niniteInstaller = "$env:TEMP\ninite.exe"
Invoke-WebRequest -Uri $niniteUrl -OutFile $niniteInstaller
Start-Process -FilePath $niniteInstaller -Wait

# ---- INSTALLATION COMPLETE ----

Write-Output "Windows 10 configuration completed successfully."
Write-Output "Please restart your machine to apply the changes."
