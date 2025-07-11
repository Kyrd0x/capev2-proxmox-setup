# Prerequis :
# Permissions admin (a tester)
# Acces internet (a tester)
# Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force


# VMWare :
# https://web.archive.org/web/20200222145558/http://vknowledge.net/2014/04/17/how-to-fake-a-vms-guest-os-cpuid/
# Get-Service | Where-Object {$_.Name -like "*vmic*"} | Stop-Service -Force # to confirm
# Uncheck all VMware services in config
# check attached .vmx config file (4C/4T cpu imitation, etc.)

# Ensure running as admin
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit
}

# ================================ DISABLING PROTECTIONS ================================
Write-Output "Debut de la desactivation des protections..."

# Before
netsh interface teredo set state disabled
# gpedit todo

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
Write-Output "Debut de l'installation de Sysmon..."
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

# =============================== PYTHON & AGENT INSTALLATION ================================

Write-Output "Debut du script de configuration Python..."

# 1. Installer Python 3.12.4 32 bits
Write-Output "Installation de Python 3.12.4 32 bits via winget..."
winget install --id Python.Python.3.12 --architecture x86 --version 3.12.4 --scope machine --silent

# Attendre que l'installation se termine
Start-Sleep -Seconds 10

# Définir le chemin d'installation par défaut pour 32-bit installé pour tous les utilisateurs
$pythonPath = "C:\Program Files (x86)\Python312-32"

# Vérifier que Python est installé
$pythonExe = Join-Path $pythonPath "python.exe"
if (Test-Path $pythonExe) {
    Write-Output "Python a été installé avec succès."

    # Ajouter Python au PATH pour la session en cours
    $env:Path += ";$pythonPath;$pythonPath\Scripts"
    Write-Output "Chemins ajoutés au PATH pour cette session : $pythonPath"
} else {
    Write-Error "L'installation de Python a échoué ou le chemin est incorrect."
}

# 3. Mettre à jour pip
Write-Output "Mise à jour de pip..."
& $pythonExe -m ensurepip --upgrade
& $pythonExe -m pip install --upgrade pip

# 4. Installer Pillow
Write-Output "Installation de Pillow & pywintrace ..."
& $pythonExe -m pip install Pillow==9.5.0
& $pythonExe -m pip install pywintrace

Write-Output "Installation de Python et des modules terminee."

# 5. --- Setup agent

# 1. Liste d’animaux pour nom discret aleatoire
$animals = @(
    "panda", "koala", "tiger", "eagle", "falcon", "otter", "lynx", "panther", "gecko", "wolf",
    "fox", "rabbit", "bear", "orca", "shark", "bat", "owl", "boar", "seal", "lizard"
)

# 2. Generer un nom aleatoire et definir les chemins
$randomAnimal = Get-Random -InputObject $animals
$filename = "$randomAnimal.pyw"
$downloadFolder = Join-Path $env:USERPROFILE "Downloads"
$fullPath = Join-Path $downloadFolder $filename

# 3. Telecharger le fichier agent.py depuis GitHub (version raw)
$rawUrl = "https://raw.githubusercontent.com/kevoreilly/CAPEv2/master/agent/agent.py"
Invoke-WebRequest -Uri $rawUrl -OutFile $fullPath
Write-Output "Fichier telecharge : $fullPath"

# 4. Creer la tache planifiee
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

Write-Output "Tache planifiee '$taskName' creee avec privileges eleves."

# Clean files todo
