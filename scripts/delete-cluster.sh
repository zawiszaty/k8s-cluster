#!/bin/bash

echo "🗑️  Deleting Kubernetes cluster..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if cluster exists
cluster_exists() {
    kind get clusters 2>/dev/null | grep -q "^platform$"
}

# Check if cluster exists
if ! cluster_exists; then
    echo -e "${YELLOW}⚠️  Cluster 'platform' does not exist${NC}"
    echo ""
    echo "Available clusters:"
    kind get clusters 2>/dev/null || echo "  (none)"
    exit 0
fi

# Confirmation
echo -e "${YELLOW}⚠️  This will delete the 'platform' cluster with all its resources!${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Stopping port-forward processes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
pkill -f "kubectl.*port-forward" 2>/dev/null && echo -e "${GREEN}✅ Port-forward stopped${NC}" || echo "ℹ️  No running port-forwards"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deleting KIND cluster"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kind delete cluster --name platform
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if cluster_exists; then
    echo -e "${RED}❌ Cluster still exists - something went wrong${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Cluster has been completely deleted${NC}"
fi

# Check for remaining Docker containers
REMAINING_CONTAINERS=$(docker ps -a --filter "name=platform" --format "{{.Names}}" 2>/dev/null)
if [ -n "$REMAINING_CONTAINERS" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Remaining containers detected:${NC}"
    echo "$REMAINING_CONTAINERS"
    read -p "Do you want to delete them as well? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker ps -a --filter "name=platform" --format "{{.ID}}" | xargs -r docker rm -f
        echo -e "${GREEN}✅ Containers deleted${NC}"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Cluster has been deleted. You can create a new one:${NC}"
echo "  ./scripts/create-cluster.sh"
echo ""
