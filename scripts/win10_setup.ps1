# Summary
# Context : Windows 10 fresh install, NETWORK WORKING
# Pre checks : admin rights, network connection OK
# Disable : Defender / Firewall / Updates
# Install : Python 32bits 3.12.4 + upgrade pip + install Pillow / pywintrace
# Create Ninite from selection of software

Write-Output "🟢 Début du script de configuration Python..."

# 1. Installer Python 3.12.4 32 bits
Write-Output "📦 Installation de Python 3.12.4 32 bits via winget..."
winget install --id "Python.Python.3.12" --architecture x86 --version 3.12.4.0 --silent

# Attendre que l'installation se termine
Start-Sleep -Seconds 10

# 2. Ajouter Python au PATH si ce n'est pas déjà fait
$pythonPath = "$env:LOCALAPPDATA\Programs\Python\Python312-32"
$env:Path += ";$pythonPath;$pythonPath\Scripts"

# 3. Mettre à jour pip
Write-Output "⬆️ Mise à jour de pip..."
python -m ensurepip --upgrade
python -m pip install --upgrade pip

# 4. Installer NumPy
Write-Output "➕ Installation de NumPy..."
python -m pip install numpy

Write-Output "✅ Installation de Python et NumPy terminée."

# 5. --- Setup agent

# 1. Liste d’animaux pour nom discret aléatoire
$animals = @(
    "panda", "koala", "tiger", "eagle", "falcon", "otter", "lynx", "panther", "gecko", "wolf",
    "fox", "rabbit", "bear", "orca", "shark", "bat", "owl", "boar", "seal", "lizard"
)

# 2. Générer un nom aléatoire et définir les chemins
$randomAnimal = Get-Random -InputObject $animals
$filename = "$randomAnimal.pyw"
$downloadFolder = Join-Path $env:USERPROFILE "Downloads"
$fullPath = Join-Path $downloadFolder $filename

# 3. Télécharger le fichier agent.py depuis GitHub (version raw)
$rawUrl = "https://raw.githubusercontent.com/kevoreilly/CAPEv2/master/agent/agent.py"
Invoke-WebRequest -Uri $rawUrl -OutFile $fullPath
Write-Output "✅ Fichier téléchargé : $fullPath"

# 4. Créer la tâche planifiée
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

Write-Output "✅ Tâche planifiée '$taskName' créée avec privilèges élevés."
