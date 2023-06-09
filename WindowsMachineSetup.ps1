<#
    Author: Hydramus
    Script Name: WindowsMachineSetup.ps1
    Version: 1.1
    Description: This script installs and configures Windows Package Manager (winget), then installs a list of applications and removes another list of apps.
    Usage: Run this script using Windows PowerShell. To see the help, execute: Get-Help <path_to_script> -Detailed
#>

param (
    [switch]$help
)

if ($help) {
    Write-Host "This script automates the installation and configuration of Windows Package Manager (winget)."
    Write-Host "It ensures that winget is installed and then configures it by enabling experimental features."
    Write-Host "The script also installs a pre-defined list of applications and removes others."
    Write-Host "No parameters are required to run this script."
    Write-Host "Example usage: .\WinGet-Installation-Configuration.ps1"
    exit
}

# Ensure the script is running with administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator."
    Start-Sleep -Seconds 10
    Exit
}

# Set the execution policy to allow running scripts
Set-ExecutionPolicy Bypass -Scope Process -Force

#Install WinGet
#Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
else {
    "winget already installed"
}

#Configure WinGet
Write-Output "Configuring winget"

#winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
$settingsJson = 
@"
    {
        // For documentation on these settings, see: https://aka.ms/winget-settings
        "experimentalFeatures": {
          "experimentalMSStore": true,
        }
    }
"@;
$settingsJson | Out-File $settingsPath -Encoding utf8

#Install New apps
Write-Output "Installing Apps"
$apps = @(
    #@{name = "Microsoft.AzureCLI" }, 
    @{name = "Microsoft.PowerShell" }, 
    @{name = "Microsoft.VisualStudioCode" }, 
    @{name = "Microsoft.WindowsTerminal"; source = "msstore" }, 
    #@{name = "Microsoft.AzureStorageExplorer" }, 
    @{name = "Microsoft.PowerToys" }, 
    @{name = "Git.Git" }, 
    @{name = "Docker.DockerDesktop" },
    @{name = "Microsoft.dotnet" },
    @{name = "GitHub.cli" },
    @{name = "Adobe.Acrobat.Reader.64-bit"}, #Adobe Acrobat Reader DC
    @{name = "Python.Python.3.9"},
    #@{name = "9WZDNCRFHWQT"; source = "msstore"}, # Drawboard PDF
    @{name = "Google.Chrome"},
    @{name = "Zoom.Zoom"},
    @{name = "Zoom.Zoom.OutlookPlugin"},
    @{name = "Tencent.WeChat"},
    @{name = "Tencent.VooVMeeting"},
    @{name = "Dropbox.Dropbox"},
    @{name = "9PMMSR1CGPWG"; source = "msstore" },        # HEIF-PictureExtension
    @{name = "9MVZQVXJBQ9V"; source = "msstore" },        # AV1 VideoExtension
    @{name = "9NCTDW2W1BH8"; source = "msstore" },        # Raw-PictureExtension
    @{name = "9N95Q1ZZPMH4"; source = "msstore" },        # MPEG-2-VideoExtension
    @{name = "9N4WGH0Z6VHQ"; source = "msstore" },        # HEVC-VideoExtension
    @{name = "9NLXL1B6J7LW"; source = "msstore" },        # SafeInCloud password management
    @{name = "7zip.7zip"},
    @{name = "qBittorrent.qBittorrent"},
    @{name = "TeamViewer.TeamViewer"},    
    @{name = "Notepad++.Notepad++"}
);
Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name 
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-Host "Attempting to install:" $app.name -ForegroundColor Cyan
        if ($app.source -ne $null) {
            $installStatus = winget install --exact --silent $app.name --source $app.source --accept-source-agreements --accept-package-agreements
        }
        else {
            $installStatus = winget install --exact --silent $app.name --accept-source-agreements --accept-package-agreements
        }
        
        # Check if the installation was successful
        if ($installStatus -like '*successfully*') {
            Write-Host "Successfully installed:" $app.name -ForegroundColor Green
        } else {
            Write-Host "Failed to install:" $app.name -ForegroundColor Red
        }

    } else {
        Write-Host "Skipping installation of" $app.name -ForegroundColor Yellow
    }
}


#Remove Apps
Write-Output "Removing Apps"

$apps = @(
        # These apps will be uninstalled by default:
        #
        # If you wish to KEEP any of the apps below simply add a # character
        # in front of the specific app in the list below.
        "*3DPrint*"
        "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
        "*Clipchamp.Clipchamp*"
        "*Dolby*"
        "*Duolingo-LearnLanguagesforFree*"
        "*Facebook*"
        "*Flipboard*"
        "*HULULLC.HULUPLUS*"
        "*Microsoft.3DBuilder*"
        "*Microsoft.549981C3F5F10*"   #Cortana app
        "*Microsoft.Asphalt8Airborne*"
        "*Microsoft.BingFinance*"
        "*Microsoft.BingNews*"
        "*Microsoft.BingSports*"
        "*Microsoft.BingTranslator*"
        "*Microsoft.BingWeather*"
        "*Microsoft.GetHelp*"
        "*Microsoft.Getstarted*"   # Cannot be uninstalled in Windows 11
        "*Microsoft.Messaging*"
        "*Microsoft.Microsoft3DViewer*"
        "*Microsoft.MicrosoftOfficeHub*"
        "*Microsoft.MicrosoftSolitaireCollection*"
        "*Microsoft.MicrosoftStickyNotes*"
        "*Microsoft.MixedReality.Portal*"
        "*Microsoft.NetworkSpeedTest*"
        "*Microsoft.News*"
        "*Microsoft.Office.OneNote*"
        "*Microsoft.Office.Sway*"
        "*Microsoft.OneConnect*"
        "*Microsoft.Print3D*"
        "*Microsoft.RemoteDesktop*"
        "*Microsoft.SkypeApp*"
        "*Microsoft.Todos*"
        "*Microsoft.WindowsAlarms*"
        "*Microsoft.WindowsFeedbackHub*"
        "*Microsoft.WindowsMaps*"
        "*Microsoft.WindowsSoundRecorder*"
        "*Microsoft.ZuneMusic*"
        "*Microsoft.ZuneVideo*"
        "*PandoraMediaInc*"
        "*PICSART-PHOTOSTUDIO*"
        "*Royal Revolt*"
        "*Speed Test*"
        "*Spotify*"
        "*Twitter*"
        "*Wunderlist*"
        "*king.com.BubbleWitch3Saga*"
        "*king.com.CandyCrushSaga*"
        "*king.com.CandyCrushSodaSaga*"
        "*Microsoft.GamingApp*"
        "*Microsoft.XboxGameOverlay*"
        "*Microsoft.XboxGamingOverlay*"
        "*Microsoft.XboxIdentityProvider*"
        "*Microsoft.XboxSpeechToTextOverlay*"

)
        
Foreach ($app in $apps)
{
  Write-host "Uninstalling:" $app
  Get-AppxPackage -allusers $app | Remove-AppxPackage
  Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $app } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
}