#!/bin/bash
set -e

echo "🔧 Installing Kubernetes tools..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Target directory
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Add to PATH if not exists
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    export PATH="$BIN_DIR:$PATH"
    echo -e "${YELLOW}⚠️  Added $BIN_DIR to PATH in ~/.bashrc${NC}"
    echo "   Run: source ~/.bashrc"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installing KIND"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v kind &> /dev/null; then
    echo -e "${GREEN}✅ KIND already installed: $(kind version)${NC}"
else
    curl -sLo "$BIN_DIR/kind" https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x "$BIN_DIR/kind"
    echo -e "${GREEN}✅ KIND installed${NC}"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installing kubectl"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✅ kubectl already installed: $(kubectl version --client -o json | grep -o '"gitVersion":"[^"]*' | cut -d'"' -f4)${NC}"
else
    curl -sLo "$BIN_DIR/kubectl" "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x "$BIN_DIR/kubectl"
    echo -e "${GREEN}✅ kubectl installed${NC}"
fi
echo ""


echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ All tools installed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}Installed tools:${NC}"
echo "  • KIND: $(kind version 2>/dev/null || echo 'not found')"
echo "  • kubectl: $(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*' | cut -d'"' -f4 || echo 'not found')"
echo ""
echo -e "${YELLOW}ℹ️  Cilium and Flux are installed from manifests in the repo (CLI not needed)${NC}"
echo ""
echo -e "${GREEN}🎉 Done! You can now run: ./scripts/create-cluster.sh${NC}"
