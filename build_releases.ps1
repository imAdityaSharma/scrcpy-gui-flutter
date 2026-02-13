# build_releases.ps1
# This script builds self-contained, single-file executables for all architectures.

$architectures = @("win-x64", "win-x86", "win-arm64")
$outputBase = ".\Releases"

if (Test-Path $outputBase) { Remove-Item -Recurse -Force $outputBase }
New-Item -ItemType Directory -Path $outputBase

foreach ($arch in $architectures) {
    Write-Host "--- Building for $arch ---" -ForegroundColor Cyan
    dotnet publish ScrcpyGuiDotNet.csproj `
        -c Release `
        -r $arch `
        --self-contained true `
        -p:PublishSingleFile=true `
        -p:PublishReadyToRun=true `
        -p:IncludeNativeLibrariesForSelfExtract=true `
        -o "$outputBase\$arch"
    
    Write-Host "Success! Portable version for $arch is in $outputBase\$arch" -ForegroundColor Green
}

Write-Host "`nAll builds complete! Check the 'Releases' folder." -ForegroundColor Yellow
