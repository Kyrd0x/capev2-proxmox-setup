# ====================================
# 🎯 Realistic User Profile Simulator
# ====================================

# -----------------------------
# 🔧 Utility: Ensure directory exists
function Ensure-Folder {
    param ($Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

# -----------------------------
# ✍️ Generate random realistic sentence from API
function Get-RandomSentence {
    try {
        $response = Invoke-RestMethod "https://sentences.drycodes.com/1?separator=."
        return ($response -join ".") + "."
    } catch {
        return "This is a placeholder sentence due to API failure."
    }
}

# -----------------------------
# 📝 Create text and Word files
function Create-TextFile {
    param ($Path, $Lines = 10)
    $content = @()
    for ($i = 0; $i -lt $Lines; $i++) {
        $content += Get-RandomSentence
    }
    $content | Set-Content -Path $Path
}

# function Create-WordFile {
#     param ($Path, $Paragraphs = 3)
#     $word = New-Object -ComObject Word.Application
#     $word.Visible = $false
#     $doc = $word.Documents.Add()
#     for ($i = 0; $i -lt $Paragraphs; $i++) {
#         $para = $doc.Paragraphs.Add()
#         $text = ""
#         for ($j = 0; $j -lt (Get-Random -Minimum 2 -Maximum 5); $j++) {
#             $text += Get-RandomSentence + " "
#         }
#         $para.Range.Text = $text.Trim()
#     }
#     $doc.SaveAs([ref]$Path)
#     $doc.Close()
#     $word.Quit()
# }

# -----------------------------
# 🖼️ Download random images
function Download-RandomImages {
    param ($TargetFolder, $Count = 6)
    for ($i = 0; $i -lt $Count; $i++) {
        $url = "https://picsum.photos/800/600?random=$(Get-Random)"
        $file = Join-Path $TargetFolder "photo_$i.jpg"
        Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
    }
}

# -----------------------------
# 🖼️ Set desktop wallpaper
function Set-RandomWallpaper {
    param ($TargetFolder)
    $wallpaper = Join-Path $TargetFolder "wallpaper.jpg"
    Invoke-WebRequest -Uri "https://picsum.photos/1920/1080" -OutFile $wallpaper -UseBasicParsing
    Add-Type @"
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
    [Wallpaper]::SystemParametersInfo(20, 0, $wallpaper, 3)
}

# -----------------------------
# 📁 Generate documents with projects
function Generate-Documents {
    param ($BasePath)
    $projects = "ProjectA", "ProjectB", "Reports", "HR"
    foreach ($proj in $projects) {
        $folder = Join-Path $BasePath $proj
        Ensure-Folder $folder
        # Create-WordFile "$folder\report_$(Get-Random -Minimum 100 -Maximum 999).docx"
        Create-TextFile "$folder\notes_$(Get-Random -Minimum 1000 -Maximum 9999).txt"
    }
    Create-TextFile "$BasePath\midnight_$(Get-Random -Minimum 1000 -Maximum 9999).txt"
    Create-TextFile "$BasePath\test_$(Get-Random -Minimum 1000 -Maximum 9999).txt"
    Create-TextFile "$BasePath\temp_$(Get-Random -Minimum 1000 -Maximum 9999).txt"
}

# -----------------------------
# 📥 Downloads
function Create-Downloads {
    param ($DownloadPath)
    $pdf = "$DownloadPath\manual_$(Get-Random -Minimum 100 -Maximum 999).pdf"
    Invoke-WebRequest -Uri "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" -OutFile $pdf
    Compress-Archive -Path $pdf -DestinationPath "$DownloadPath\archive_$(Get-Random -Minimum 1000 -Maximum 9999).zip" -Force
}

# -----------------------------
# 🗑️ Simulate Recycle Bin
function Simulate-Trash {
    param ($TrashPath)
    Ensure-Folder $TrashPath
    Create-TextFile "$TrashPath\deleted_file.txt" -Lines 6
}

# -----------------------------
# 🕘 Create Recent Shortcuts
function Simulate-RecentFiles {
    param ($DocsPath, $RecentPath)
    $shell = New-Object -ComObject WScript.Shell
    $files = Get-ChildItem -Path $DocsPath -Recurse -Filter *.docx
    if ($files.Count -ne 0) { 
        $selected = $files | Get-Random -Count ([Math]::Min(3, $files.Count))
        foreach ($file in $selected) {
            $lnk = $shell.CreateShortcut("$RecentPath\$($file.BaseName).lnk")
            $lnk.TargetPath = $file.FullName
            $lnk.Save()
        }
    } else {
        Write-Host "No documents found in $DocsPath to simulate recent files."
    }
}

# -----------------------------
# 🌐 Simulate browser logs (manually visited)
function Simulate-BrowserData {
    param ($BrowserPath)
    Ensure-Folder $BrowserPath
    $sites = @("reddit.com", "github.com", "amazon.com", "wikipedia.org", "nytimes.com")
    $history = @()
    $cookies = @()
    foreach ($site in $sites) {
        $time = (Get-Date).AddDays(- (Get-Random -Minimum 1 -Maximum 30)).ToString("yyyy-MM-dd HH:mm:ss")
        $history += "$time`tVisited $site"
        $cookies += "$site`tSESSION_ID=token_$(Get-Random -Minimum 10000 -Maximum 99999)"
    }
    $history | Set-Content "$BrowserPath\History.txt"
    $cookies | Set-Content "$BrowserPath\Cookies.txt"
}

# -----------------------------
# 🚀 Main
# -----------------------------
function Run-Simulation {
    $user = $env:USERPROFILE
    $paths = @{
        Desktop = "$user\Desktop"
        Documents = "$user\Documents"
        Pictures = "$user\Pictures"
        Downloads = "$user\Downloads"
        Trash = "$env:SystemDrive\Recycle\Simulated"
        Recent = "$user\AppData\Roaming\Microsoft\Windows\Recent"
        Browser = "$user\AppData\Local\SimulatedBrowser"
    }

    # Ensure folders
    foreach ($p in $paths.Values) { Ensure-Folder $p }

    Write-Host "Creating user content..."

    Generate-Documents $paths.Documents
    Download-RandomImages $paths.Pictures
    Download-RandomImages $paths.Desktop
    Generate-Documents $paths.Desktop
    Set-RandomWallpaper $paths.Pictures
    Create-Downloads $paths.Downloads
    Simulate-Trash $paths.Trash
    Simulate-RecentFiles $paths.Documents $paths.Recent
    Simulate-BrowserData $paths.Browser

    Write-Host "Done! Realistic user environment populated."
}

Run-Simulation
