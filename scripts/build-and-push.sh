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

echo -e "${BLUE}🐳 Build and Push Script${NC}"
echo "================================"
echo ""

# Function to build and push image
build_and_push() {
    local APP_NAME=$1
    local APP_DIR=$2
    local DOCKERFILE=$3
    local IMAGE_TAG=${4:-latest}

    echo -e "${YELLOW}📦 Building: $APP_NAME${NC}"

    if [ ! -f "$APP_DIR/$DOCKERFILE" ]; then
        echo -e "${RED}❌ Dockerfile not found: $APP_DIR/$DOCKERFILE${NC}"
        return 1
    fi

    # Build image
    docker build -t "$APP_NAME:$IMAGE_TAG" -f "$APP_DIR/$DOCKERFILE" "$APP_DIR"

    # Tag for local registry
    docker tag "$APP_NAME:$IMAGE_TAG" "$REGISTRY/$APP_NAME:$IMAGE_TAG"

    # Push to registry
    echo -e "${BLUE}📤 Pushing to registry: $REGISTRY/$APP_NAME:$IMAGE_TAG${NC}"
    docker push "$REGISTRY/$APP_NAME:$IMAGE_TAG"

    echo -e "${GREEN}✅ $APP_NAME built and pushed to registry${NC}"
    echo ""
}

# Check if registry is running
echo "🔍 Checking registry..."
if ! curl -s http://localhost:5001/v2/_catalog > /dev/null; then
    echo -e "${RED}❌ Registry is not running on localhost:5001${NC}"
    echo "Run first: docker run -d --restart=always -p 5001:5000 --name kind-registry registry:2"
    exit 1
fi
echo -e "${GREEN}✅ Registry is running${NC}"
echo ""

# Example usage - you can add your applications here
# build_and_push "app-name" "$PROJECT_DIR/path/to/app" "Dockerfile" "v1.0.0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Done!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📋 To use images in Kubernetes:${NC}"
echo "  image: $REGISTRY/app-name:tag"
echo ""
echo -e "${BLUE}📋 Check images in registry:${NC}"
echo "  curl http://localhost:5001/v2/_catalog"
echo ""
