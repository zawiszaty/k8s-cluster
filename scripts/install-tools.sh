#!/bin/bash
set -e

echo "🔧 Instalacja narzędzi Kubernetes..."
echo ""

# Kolory
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Katalog docelowy
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Dodaj do PATH jeśli nie istnieje
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    export PATH="$BIN_DIR:$PATH"
    echo -e "${YELLOW}⚠️  Dodano $BIN_DIR do PATH w ~/.bashrc${NC}"
    echo "   Uruchom: source ~/.bashrc"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Instalacja KIND"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v kind &> /dev/null; then
    echo -e "${GREEN}✅ KIND już zainstalowany: $(kind version)${NC}"
else
    curl -sLo "$BIN_DIR/kind" https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x "$BIN_DIR/kind"
    echo -e "${GREEN}✅ KIND zainstalowany${NC}"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Instalacja kubectl"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✅ kubectl już zainstalowany: $(kubectl version --client -o json | grep -o '"gitVersion":"[^"]*' | cut -d'"' -f4)${NC}"
else
    curl -sLo "$BIN_DIR/kubectl" "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x "$BIN_DIR/kubectl"
    echo -e "${GREEN}✅ kubectl zainstalowany${NC}"
fi
echo ""


echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Wszystkie narzędzia zainstalowane!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}Zainstalowane narzędzia:${NC}"
echo "  • KIND: $(kind version 2>/dev/null || echo 'nie znaleziono')"
echo "  • kubectl: $(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*' | cut -d'"' -f4 || echo 'nie znaleziono')"
echo ""
echo -e "${YELLOW}ℹ️  Cilium i Flux są instalowane z manifestów w repo (nie potrzeba CLI)${NC}"
echo ""
echo -e "${GREEN}🎉 Gotowe! Możesz teraz uruchomić: ./scripts/create-cluster.sh${NC}"
