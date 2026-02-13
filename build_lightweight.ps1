# build_lightweight.ps1
# This script builds small, framework-dependent executables.
# REQUIRES: The user must have .NET 10 Desktop Runtime installed on their PC.

$architectures = @("win-x64", "win-x86", "win-arm64")
$outputBase = ".\Releases_Lightweight"

if (Test-Path $outputBase) { Remove-Item -Recurse -Force $outputBase }
New-Item -ItemType Directory -Path $outputBase

# FORCE CLEAN to remove huge R2R artifacts
dotnet clean -c Release

foreach ($arch in $architectures) {
    Write-Host "--- Building Lightweight for $arch ---" -ForegroundColor Cyan
    
    # We use very specific flags to ensure the smallest size:
    # --self-contained false : Don't bundle the runtime (Small)
    # PublishSingleFile : Pack everything into one EXE
    # PublishReadyToRun false : Disable R2R which was causing the 100MB+ bloat
    dotnet publish ScrcpyGuiDotNet.csproj `
        -c Release `
        -r $arch `
        --self-contained false `
        -p:PublishSingleFile=true `
        -p:PublishReadyToRun=false `
        -p:IncludeNativeLibrariesForSelfExtract=false `
        -p:DebugType=none `
        -p:DebugSymbols=false `
        -o "$outputBase\$arch"
    
    $size = (Get-Item "$outputBase\$arch\ScrcpyGUI.exe").Length / 1MB
    Write-Host "Success! Final Size: $([math]::Round($size, 2)) MB" -ForegroundColor Green
}

Write-Host "`nLightweight builds complete! Check the 'Releases_Lightweight' folder." -ForegroundColor Yellow
