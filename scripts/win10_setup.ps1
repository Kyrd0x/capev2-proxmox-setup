# Summary
# Context : Windows 10 fresh install, NETWORK WORKING
# Pre checks : admin rights, network connection OK
# Disable : Defender / Firewall / Updates
# Install : Python 32bits 3.12.4 + upgrade pip + install Pillow / pywintrace
# Create Ninite from selection of software

# Prerequis :
# Permissions admin (a tester)
# Acces internet (a tester)
# Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force


# Prerequis :
# Permissions admin (a tester)
# Acces internet (a tester)
# Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force


# Before
netsh interface teredo set state disabled
# gpedit todo

# Sysmon
$rawUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$downloadFolder = Join-Path $env:USERPROFILE "Downloads"
$filename = "sysmonconfig-export.xml"
$fullPath = Join-Path $downloadFolder $filename
Invoke-WebRequest -Uri $rawUrl -OutFile $fullPath
Write-Output "Fichier de configuration Sysmon telecharge : $fullPath"
winget install --id Sysinternals.Sysmon --scope machine --silent
# Attendre que l'installation se termine
Start-Sleep -Seconds 5
# Configurer Sysmon avec le fichier de configuration telecharge
Write-Output "Configuration de Sysmon avec le fichier $fullPath..."
& "C:\Program Files\Sysinternals\Sysmon64.exe" -accepteula -i $fullPath


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
    -Description "Discreet task running $filename at logon" `
    -Force

Write-Output "Tache planifiee '$taskName' creee avec privileges eleves."

# Clean files todo
