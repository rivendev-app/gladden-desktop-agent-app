# Cleanup Visual C++ Redistributable 2015-2022 Artifacts (Updated)
# Run as Administrator

$ErrorActionPreference = "SilentlyContinue"

Write-Host "Stopping Windows Installer service..." -ForegroundColor Yellow
Stop-Service msiserver -Force

# Registry locations to check
$registryLocations = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Classes\Installer\Products",
    "HKLM:\SOFTWARE\Classes\Installer\Features",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
)

Write-Host "Searching for Visual C++ registry keys..." -ForegroundColor Yellow

foreach ($location in $registryLocations) {
    if (Test-Path $location) {
        $keys = Get-ChildItem -Path $location
        foreach ($key in $keys) {
            # Check DisplayName or ProductName
            $displayName = (Get-ItemProperty -Path $key.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
            $productName = (Get-ItemProperty -Path $key.PSPath -Name "ProductName" -ErrorAction SilentlyContinue).ProductName

            if (($displayName -match "Visual C\+\+.*(2015|2017|2019|2022).*Redistributable") -or 
                ($productName -match "Visual C\+\+.*(2015|2017|2019|2022).*Redistributable") -or
                ($productName -match "Microsoft Visual C\+\+ 2022 X86 Minimum Runtime") -or
                ($productName -match "Microsoft Visual C\+\+ 2022 X64 Minimum Runtime") -or
                ($productName -match "Microsoft Visual C\+\+ 2022 X86 Additional Runtime") -or
                ($productName -match "Microsoft Visual C\+\+ 2022 X64 Additional Runtime")) {
                
                Write-Host "Found corrupted key: $($key.PSPath)" -ForegroundColor Red
                Remove-Item -Path $key.PSPath -Recurse -Force
                Write-Host "Removed." -ForegroundColor Green
            }
        }
    }
}

Write-Host "Cleaning ProgramData Package Cache..." -ForegroundColor Yellow
$packageCache = "C:\ProgramData\Package Cache"
if (Test-Path $packageCache) {
    # Remove specific GUID folders known to be problematic if they exist
    # {5D0C4511-3CA1-4FF8-A4BA-C0E1957ABEEA} - Minimum Runtime x86
    # {A5592FEF-F948-4BA6-A066-8BBFC2DC7EE1} - Additional Runtime x86
    $badGuids = @(
        "{5D0C4511-3CA1-4FF8-A4BA-C0E1957ABEEA}",
        "{A5592FEF-F948-4BA6-A066-8BBFC2DC7EE1}"
    )
    
    foreach ($guid in $badGuids) {
        Remove-Item -Path "$packageCache\$guid*" -Recurse -Force -Verbose
    }
    
    # Generic cleanup for VC++ redist folders
    Get-ChildItem -Path $packageCache -Recurse -Filter "*VisualCpp*" | Remove-Item -Recurse -Force
}

Write-Host "Done. Please restart your computer and try installing the Redistributables again." -ForegroundColor Cyan
