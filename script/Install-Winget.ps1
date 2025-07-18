#=========================================================================
# Windows Package Manager (winget) offline installer
# Version: 1.0.0
#
# Author: EXLOUD
# >> https://github.com/EXLOUD <<
#=========================================================================

#========= Define the offline files directory =========
# $ErrorActionPreference = "Stop"
$filesDir = Join-Path $PSScriptRoot "Files"

#========= Function to disable winget telemetry =========
function Disable-WingetTelemetry {
    Write-Host "`n[INFO] Disabling winget telemetry..." -ForegroundColor Yellow

    try {
        $settingsDir  = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
        $settingsFile = Join-Path $settingsDir "settings.json"

        if (-not (Test-Path $settingsDir)) {
            New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
        }

        if (Test-Path $settingsFile) {
            $settings = Get-Content $settingsFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } else {
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

#========= 0. Detect architecture =========
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

#========= 1. Install VCLibs =========
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
		Write-Host "[ERROR] Missing VCLibs file for ${archLower}: $file" -ForegroundColor Red
		exit 1
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

#========= 2. Install Microsoft.UI.Xaml =========
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
		Write-Host "[ERROR] Missing UI-Xaml file for ${archLower}: $file" -ForegroundColor Red
		exit 1
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

#========= 3. Check if winget is available =========
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

#========= 4. Point to the offline files =========
$bundleFile = Join-Path $filesDir "Microsoft.DesktopAppInstaller_1.11.400.msixbundle"
$licenseFile = Join-Path $filesDir "Microsoft.DesktopAppInstaller_License.xml"

#========= 5. Verify the main installer files exist =========
if (-not (Test-Path $bundleFile) -or -not (Test-Path $licenseFile))
{
	Write-Host "[ERROR] One or both offline files are missing in .\Files" -ForegroundColor Red
	exit 1
}

#========= 6. Install winget for the current user =========
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

#========= 7. Provision winget for all users =========
Write-Host "`n[INFO] Provisioning winget for all users..." -ForegroundColor Yellow
try
{
	Add-AppxProvisionedPackage -Online -PackagePath $bundleFile -LicensePath $licenseFile -Verbose
}
catch
{
	Write-Host "[WARN] Provisioning failed (non-critical): $_" -ForegroundColor DarkYellow
}

#========= 8. Verify if winget is available immediately =========
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

#========= 9. Search for winget.exe in WindowsApps =========
$wingetFile = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Recurse -Filter "winget.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $wingetFile)
{
	Write-Host "[ERROR] winget.exe not found in WindowsApps." -ForegroundColor Red
	exit 1
}

#========= 10. Get full path of winget folder =========
$wingetPath = $wingetFile.Directory.FullName
Write-Host "`n[INFO] Found winget.exe in WindowsApps" -ForegroundColor Cyan

#========= 11. Grant access to the folder (Admin required) =========
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

#========= 12. Try executing winget directly and add to PATH if needed =========
Write-Host "`n[INFO] Testing winget execution from found path..." -ForegroundColor Yellow
try
{
	$wingetOutput = & $wingetFile.FullName --version
	if ($wingetOutput)
	{
		Write-Host "`n[SUCCESS] Winget is working: $wingetOutput" -ForegroundColor Green
		
		#========= 13. Add directory to PATH if not already =========
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