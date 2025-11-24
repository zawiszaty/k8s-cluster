#!/bin/bash
set -e

echo "🚀 Creating Kubernetes cluster..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to check if cluster exists
cluster_exists() {
    kind get clusters 2>/dev/null | grep -q "^platform$"
}

# Check if cluster already exists
if cluster_exists; then
    echo -e "${YELLOW}⚠️  Cluster 'platform' already exists!${NC}"
    read -p "Do you want to delete the existing cluster and create a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        kind delete cluster --name platform
    else
        echo "❌ Cancelled. Cluster was not created."
        exit 1
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1a/9: Creating local container registry"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Check if registry already exists
if [ "$(docker ps -q -f name=kind-registry)" ]; then
    echo "Registry already exists"
else
    echo "Creating local registry..."
    docker run -d --restart=always -p 5001:5000 --name kind-registry registry:2
fi
echo -e "${GREEN}✅ Registry ready on localhost:5001${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1b/9: Creating KIND cluster"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kind create cluster --name platform --config "$PROJECT_DIR/configs/cluster.yaml"

# Connect registry to KIND network
echo "Connecting registry to KIND network..."
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' kind-registry)" = 'null' ]; then
    docker network connect "kind" "kind-registry"
fi

# Remove taint from control-plane so pods can run
echo "Removing taint from control-plane..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- || true
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule- || true

echo -e "${GREEN}✅ Cluster created${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 2/9: Installing Cilium CNI via CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing Cilium CLI..."
cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=platform-control-plane \
  --set k8sServicePort=6443 \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}"
echo "Waiting for Cilium to be ready..."
cilium status --wait --wait-duration=5m
echo -e "${GREEN}✅ Cilium installed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 3/9: Installing Ingress-NGINX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/ingress-nginx/deploy.yaml"
echo "Waiting for Ingress-NGINX to be ready..."
sleep 10
kubectl wait --namespace ingress-nginx \
  --for=condition=available deployment/ingress-nginx-controller \
  --timeout=300s
echo -e "${GREEN}✅ Ingress-NGINX installed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 4/9: Installing cert-manager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/cert-manager/cert-manager.yaml"
echo "Waiting for cert-manager to be ready..."
sleep 10
kubectl wait --namespace cert-manager \
  --for=condition=available deployment/cert-manager \
  --timeout=300s
kubectl wait --namespace cert-manager \
  --for=condition=available deployment/cert-manager-webhook \
  --timeout=60s
sleep 5
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/cert-manager/cluster-issuer.yaml"
echo -e "${GREEN}✅ cert-manager installed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 5/9: Installing Argo CD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for Argo CD to be ready..."
sleep 15
kubectl wait --namespace argocd \
  --for=condition=available deployment/argocd-server \
  --timeout=300s
echo -e "${GREEN}✅ Argo CD installed${NC}"
echo ""

echo "🔑 Argo CD Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "Login: admin"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 6/9: Installing monitoring (Loki + Grafana)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/monitoring/loki.yaml"
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/monitoring/promtail.yaml"
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/monitoring/grafana.yaml"
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/monitoring/grafana-dashboard.yaml"
echo "Waiting for Grafana to be ready..."
sleep 10
kubectl wait --namespace monitoring \
  --for=condition=available deployment/grafana \
  --timeout=300s
echo -e "${GREEN}✅ Monitoring installed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 7/9: Deploying Guestbook application"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl create namespace guestbook --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$PROJECT_DIR/cluster/apps/guestbook/"
echo -e "${GREEN}✅ Guestbook deployed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 8/9: Creating Ingress for dashboards"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/ingress-nginx/ingress-dashboards.yaml"
echo -e "${GREEN}✅ Ingress created${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 9/9: Configuring Argo CD Applications"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$PROJECT_DIR/cluster/infrastructure/argocd" ]; then
    kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/argocd/"
    echo -e "${GREEN}✅ Argo CD Applications configured${NC}"
else
    echo -e "${YELLOW}⚠️  argocd directory does not exist - skip${NC}"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Installation completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📊 Dashboards available at:${NC}"
echo "  • Argo CD:   https://argocd.local"
echo "  • Grafana:   https://grafana.local (admin/admin)"
echo "  • Hubble UI: https://hubble.local"
echo "  • Guestbook: https://guestbook.local"
echo "  • Registry:  https://registry.local"
echo ""
echo -e "${YELLOW}⚠️  Add to /etc/hosts:${NC}"
echo "127.0.0.1 argocd.local grafana.local hubble.local guestbook.local registry.local demo.local demo-api.local"
echo ""
echo -e "${BLUE}🐳 Local Registry:${NC}"
echo "  • localhost:5001"
echo "  • Test: docker tag myimage:tag localhost:5001/myimage:tag && docker push localhost:5001/myimage:tag"
echo ""
echo -e "${GREEN}🎉 Cluster ready to use!${NC}"
