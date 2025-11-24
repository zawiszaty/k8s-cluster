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

echo -e "${BLUE}🐳 Build and Push Script${NC}"
echo "================================"
echo ""

# Funkcja do budowania i push'owania image
build_and_push() {
    local APP_NAME=$1
    local APP_DIR=$2
    local DOCKERFILE=$3
    local IMAGE_TAG=${4:-latest}

    echo -e "${YELLOW}📦 Budowanie: $APP_NAME${NC}"

    if [ ! -f "$APP_DIR/$DOCKERFILE" ]; then
        echo -e "${RED}❌ Dockerfile nie znaleziony: $APP_DIR/$DOCKERFILE${NC}"
        return 1
    fi

    # Buduj image
    docker build -t "$APP_NAME:$IMAGE_TAG" -f "$APP_DIR/$DOCKERFILE" "$APP_DIR"

    # Tag dla local registry
    docker tag "$APP_NAME:$IMAGE_TAG" "$REGISTRY/$APP_NAME:$IMAGE_TAG"

    # Push do registry
    echo -e "${BLUE}📤 Push do registry: $REGISTRY/$APP_NAME:$IMAGE_TAG${NC}"
    docker push "$REGISTRY/$APP_NAME:$IMAGE_TAG"

    echo -e "${GREEN}✅ $APP_NAME zbudowany i wrzucony do registry${NC}"
    echo ""
}

# Sprawdź czy registry działa
echo "🔍 Sprawdzam registry..."
if ! curl -s http://localhost:5001/v2/_catalog > /dev/null; then
    echo -e "${RED}❌ Registry nie działa na localhost:5001${NC}"
    echo "Uruchom najpierw: docker run -d --restart=always -p 5001:5000 --name kind-registry registry:2"
    exit 1
fi
echo -e "${GREEN}✅ Registry działa${NC}"
echo ""

# Przykład użycia - możesz dodać swoje aplikacje tutaj
# build_and_push "nazwa-app" "$PROJECT_DIR/ścieżka/do/app" "Dockerfile" "v1.0.0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Gotowe!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📋 Aby użyć obrazów w Kubernetes:${NC}"
echo "  image: $REGISTRY/nazwa-app:tag"
echo ""
echo -e "${BLUE}📋 Sprawdź obrazy w registry:${NC}"
echo "  curl http://localhost:5001/v2/_catalog"
echo ""
