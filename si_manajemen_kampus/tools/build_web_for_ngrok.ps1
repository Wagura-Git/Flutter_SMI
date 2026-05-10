param(
    [Parameter(Mandatory = $true)]
    [string]$PublicBaseUrl
)

$ErrorActionPreference = 'Stop'

function Remove-TrailingSlash {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "PublicBaseUrl tidak boleh kosong."
    }

    return $Value.TrimEnd('/')
}

$normalizedBaseUrl = Remove-TrailingSlash -Value $PublicBaseUrl
$apiBaseUrl = "$normalizedBaseUrl/1_Project_Thesis/SI-manajemen-kampus/backend/api"
$webBaseHref = "/1_Project_Thesis/SI-manajemen-kampus/si_manajemen_kampus/build/web/"
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterProjectDirectory = Split-Path -Parent $scriptDirectory

Write-Host "Membangun Flutter Web untuk akses publik via ngrok..." -ForegroundColor Cyan
Write-Host "Public URL : $normalizedBaseUrl" -ForegroundColor Yellow
Write-Host "API URL    : $apiBaseUrl" -ForegroundColor Yellow
Write-Host "Base href  : $webBaseHref" -ForegroundColor Yellow

Push-Location $flutterProjectDirectory
try {
    flutter build web --release `
        --base-href $webBaseHref `
        --dart-define=API_BASE_URL=$apiBaseUrl
} finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Build Flutter Web gagal."
}

$publicWebUrl = "$normalizedBaseUrl$webBaseHref"

Write-Host ""
Write-Host "Build selesai." -ForegroundColor Green
Write-Host "Buka website publik ini:" -ForegroundColor Green
Write-Host $publicWebUrl -ForegroundColor White
