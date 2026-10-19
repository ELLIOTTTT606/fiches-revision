#!/bin/bash
# Installation locale pour l'appli Fiches (macOS)
# Lancer dans le Terminal :  bash setup-mac.sh

# Origine autorisée à joindre Ollama. Mettre "*" pour tout autoriser (déconseillé).
ORIGINS="https://elliotttt606.github.io"
MODEL="qwen2.5:7b"

ok()   { printf "OK      %s\n" "$1"; }
fail() { printf "\033[31mECHEC : %s\033[0m\n" "$1"; exit 1; }
step() { printf "\n\033[36m=== %s ===\033[0m\n" "$1"; }

step "0. Outils"
if ! command -v brew >/dev/null; then
  echo "Homebrew absent : installation (ton mot de passe Mac te sera demandé)."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
command -v git >/dev/null && ok git || brew install git
command -v gh  >/dev/null && ok gh  || brew install gh
if [ -d /Applications/Ollama.app ]; then
  ok "Ollama.app"
else
  brew install --cask ollama-app 2>/dev/null || brew install --cask ollama \
    || fail "installe Ollama à la main depuis https://ollama.com/download, puis relance ce script."
fi
command -v ollama >/dev/null || export PATH="/Applications/Ollama.app/Contents/Resources:$PATH"

step "1. OLLAMA_ORIGINS (permanent)"
launchctl setenv OLLAMA_ORIGINS "$ORIGINS"
PLIST="$HOME/Library/LaunchAgents/com.fiches.ollama-origins.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.fiches.ollama-origins</string>
  <key>ProgramArguments</key>
  <array><string>/bin/launchctl</string><string>setenv</string><string>OLLAMA_ORIGINS</string><string>$ORIGINS</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
EOF
launchctl unload "$PLIST" 2>/dev/null; launchctl load "$PLIST"
ok "OLLAMA_ORIGINS = $(launchctl getenv OLLAMA_ORIGINS) (réappliqué à chaque connexion)"

step "2. Redémarrage d'Ollama"
osascript -e 'quit app "Ollama"' 2>/dev/null; pkill -x ollama 2>/dev/null; sleep 2
open -a Ollama
for i in $(seq 1 20); do curl -s http://localhost:11434/api/tags >/dev/null && break; sleep 1; done
curl -s http://localhost:11434/api/tags >/dev/null || fail "Ollama ne répond pas sur localhost:11434."
ok "Ollama répond"

step "3. Modèle $MODEL"
ollama list | grep -q "$MODEL" && ok "déjà installé" || ollama pull "$MODEL"

step "4. Test CORS"
TEST_ORIGIN="$ORIGINS"; [ "$ORIGINS" = "*" ] && TEST_ORIGIN="https://example.github.io"
ACAO=$(curl -s -D - -o /dev/null -H "Origin: $TEST_ORIGIN" http://localhost:11434/api/tags | grep -i "access-control-allow-origin")
[ -n "$ACAO" ] && ok "$ACAO" || fail "pas d'en-tête Access-Control-Allow-Origin."

step "5. GitHub"
gh auth status || printf "\033[33mPas connecté. Lance :  gh auth login   (GitHub.com > HTTPS > Login with a web browser)\033[0m\n"

printf "\nTerminé. Copie tout ce qui est affiché ci-dessus et renvoie-le à Claude.\n"
