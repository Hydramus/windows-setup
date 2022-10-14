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
    #@{name = "Microsoft.VisualStudioCode" }, 
    @{name = "Microsoft.WindowsTerminal"; source = "msstore" }, 
    #@{name = "Microsoft.AzureStorageExplorer" }, 
    @{name = "Microsoft.PowerToys" }, 
    @{name = "Git.Git" }, 
    #@{name = "Docker.DockerDesktop" },
    #@{name = "Microsoft.dotnet" },
    #@{name = "GitHub.cli" },
    @{name = "Adobe.Acrobat.Reader.64-bit"}, #Adobe Acrobat Reader DC
    @{name = "Python.Python.3.9"},
    @{name = "9WZDNCRFHWQT"; source = "msstore"}, # Drawboard PDF
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
    @{name = "7zip.7zip"},
    @{name = "qBittorrent.qBittorrent"},
    @{name = "TeamViewer.TeamViewer"}    

);
Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name 
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-host "Installing:" $app.name
        if ($app.source -ne $null) {
            winget install --exact --silent $app.name --source $app.source --accept-source-agreements
        }
        else {
            winget install --exact --silent $app.name --accept-source-agreements
        }
    }
    else {
        Write-host "Skipping Install of " $app.name
    }
}

#Remove Apps
Write-Output "Removing Apps"

$apps = "*3DPrint*", "Microsoft.MixedReality.Portal", "Microsoft.People", "*xboxapp*",`
"*3DPrint*", "Microsoft.SkypeApp", "Microsoft.Advertising*", "Microsoft.BingWeather", `
"Microsoft.ZuneVideo", "Microsoft.ZuneMusic", "Microsoft.Getstarted", "Microsoft.MicrosoftOfficeHub", `
"microsoft.windowscommunicationsapps", ""
Foreach ($app in $apps)
{
  Write-host "Uninstalling:" $app
  Get-AppxPackage -allusers $app | Remove-AppxPackage
}