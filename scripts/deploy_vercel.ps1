# Package Flutter web build for Vercel and deploy (run from repo root).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot/..

Write-Host "Building Flutter web..."
flutter build web --release --pwa-strategy=none --base-href "/"

$output = ".vercel/output"
if (Test-Path $output) { Remove-Item -Recurse -Force $output }
New-Item -ItemType Directory -Force -Path "$output/static" | Out-Null
Copy-Item -Recurse -Force build/web/* "$output/static/"

@'
{
  "version": 3,
  "routes": [
    { "handle": "filesystem" },
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
'@ | Set-Content -Encoding utf8 "$output/config.json"

Write-Host "Deploying to Vercel..."
vercel link --project implant_stock --yes
vercel deploy --prebuilt --prod --yes
