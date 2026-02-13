# build_ultra_compressed.ps1
# This script builds the smallest possible version that is still 100% portable.

$architectures = @("win-x64", "win-x86", "win-arm64")
$outputBase = ".\Releases_Ultra"

if (Test-Path $outputBase) { Remove-Item -Recurse -Force $outputBase }
New-Item -ItemType Directory -Path $outputBase

foreach ($arch in $architectures) {
    Write-Host "--- Building Ultra Compressed for $arch ---" -ForegroundColor Cyan
    dotnet publish ScrcpyGuiDotNet.csproj `
        -c Release `
        -r $arch `
        --self-contained true `
        -p:PublishSingleFile=true `
        -p:PublishTrimmed=true `
        -p:TrimMode=partial `
        -p:PublishReadyToRun=false `
        -p:EnableCompressionInSingleFile=true `
        -p:DebugType=none `
        -p:DebugSymbols=false `
        -o "$outputBase\$arch"
    
    $size = (Get-Item "$outputBase\$arch\ScrcpyGuiDotNet.exe").Length / 1MB
    Write-Host "Success! Size: $([math]::Round($size, 2)) MB" -ForegroundColor Green
}

Write-Host "`nUltra builds complete! Check the 'Releases_Ultra' folder." -ForegroundColor Yellow
