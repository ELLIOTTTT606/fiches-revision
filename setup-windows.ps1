# Installation locale pour l'appli Fiches (Windows)
# Lancer dans PowerShell :  powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1

# Origine autorisée à joindre Ollama. Mettre "*" pour tout autoriser (déconseillé).
$Origins = "https://elliotttt606.github.io"
$Model   = "qwen2.5:7b"

function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "`n=== 0. Outils ===" -ForegroundColor Cyan
$tools = @(
  @{ cmd = "git";    id = "Git.Git" },
  @{ cmd = "gh";     id = "GitHub.cli" },
  @{ cmd = "ollama"; id = "Ollama.Ollama" }
)
foreach ($t in $tools) {
  if (Get-Command $t.cmd -ErrorAction SilentlyContinue) {
    Write-Host "OK      $($t.cmd)"
  } else {
    Write-Host "Install $($t.cmd) via winget..."
    winget install --id $t.id -e --accept-source-agreements --accept-package-agreements
    Refresh-Path
  }
}
foreach ($t in $tools) {
  if (-not (Get-Command $t.cmd -ErrorAction SilentlyContinue)) {
    Write-Host "ECHEC : $($t.cmd) introuvable. Ferme et rouvre PowerShell, puis relance le script." -ForegroundColor Red
    exit 1
  }
}

Write-Host "`n=== 1. OLLAMA_ORIGINS (permanent) ===" -ForegroundColor Cyan
setx OLLAMA_ORIGINS $Origins | Out-Null
$env:OLLAMA_ORIGINS = $Origins
Write-Host "OLLAMA_ORIGINS = $Origins"

Write-Host "`n=== 2. Redemarrage d'Ollama ===" -ForegroundColor Cyan
Get-Process | Where-Object { $_.ProcessName -like "ollama*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$app = "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe"
if (Test-Path $app) { Start-Process $app } else { Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden }
$up = $false
for ($i = 0; $i -lt 20; $i++) {
  try { Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 2 | Out-Null; $up = $true; break } catch { Start-Sleep 1 }
}
if (-not $up) { Write-Host "ECHEC : Ollama ne repond pas sur localhost:11434." -ForegroundColor Red; exit 1 }
Write-Host "OK      Ollama repond"

Write-Host "`n=== 3. Modele $Model ===" -ForegroundColor Cyan
if ((ollama list) -match [regex]::Escape($Model)) { Write-Host "OK      deja installe" }
else { ollama pull $Model }

Write-Host "`n=== 4. Test CORS ===" -ForegroundColor Cyan
$testOrigin = if ($Origins -eq "*") { "https://example.github.io" } else { $Origins }
$headers = curl.exe -s -D - -o NUL -H "Origin: $testOrigin" http://localhost:11434/api/tags
$acao = $headers | Select-String -Pattern "Access-Control-Allow-Origin"
if ($acao) { Write-Host "OK      $($acao.Line.Trim())" -ForegroundColor Green }
else { Write-Host "ECHEC : pas d'en-tete Access-Control-Allow-Origin. Redemarre le PC et relance." -ForegroundColor Red; exit 1 }

Write-Host "`n=== 5. GitHub ===" -ForegroundColor Cyan
gh auth status 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "Pas connecte. Lance :  gh auth login   (GitHub.com > HTTPS > Login with a web browser)" -ForegroundColor Yellow }

Write-Host "`nTermine. Copie tout ce qui est affiche ci-dessus et renvoie-le a Claude." -ForegroundColor Cyan
