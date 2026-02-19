# Fix VC++ Redistributable Registry Key
# Removes the corrupted uninstall entry for {2E15F519-4FDA-4834-B4EE-7EFCE7D8D4EE}

$guid = "{ba10fda9-f731-441f-a999-000bbb7ceec2}"
$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$guid"
)

Write-Host "Checking for corrupted VC++ registry keys..." -ForegroundColor Cyan

$found = $false
foreach ($path in $paths) {
    if (Test-Path $path) {
        $found = $true
        Write-Host "Found key: $path" -ForegroundColor Yellow
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Host "Successfully removed key." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to remove key: $_. Try running as Administrator."
        }
    }
}

if (-not $found) {
    Write-Host "No registry keys found for GUID $guid." -ForegroundColor White
}

Write-Host "`nDone. Now try running the Visual C++ Redistributable installer again." -ForegroundColor Cyan
