# Summary
# Context : Windows 10 fresh install, NETWORK WORKING
# Pre checks : admin rights, network connection OK
# Disable : Defender / Firewall / Updates
# Install : Python 32bits 3.12.4 + upgrade pip + install Pillow / pywintrace
# Create Ninite from selection of software

# Prerequis :
# Permissions admin (a tes)
# Acces internet (a tester)
# Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force


Write-Output "Debut du script de configuration Python..."

# 1. Installer Python 3.12.4 32 bits
Write-Output "Installation de Python 3.12.4 32 bits via winget..."
winget install --id "Python.Python.3.12" --architecture x86 --version 3.12.4.0 --silent

# Attendre que l'installation se termine
Start-Sleep -Seconds 10

# 2. Ajouter Python au PATH si ce n'est pas deja fait
$pythonPath = "$env:LOCALAPPDATA\Programs\Python\Python312-32"
$env:Path += ";$pythonPath;$pythonPath\Scripts"

# 3. Mettre a jour pip
Write-Output "⬆Mise a jour de pip..."
python -m ensurepip --upgrade
python -m pip install --upgrade pip

# 4. Installer Pillow
Write-Output "Installation de Pillow..."
python -m pip install Pillow==9.5.0

Write-Output "Installation de Python et Pillow terminee."

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
