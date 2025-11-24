#!/bin/bash
set -e

# Kolory
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Konfiguracja
REGISTRY="localhost:5001"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_APP_DIR="$PROJECT_DIR/cluster/apps/demo-app"
VERSION="${1:-v1.0}"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Build & Push Demo App to Registry      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Sprawdź czy registry działa
echo -e "${YELLOW}🔍 Sprawdzam registry...${NC}"
if ! curl -s http://localhost:5001/v2/_catalog > /dev/null; then
    echo -e "${RED}❌ Registry nie działa na localhost:5001${NC}"
    echo "Uruchom klaster: ./scripts/create-cluster.sh"
    exit 1
fi
echo -e "${GREEN}✅ Registry działa${NC}"
echo ""

# Build i push API
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📦 Budowanie: demo-api${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$DEMO_APP_DIR/api"

echo "Building image..."
docker build -t demo-api:$VERSION .

echo "Tagging for registry..."
docker tag demo-api:$VERSION $REGISTRY/demo-api:$VERSION

echo "Pushing to registry..."
docker push $REGISTRY/demo-api:$VERSION

echo -e "${GREEN}✅ demo-api:$VERSION pushed to registry${NC}"
echo ""

# Build i push Frontend
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📦 Budowanie: demo-frontend${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$DEMO_APP_DIR/frontend"

echo "Building image..."
docker build -t demo-frontend:$VERSION .

echo "Tagging for registry..."
docker tag demo-frontend:$VERSION $REGISTRY/demo-frontend:$VERSION

echo "Pushing to registry..."
docker push $REGISTRY/demo-frontend:$VERSION

echo -e "${GREEN}✅ demo-frontend:$VERSION pushed to registry${NC}"
echo ""

# Podsumowanie
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ✅ Gotowe!                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📦 Obrazy w registry:${NC}"
echo "  • $REGISTRY/demo-api:$VERSION"
echo "  • $REGISTRY/demo-frontend:$VERSION"
echo ""
echo -e "${BLUE}📋 Sprawdź registry:${NC}"
echo "  curl http://localhost:5001/v2/_catalog"
echo ""
echo -e "${BLUE}🚀 Następne kroki:${NC}"
echo ""
echo "1. Zaktualizuj manifesty Kubernetes (jeśli używasz innej wersji niż v1.0):"
echo "   sed -i 's/demo-api:v1.0/demo-api:$VERSION/' $DEMO_APP_DIR/api-deployment.yaml"
echo "   sed -i 's/demo-frontend:v1.0/demo-frontend:$VERSION/' $DEMO_APP_DIR/frontend-deployment.yaml"
echo ""
echo "2. Commit i push do Git:"
echo "   git add cluster/apps/demo-app/"
echo "   git commit -m 'Update demo-app to $VERSION'"
echo "   git push"
echo ""
echo "3. Zastosuj Argo CD Application (jeśli jeszcze nie):"
echo "   kubectl apply -f $PROJECT_DIR/cluster/infrastructure/argocd/demo-app.yaml"
echo ""
echo "4. Lub deploy bezpośrednio:"
echo "   kubectl apply -f $DEMO_APP_DIR/"
echo ""
echo "5. Sprawdź aplikację:"
echo "   https://demo.local"
echo "   https://demo-api.local"
echo ""
echo -e "${YELLOW}⚠️  Pamiętaj dodać do /etc/hosts:${NC}"
echo "   127.0.0.1 demo.local demo-api.local"
echo ""
