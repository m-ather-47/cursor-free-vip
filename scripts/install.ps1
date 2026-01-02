# -------------------------------
# Cursor Free VIP Installer
# -------------------------------

$Theme = @{
    Primary = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'White'
}

$Logo = @"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
"@

function Write-Styled {
    param(
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

    $text = if ($Prefix) { "$symbol $Prefix :: $Message" } else { "$symbol $Message" }

    if ($NoNewline) {
        Write-Host $text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $text -ForegroundColor $Color
    }
}

Write-Host $Logo -ForegroundColor $Theme.Primary
Write-Host "Installer`n" -ForegroundColor $Theme.Info

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-CursorFreeVIP {
    $RepoOwner = "m-ather-47"
    $RepoName  = "cursor-free-vip"

    # 🔹 GitHub Releases (CORRECT)
    $BaseUrl = "https://github.com/$RepoOwner/$RepoName/releases/"

    $ExeName   = "CursorFreeVIP.exe"
    $ConfigIni = "config.ini"

    $InstallDir = "$env:USERPROFILE\Downloads"
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

    $Files = @($ExeName, $ConfigIni)

    foreach ($file in $Files) {
        $url  = "$BaseUrl/$file"
        $dest = Join-Path $InstallDir $file

        if (Test-Path $dest) {
            Write-Styled "Found $file" -Color $Theme.Success -Prefix "Found"
            continue
        }

        Write-Styled "Downloading $file..." -Color $Theme.Primary -Prefix "Download"

        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "PowerShell")

        $wc.DownloadProgressChanged += {
            Write-Host (
                "`rDownloading ${file}: {0}% ({1} MB / {2} MB)" -f
                $_.ProgressPercentage,
                [math]::Round($_.BytesReceived / 1MB, 2),
                [math]::Round($_.TotalBytesToReceive / 1MB, 2)
            ) -NoNewline -ForegroundColor Cyan
        }

        $completed = $false
        $wc.DownloadFileCompleted += { $script:completed = $true }

        $wc.DownloadFileAsync($url, $dest)

        while (-not $completed) {
            Start-Sleep -Milliseconds 100
        }

        Write-Host ""
        Write-Styled "$file downloaded" -Color $Theme.Success -Prefix "Complete"
    }

    $exePath = Join-Path $InstallDir $ExeName

    if (-not (Test-Path $exePath)) {
        throw "Executable not found after download"
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Styled "Requesting admin privileges..." -Color $Theme.Warning -Prefix "Admin"
        Start-Process $exePath -Verb RunAs
    } else {
        Start-Process $exePath
    }
}

try {
    Install-CursorFreeVIP
} catch {
    Write-Styled "Installation failed!" -Color $Theme.Error -Prefix "Error"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}

Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
