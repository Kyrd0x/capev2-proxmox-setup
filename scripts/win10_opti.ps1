# ====================== PERFORMANCE & UX OPTIMIZATION (ALL USERS, NO MANUAL STEPS) ======================
Write-Output "Optimizing performance and UX (applying to all profiles)..."

# --- Helpers ---
function Set-RegistryValueForAllUsers {
    <#
        .SYNOPSIS
            Create/modify an HKCU value for ALL existing users (even if their hives are not loaded) + .DEFAULT (for new profiles).
        .PARAMETER SubPath
            Path relative to HKCU (e.g., 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize')
        .PARAMETER Name
            Value name
        .PARAMETER Type
            Value type (DWord, String, QWord, Binary, MultiString, ExpandString)
        .PARAMETER Value
            Data
    #>
    param(
        [Parameter(Mandatory=$true)][string]$SubPath,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)]
        [ValidateSet('DWord','String','QWord','Binary','MultiString','ExpandString')]
        [string]$Type,
        [Parameter(Mandatory=$true)]$Value
    )

    # 1) New users (.DEFAULT)
    try {
        $defaultPath = "Registry::HKEY_USERS\.DEFAULT\$SubPath"
        if (!(Test-Path $defaultPath)) { New-Item -Path $defaultPath -Force | Out-Null }
        New-ItemProperty -Path $defaultPath -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
    } catch { Write-Host "DEFAULT hive update failed: $($_.Exception.Message)" -ForegroundColor Yellow }

    # 2) Existing users
    $profileKeys = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' |
                   Where-Object { $_.PSChildName -notlike '*_Classes' }

    foreach ($pk in $profileKeys) {
        $sid = $pk.PSChildName
        $hkuLoaded = "Registry::HKEY_USERS\$sid"
        $targetRoot = $hkuLoaded
        $tempHive = $null

        # Skip system/service accounts
        if ($sid -in @('S-1-5-18','S-1-5-19','S-1-5-20')) { continue }

        if (!(Test-Path $hkuLoaded)) {
            $profilePath = (Get-ItemProperty -Path $pk.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
            if (-not $profilePath) { continue }
            $ntuser = Join-Path $profilePath 'NTUSER.DAT'
            if (!(Test-Path $ntuser)) { continue }

            # Load the not-currently-loaded user hive under a temporary name
            $tempHive = "HKU\TEMP_$($sid -replace '[^A-Za-z0-9_]','_')"
            try {
                & reg.exe load $tempHive $ntuser | Out-Null 2>$null
                $targetRoot = "Registry::$tempHive"
            } catch { continue }
        }

        try {
            $fullPath = Join-Path $targetRoot $SubPath
            if (!(Test-Path $fullPath)) { New-Item -Path $fullPath -Force | Out-Null }
            New-ItemProperty -Path $fullPath -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
        } finally {
            if ($tempHive) { & reg.exe unload $tempHive | Out-Null 2>$null }
        }
    }
}

# 0) Power plan -> Ultimate/High performance + no sleep + no hibernation
try {
    $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

    if (-not ((powercfg -list) -match $ultimateGuid)) { try { powercfg -duplicatescheme $ultimateGuid | Out-Null } catch {} }
    if ((powercfg -list) -match $ultimateGuid) { powercfg -setactive $ultimateGuid } else { powercfg -setactive $highPerfGuid }

    powercfg -change -monitor-timeout-ac 0
    powercfg -change -standby-timeout-ac 0
    powercfg -hibernate off
    Write-Host "Power plan configured." -ForegroundColor Green
} catch { Write-Host "Power plan configuration failed: $($_.Exception.Message)" -ForegroundColor Red }

# 1) Disable transparency/blur (UI + logon screen)
try {
    # All users (HKCU)
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Type DWord -Value 0
    # Logon (HKLM)
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableAcrylicBackgroundOnLogon" -PropertyType DWord -Value 1 -Force | Out-Null
    Write-Host "Transparency/blur disabled." -ForegroundColor Green
} catch { Write-Host "Disabling transparency failed: $($_.Exception.Message)" -ForegroundColor Red }

# 2) Visual effects -> Best performance + disable common animations
try {
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Type DWord -Value 2   # 2 = Best performance

    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations'  -Type DWord -Value 0
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect' -Type DWord -Value 0
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow'     -Type DWord -Value 0

    # String values (REG_SZ) under Desktop
    Set-RegistryValueForAllUsers -SubPath 'Control Panel\Desktop' -Name 'DragFullWindows' -Type String -Value '0'
    Set-RegistryValueForAllUsers -SubPath 'Control Panel\Desktop' -Name 'CursorShadow'   -Type String -Value '0'
    Set-RegistryValueForAllUsers -SubPath 'Control Panel\Desktop' -Name 'MinAnimate'     -Type String -Value '0'
    Set-RegistryValueForAllUsers -SubPath 'Control Panel\Desktop' -Name 'MenuShowDelay'  -Type String -Value '0'

    # Disable first-logon animation
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableFirstLogonAnimation' -PropertyType DWord -Value 0 -Force | Out-Null

    Write-Host "Visual effects optimized." -ForegroundColor Green
} catch { Write-Host "Visual effects configuration failed: $($_.Exception.Message)" -ForegroundColor Red }

# 3) Block UWP apps from running in background (machine policy)
try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -PropertyType DWord -Value 2 -Force | Out-Null  # 2 = Force deny
    Write-Host "UWP background apps disabled (policy)." -ForegroundColor Green
} catch { Write-Host "Disabling UWP background apps failed: $($_.Exception.Message)" -ForegroundColor Red }

# 4) Disable VM-lab heavy services: SysMain & Indexing (WSearch)
try {
    foreach ($svc in @('SysMain','WSearch')) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled
        }
    }
    Write-Host "Services SysMain/WSearch disabled." -ForegroundColor Yellow
} catch { Write-Host "Disabling services failed: $($_.Exception.Message)" -ForegroundColor Red }

# 5) Turn off Game Bar / Game DVR (useless in VMs)
try {
    # Machine policy
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -PropertyType DWord -Value 0 -Force | Out-Null
    # Per-user (apply to all profiles)
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\GameBar'     -Name 'ShowStartupPanel'    -Type DWord -Value 0
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\GameBar'     -Name 'AutoGameModeEnabled' -Type DWord -Value 0
    Set-RegistryValueForAllUsers -SubPath 'System\GameConfigStore'                 -Name 'GameDVR_Enabled'     -Type DWord -Value 0
    Write-Host "Game Bar / Game DVR disabled." -ForegroundColor Green
} catch { Write-Host "Disabling Game Bar/Game DVR failed: $($_.Exception.Message)" -ForegroundColor Red }

# 6) Reduce Windows suggestions/content surfaces (all profiles)
try {
    Set-RegistryValueForAllUsers -SubPath 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Type DWord -Value 0
    Write-Host "Windows suggestions reduced." -ForegroundColor Green
} catch { Write-Host "Suggestions configuration failed: $($_.Exception.Message)" -ForegroundColor Red }

Write-Output "Performance optimizations applied to all profiles. The final reboot will activate 100% of the changes."
# ===================================================================
