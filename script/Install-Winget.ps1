#=========================================================================
# Windows Package Manager (winget) simple installer
# Version: 1.0.5
#
# Author: EXLOUD
# >> https://github.com/EXLOUD <<
#=========================================================================

#========= Define the offline files directory =========
# $ErrorActionPreference = "Stop"
$filesDir = Join-Path $PSScriptRoot "Files"

#========= Checking system and preparing installation =========
Write-Host "`n[INFO] Checking system and preparing installation..." -ForegroundColor Yellow

#========= Function to download winget files =========
function Download-WingetFiles {
    param(
        [string]$FilesDirectory
    )
    
    if (-not (Test-Path $FilesDirectory)) {
        Write-Host "`n[INFO] Creating files directory..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $FilesDirectory -Force | Out-Null
        Write-Host "[SUCCESS] Files directory created: $FilesDirectory" -ForegroundColor Green
    } else {
        Write-Host "`n[INFO] Files directory already exists: $FilesDirectory" -ForegroundColor Cyan
    }
    
    $wingetPath = Join-Path $FilesDirectory "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $licensePath = Join-Path $FilesDirectory "e53e159d00e04f729cc2180cffd1c02e_License1.xml"
    
    # Check if winget bundle already exists
    if (Test-Path $wingetPath) {
        Write-Host "`n[INFO] Winget bundle already exists. Skipping download." -ForegroundColor Cyan
    } else {
        Write-Host "`n[INFO] Downloading winget using curl...`n" -ForegroundColor Green
        
        try {
            & "C:\Windows\System32\curl.exe" -L -o $wingetPath "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            
            if (Test-Path $wingetPath) {
                Write-Host "`n[SUCCESS] Winget bundle downloaded successfully" -ForegroundColor Green
            } else {
                Write-Host "`n[ERROR] Winget download failed!" -ForegroundColor Red
                exit 1
            }
        }
        catch {
            Write-Host "[ERROR] Failed to download winget: $_" -ForegroundColor Red
            exit 1
        }
    }
    
    # Check if license file already exists
    if (Test-Path $licensePath) {
        Write-Host "[INFO] License file already exists. Skipping download.`n" -ForegroundColor Cyan
    } else {
        Write-Host "`n[INFO] Downloading winget license...`n" -ForegroundColor Green
        
        try {
            & "C:\Windows\System32\curl.exe" -L -o $licensePath "https://github.com/microsoft/winget-cli/releases/latest/download/e53e159d00e04f729cc2180cffd1c02e_License1.xml"
            
            if ((Test-Path $licensePath) -and ((Get-Item $licensePath).Length -gt 0)) {
                Write-Host "`n[SUCCESS] License file downloaded successfully`n" -ForegroundColor Green
            } else {
                Write-Host "`n[WARN] License download failed, proceeding without license...`n" -ForegroundColor DarkYellow
                if (Test-Path $licensePath) { Remove-Item $licensePath -Force }
            }
        }
        catch {
            Write-Host "`n[WARN] Failed to download license: $_" -ForegroundColor DarkYellow
            Write-Host "[INFO] Proceeding without license file..." -ForegroundColor DarkYellow
        }
    }
}

#========= Function to disable winget telemetry =========
function Disable-WingetTelemetry {
    Write-Host "`n[INFO] Checking winget telemetry settings..." -ForegroundColor Yellow

    try {
        $settingsDir  = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
        $settingsFile = Join-Path $settingsDir "settings.json"

        if (Test-Path $settingsFile) {
            $settings = Get-Content $settingsFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            
            if ($settings.PSObject.Properties.Name -contains 'telemetry' -and 
                $settings.telemetry.PSObject.Properties.Name -contains 'disable' -and 
                $settings.telemetry.disable -eq $true) {
                
                Write-Host "`n[INFO] Winget telemetry is already disabled." -ForegroundColor Cyan
                return
            }
        } else {
            if (-not (Test-Path $settingsDir)) {
                New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
            }
            $settings = [PSCustomObject]@{}
        }

        if (-not $settings.PSObject.Properties.Name -contains 'telemetry') {
            $settings | Add-Member -MemberType NoteProperty -Name 'telemetry' -Value ([PSCustomObject]@{})
        }

        $settings.telemetry | Add-Member -MemberType NoteProperty -Name 'disable' -Value $true -Force

        $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding UTF8 -Force

        Write-Host "`n[SUCCESS] Winget telemetry has been disabled." -ForegroundColor Green
        Write-Host "[INFO] Settings file: $settingsFile" -ForegroundColor Cyan
    }
    catch {
        Write-Host "`n[WARN] Failed to disable telemetry: $_" -ForegroundColor DarkYellow
        Write-Host "[INFO] You can manually disable it later with: winget settings" -ForegroundColor DarkYellow
    }
}

#========= 0. Download winget files if needed =========
Download-WingetFiles -FilesDirectory $filesDir

#========= 1. Detect architecture =========
$arch = $env:PROCESSOR_ARCHITECTURE
switch ($arch)
{
	"AMD64" { $archLower = "x64" }
	"x86"   { $archLower = "x86" }
	"ARM64" { $archLower = "arm64" }
	default {
		Write-Host "[ERROR] Unsupported architecture: $arch" -ForegroundColor Red
		exit 1
	}
}

#========= 2. Install VCLibs =========
$minVersion = [version]"14.0.33728.0"
$procArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
if ($procArch -eq 'Arm64')
{
	$arches = @('Arm64')
}
elseif ($procArch -eq 'X64')
{
	$arches = @('X64', 'X86')
}
else
{
	$arches = @('X86')
}
foreach ($arch in $arches)
{
	$archLower = $arch.ToLower()
	$pkgName = "Microsoft.VCLibs.140.00.UWPDesktop"
	$installed = Get-AppxPackage -Name $pkgName |
	Where-Object { $_.Architecture -eq $arch } |
	Sort-Object Version -Descending |
	Select-Object -First 1
	if ($installed -and [version]$installed.Version -ge $minVersion)
	{
		Write-Host "[INFO] VCLibs 140 - $($installed.Version) ($archLower) already installed. Skipping." -ForegroundColor Cyan
		continue
	}
	$fileName = "Microsoft.VCLibs.14.00_14.0.33728_$($archLower).Appx"
	$file = Join-Path $filesDir $fileName
	if (-not (Test-Path $file))
	{
		Write-Host "[WARN] Missing VCLibs file for ${archLower}: $file" -ForegroundColor DarkYellow
		Write-Host "[INFO] Skipping VCLibs installation for ${archLower}..." -ForegroundColor DarkYellow
		continue
	}
	Write-Host "`n[INFO] Installing VCLibs 140 ($archLower) from file..." -ForegroundColor Yellow
	try
	{
		Add-AppxPackage -Path $file -ErrorAction Stop
	}
	catch
	{
		Write-Host "[ERROR] Failed to install VCLibs $archLower : $_" -ForegroundColor Red
		exit 1
	}
}

#========= 3. Install Microsoft.UI.Xaml =========
$minXamlVersion = [version]"8.2501.31001.0"
foreach ($arch in $arches)
{
	$archLower = $arch.ToLower()
	$pkgName = "Microsoft.UI.Xaml.2.8"
	$installed = Get-AppxPackage -Name $pkgName |
	Where-Object { $_.Architecture -eq $arch } |
	Sort-Object Version -Descending |
	Select-Object -First 1
	if ($installed -and [version]$installed.Version -ge $minXamlVersion)
	{
		Write-Host "[INFO] UI.Xaml 2.8 - $($installed.Version) ($archLower) already installed. Skipping." -ForegroundColor Cyan
		continue
	}
	$fileName = "Microsoft.UI.Xaml.2.8_8.2501.31001_$($archLower).appx"
	$file = Join-Path $filesDir $fileName
	if (-not (Test-Path $file))
	{
		Write-Host "[WARN] Missing UI-Xaml file for ${archLower}: $file" -ForegroundColor DarkYellow
		Write-Host "[INFO] Skipping UI.Xaml installation for ${archLower}..." -ForegroundColor DarkYellow
		continue
	}
	Write-Host "`n[INFO] Installing UI.Xaml 2.8 ($archLower) from file..." -ForegroundColor Yellow
	try
	{
		Add-AppxPackage -Path $file -ErrorAction Stop
	}
	catch
	{
		Write-Host "[ERROR] Failed to install Microsoft.UI.Xaml 2.8 $archLower : $_" -ForegroundColor Red
		exit 1
	}
}

#========= 4. Check if winget is available =========
Write-Host "`n[INFO] Checking if winget is available ..." -ForegroundColor Yellow
try
{
	$wingetVersion = winget --version 2>$null
	if ($LASTEXITCODE -eq 0 -and $wingetVersion)
	{
		# Check if winget is available through PATH
		$wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
		if ($wingetCommand)
		{
			Write-Host "`n[SUCCESS] Winget is already available: $wingetVersion" -ForegroundColor Green
			
			# Try to find the actual winget.exe location
			$actualWingetPath = $null
			try
			{
				$actualWingetPath = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Recurse -Filter "winget.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
			}
			catch
			{
				Write-Host "[DEBUG] Could not search for winget.exe in WindowsApps" -ForegroundColor DarkGray
			}
			
			if ($actualWingetPath)
			{
				Write-Host "[INFO] Winget PATH: $($wingetCommand.Source) (alias)" -ForegroundColor Cyan
				Write-Host "[INFO] Winget actual location: $($actualWingetPath.Directory.FullName)" -ForegroundColor Cyan
			}
			else
			{
				Write-Host "[INFO] Winget PATH: $($wingetCommand.Source)" -ForegroundColor Cyan
			}
			
			# Disable telemetry for already installed winget
			Disable-WingetTelemetry
		}
		else
		{
			Write-Host "`n[SUCCESS] Winget is already available: $wingetVersion" -ForegroundColor Green
			Write-Host "[INFO] Winget PATH: Not in PATH (available through other means)" -ForegroundColor DarkYellow
			
			# Disable telemetry for already installed winget
			Disable-WingetTelemetry
		}
		exit 0
	}
}
catch
{
	Write-Host "[INFO] Winget not found in current PATH. Proceeding..." -ForegroundColor DarkYellow
}

#========= 5. Point to the offline files =========
$bundleFile = Join-Path $filesDir "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$licenseFile = Join-Path $filesDir "e53e159d00e04f729cc2180cffd1c02e_License1.xml"

#========= 6. Verify the main installer files exist =========
if (-not (Test-Path $bundleFile))
{
	Write-Host "[ERROR] Winget bundle file is missing: $bundleFile" -ForegroundColor Red
	exit 1
}

# License file is optional for direct installation
if (-not (Test-Path $licenseFile))
{
	Write-Host "[WARN] License file not found. Proceeding without license..." -ForegroundColor DarkYellow
}

#========= 7. Install winget for the current user =========
Write-Host "`n[INFO] Installing winget for the current user..." -ForegroundColor Yellow
try
{
	Add-AppxPackage -Path $bundleFile -ErrorAction Stop
}
catch
{
	Write-Host "[ERROR] Failed to install winget: $_" -ForegroundColor Red
	exit 1
}

#========= 8. Provision winget for all users (if license available) =========
if (Test-Path $licenseFile) {
    Write-Host "`n[INFO] Provisioning winget for all users..." -ForegroundColor Yellow
    try
    {
        Add-AppxProvisionedPackage -Online -PackagePath $bundleFile -LicensePath $licenseFile -Verbose
    }
    catch
    {
        Write-Host "[WARN] Provisioning failed (non-critical): $_" -ForegroundColor DarkYellow
    }
}

#========= 9. Verify if winget is available immediately =========
Write-Host "`n[INFO] Checking if winget is available globally..." -ForegroundColor Yellow
try
{
	$wingetVersion = winget --version 2>$null
	if ($LASTEXITCODE -eq 0 -and $wingetVersion)
	{
		# Check if winget is available through PATH
		$wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
		if ($wingetCommand)
		{
			Write-Host "`n[SUCCESS] Winget is now available: $wingetVersion" -ForegroundColor Green
			
			# Try to find the actual winget.exe location
			$actualWingetPath = $null
			try
			{
				$actualWingetPath = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Recurse -Filter "winget.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
			}
			catch
			{
				Write-Host "[DEBUG] Could not search for winget.exe in WindowsApps" -ForegroundColor DarkGray
			}
			
			if ($actualWingetPath)
			{
				Write-Host "[INFO] Winget PATH: $($wingetCommand.Source) (alias)" -ForegroundColor Cyan
				Write-Host "[INFO] Winget actual location: $($actualWingetPath.Directory.FullName)" -ForegroundColor Cyan
			}
			else
			{
				Write-Host "[INFO] Winget PATH: $($wingetCommand.Source)" -ForegroundColor Cyan
			}
			
			# Disable telemetry for newly installed winget
			Disable-WingetTelemetry
		}
		else
		{
			Write-Host "`n[SUCCESS] Winget is now available: $wingetVersion" -ForegroundColor Green
			Write-Host "[INFO] Winget PATH: Not in PATH (available through other means)" -ForegroundColor DarkYellow
			
			# Disable telemetry for newly installed winget
			Disable-WingetTelemetry
		}
		exit 0
	}
}
catch
{
	Write-Host "[INFO] Winget not found in current PATH. Proceeding..." -ForegroundColor DarkYellow
}

#========= 10. Search for winget.exe in WindowsApps =========
$wingetFile = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Recurse -Filter "winget.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $wingetFile)
{
	Write-Host "[ERROR] winget.exe not found in WindowsApps." -ForegroundColor Red
	exit 1
}

#========= 11. Get full path of winget folder =========
$wingetPath = $wingetFile.Directory.FullName
Write-Host "`n[INFO] Found winget.exe in WindowsApps" -ForegroundColor Cyan

#========= 12. Grant access to the folder (Admin required) =========
Write-Host "`n[INFO] Granting access to winget folder..." -ForegroundColor Yellow
$takeownPath = Join-Path $env:SystemRoot "System32\takeown.exe"
$icaclsPath = Join-Path $env:SystemRoot "System32\icacls.exe"

# Verify that the system utilities exist
if (-not (Test-Path $takeownPath))
{
	Write-Host "[ERROR] takeown.exe not found at: $takeownPath" -ForegroundColor Red
	exit 1
}
if (-not (Test-Path $icaclsPath))
{
	Write-Host "[ERROR] icacls.exe not found at: $icaclsPath" -ForegroundColor Red
	exit 1
}

Start-Process -Verb RunAs -FilePath $takeownPath -ArgumentList "/f `"$wingetPath`" /r /d y" -Wait
Start-Process -Verb RunAs -FilePath $icaclsPath -ArgumentList "`"$wingetPath`" /grant `"$env:USERNAME`":F /t" -Wait

#========= 13. Try executing winget directly and add to PATH if needed =========
Write-Host "`n[INFO] Testing winget execution from found path..." -ForegroundColor Yellow
try
{
	$wingetOutput = & $wingetFile.FullName --version
	if ($wingetOutput)
	{
		Write-Host "`n[SUCCESS] Winget is working: $wingetOutput" -ForegroundColor Green
		
		#========= 14. Add directory to PATH if not already =========
		$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
		if ($currentPath -notlike "*$wingetPath*")
		{
			[Environment]::SetEnvironmentVariable("PATH", "$currentPath;$wingetPath", "User")
			Write-Host "[INFO] Directory added to user PATH." -ForegroundColor Green
		}
		else
		{
			Write-Host "[INFO] Winget path already present in PATH." -ForegroundColor DarkYellow
		}
		
		# Disable telemetry for newly configured winget
		Disable-WingetTelemetry
	}
	else
	{
		Write-Host "[ERROR] Winget exists but failed to run." -ForegroundColor Red
		exit 1
	}
}
catch
{
	Write-Host "[ERROR] Could not execute winget directly: $_" -ForegroundColor Red
	exit 1
}
