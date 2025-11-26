#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
REGISTRY="localhost:5001"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_APP_DIR="$PROJECT_DIR/cluster/apps/demo-app"
VERSION="${1:-v1.0}"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Build & Push Demo App to Registry      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if registry is running
echo -e "${YELLOW}🔍 Checking registry...${NC}"
if ! curl -s http://localhost:5001/v2/_catalog > /dev/null; then
    echo -e "${RED}❌ Registry is not running on localhost:5001${NC}"
    echo "Start the cluster: ./scripts/create-cluster.sh"
    exit 1
fi
echo -e "${GREEN}✅ Registry is running${NC}"
echo ""

# Build and push API
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📦 Building: demo-api${NC}"
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

# Build and push Frontend
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📦 Building: demo-frontend${NC}"
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

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ✅ Done!                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📦 Images in registry:${NC}"
echo "  • $REGISTRY/demo-api:$VERSION"
echo "  • $REGISTRY/demo-frontend:$VERSION"
echo ""
echo -e "${BLUE}📋 Check registry:${NC}"
echo "  curl http://localhost:5001/v2/_catalog"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo ""
echo "1. Update Kubernetes manifests (if using a different version than v1.0):"
echo "   sed -i 's/demo-api:v1.0/demo-api:$VERSION/' $DEMO_APP_DIR/api-deployment.yaml"
echo "   sed -i 's/demo-frontend:v1.0/demo-frontend:$VERSION/' $DEMO_APP_DIR/frontend-deployment.yaml"
echo ""
echo "2. Commit and push to Git:"
echo "   git add cluster/apps/demo-app/"
echo "   git commit -m 'Update demo-app to $VERSION'"
echo "   git push"
echo ""
echo "3. Apply Argo CD Application (if not already done):"
echo "   kubectl apply -f $PROJECT_DIR/cluster/infrastructure/argocd/demo-app.yaml"
echo ""
echo "4. Or deploy directly:"
echo "   kubectl apply -f $DEMO_APP_DIR/"
echo ""
echo "5. Check the application:"
echo "   https://demo.local"
echo "   https://demo-api.local"
echo ""
echo -e "${YELLOW}⚠️  Remember to add to /etc/hosts:${NC}"
echo "   127.0.0.1 demo.local demo-api.local"
echo ""
