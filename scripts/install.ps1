# -------------------------------
# Cursor Free VIP Installer
# -------------------------------

# Set color theme
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# ASCII Logo
$Logo = @"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗   
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗  
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝     ██████╔╝██████╔╝██║   ██║  
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║   ██║  
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║     ██║     ██║  ██║╚██████╔╝  
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝  
"@

# -------------------------------
# Styled Write Function
# -------------------------------
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = "",
        [switch]$NoNewline
    )
    $symbol = switch ($Color) {
        $Theme.Success { "[OK]" }
        $Theme.Error   { "[X]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }

    $output = if ($Prefix) { "$symbol $Prefix :: $Message" } else { "$symbol $Message" }
    if ($NoNewline) {
        Write-Host $output -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $output -ForegroundColor $Color
    }
}

# -------------------------------
# Show Logo
# -------------------------------
Write-Host $Logo -ForegroundColor $Theme.Primary
Write-Host "Created by YeongPin`n" -ForegroundColor $Theme.Info

# -------------------------------
# Set TLS 1.2 for HTTPS
# -------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -------------------------------
# Main Installation Function
# -------------------------------
function Install-CursorFreeVIP {

    $RepoOwner = "m-ather-47"
    $RepoName  = "cursor-free-vip"
    $Branch    = "main"  # use main branch instead of releases/latest

    # Base URL for raw files
    $BaseRaw = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/resources"

    # Files to download
    $Files = @(
        "CursorFreeVIP.exe",
        "config.ini"
    )

    # Download location
    $DownloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
    $InstallDir = $DownloadsPath
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

    foreach ($file in $Files) {
        $url = "$BaseRaw/$file"
        $dest = Join-Path $InstallDir $file

        if (Test-Path $dest) {
            Write-Styled "Found existing file: $file" -Color $Theme.Success -Prefix "Found"
        } else {
            Write-Styled "Downloading $file..." -Color $Theme.Primary -Prefix "Download"

            # Simple progress
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "PowerShell Script")
            $wc.DownloadProgressChanged += {
                Write-Host "`rDownloading $file: $($_.ProgressPercentage)% ($([math]::Round($_.BytesReceived/1MB,2)) MB / $([math]::Round($_.TotalBytesToReceive/1MB,2)) MB)" -NoNewline -ForegroundColor Cyan
            }
            $wc.DownloadFile($url, $dest)
            Write-Host "`r"
            Write-Styled "$file downloaded successfully" -Color $Theme.Success -Prefix "Complete"
        }
    }

    # Check for admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $exePath = Join-Path $InstallDir "CursorFreeVIP_windows.exe"

    if (-not $isAdmin) {
        Write-Styled "Requesting administrator privileges..." -Color $Theme.Warning -Prefix "Admin"
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $exePath
        $startInfo.UseShellExecute = $true
        $startInfo.Verb = "runas"

        try {
            [System.Diagnostics.Process]::Start($startInfo)
            Write-Styled "Program started with admin privileges" -Color $Theme.Success -Prefix "Launch"
            return
        } catch {
            Write-Styled "Failed to start as admin, starting normally..." -Color $Theme.Warning -Prefix "Warning"
            Start-Process $exePath
        }
    } else {
        Start-Process $exePath
    }
}

# -------------------------------
# Execute Installation
# -------------------------------
try {
    Install-CursorFreeVIP
} catch {
    Write-Styled "Installation failed!" -Color $Theme.Error -Prefix "Error"
    Write-Styled $_.Exception.Message -Color $Theme.Error
} finally {
    Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
