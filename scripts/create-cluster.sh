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
echo "  Step 1/6: Creating local container registry"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Create registry container if it doesn't exist
if [ "$(docker inspect -f '{{.State.Running}}' kind-registry 2>/dev/null || true)" != 'true' ]; then
  docker run -d --restart=always -p 5001:5000 --name kind-registry registry:2
fi

echo -e "${GREEN}✅ Registry created${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 2/6: Creating KIND cluster"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kind create cluster --name platform --config "$PROJECT_DIR/configs/cluster.yaml"

# Connect registry to kind network
docker network connect kind kind-registry 2>/dev/null || true

# Remove taint from control-plane so pods can run
echo "Removing taint from control-plane..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- || true
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule- || true

# Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5001"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo -e "${GREEN}✅ Cluster created${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 3/6: Installing Cilium CNI"
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

# Apply Hubble UI ingress
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/hubble-ingress/ingress.yaml"

echo -e "${GREEN}✅ Cilium installed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 4/6: Installing Ingress-NGINX"
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
echo "  Step 5/6: Installing cert-manager"
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
echo "  Step 6/7: Installing OpenTelemetry Operator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.91.0/opentelemetry-operator.yaml
echo "Waiting for OpenTelemetry Operator to be ready..."
sleep 10
kubectl wait --namespace opentelemetry-operator-system \
  --for=condition=available deployment/opentelemetry-operator-controller-manager \
  --timeout=300s
echo -e "${GREEN}✅ OpenTelemetry Operator installed${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 7/7: Installing Argo CD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for Argo CD to be ready..."
sleep 15
kubectl wait --namespace argocd \
  --for=condition=available deployment/argocd-server \
  --timeout=300s

# Apply ArgoCD ingress
kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/argocd-ingress/ingress.yaml"

echo -e "${GREEN}✅ Argo CD installed${NC}"
echo ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Configuring Argo CD Applications"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$PROJECT_DIR/cluster/infrastructure/argocd" ]; then
    kubectl apply -f "$PROJECT_DIR/cluster/infrastructure/argocd/"
    echo -e "${GREEN}✅ Argo CD Applications configured${NC}"
    echo ""
    echo -e "${BLUE}📦 Applications will be deployed by Argo CD:${NC}"
    echo "  • Monitoring (Loki, Grafana, Tempo, OpenTelemetry)"
    echo "  • Guestbook"
    echo "  • Demo App"
    echo "  • HotROD"
else
    echo -e "${YELLOW}⚠️  ArgoCD applications directory not found${NC}"
fi
echo ""

echo ""
echo "Login: admin"
echo ""

echo ""
echo "🔑 Argo CD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Installation completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📊 Services will be available at (once deployed by ArgoCD):${NC}"
echo "  • Argo CD:   https://argocd.local"
echo "  • Grafana:   https://grafana.local (admin/admin)"
echo "  • Hubble UI: https://hubble.local"
echo "  • Guestbook: https://guestbook.local"
echo "  • Demo App:  https://demo.local"
echo "  • HotROD:    http://hotrod.local"
echo ""
echo -e "${YELLOW}⚠️  Add to /etc/hosts:${NC}"
echo "127.0.0.1 argocd.local grafana.local hubble.local guestbook.local demo.local demo-api.local hotrod.local"
echo ""
echo -e "${BLUE}🐳 Container Registry:${NC}"
echo "  • Local registry available at: localhost:5001"
echo "  • From within cluster: kind-registry:5000"
echo "  • Tag images: docker tag myimage:latest localhost:5001/myimage:latest"
echo "  • Push images: docker push localhost:5001/myimage:latest"
echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo "  1. Monitor ArgoCD applications: kubectl get applications -n argocd"
echo "  2. Check application status: kubectl get pods -A"
echo "  3. Access ArgoCD UI at https://argocd.local"
echo ""
echo -e "${GREEN}🎉 Cluster infrastructure ready! Applications are being deployed by ArgoCD...${NC}"
