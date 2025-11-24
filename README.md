# 🚀 Kubernetes Platform with Argo CD, Cilium & Local Registry

A production-ready Kubernetes platform built with:
- **Argo CD** for GitOps deployments
- **Cilium** CNI with Hubble observability
- **Local Container Registry** for development
- **Complete monitoring stack** (Loki, Grafana, Tempo)
- **Demo application** (Python FastAPI + Frontend)

## ⚡ Quick Start

```bash
# 1. Create the cluster (~5-7 minutes)
./scripts/create-cluster.sh

# 2. Add hosts to /etc/hosts
sudo bash -c 'echo "127.0.0.1 argocd.local grafana.local hubble.local guestbook.local registry.local demo.local demo-api.local" >> /etc/hosts'

# 3. Get Argo CD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# 4. Access dashboards
open https://argocd.local       # Login: admin
open https://grafana.local      # Login: admin/admin
open https://demo.local         # Demo application
```

## 📦 What's Included

### Core Infrastructure

- **Kubernetes 1.29.2** (KIND cluster)
- **Cilium** - CNI with kube-proxy replacement, Hubble UI enabled
- **Argo CD** - GitOps continuous delivery
- **Ingress-NGINX** - Ingress controller
- **cert-manager** - Automatic TLS certificates
- **Local Registry** - Container registry on localhost:5001

### Monitoring & Observability

- **Grafana** - Visualization and dashboards
- **Loki** - Log aggregation
- **Promtail** - Log shipping
- **Tempo** - Distributed tracing
- **OpenTelemetry** - Instrumentation
- **Hubble UI** - Network observability

### Sample Applications

- **Guestbook** - PHP + Redis with OpenTelemetry tracing
- **HotROD** - Demo app with distributed tracing
- **Demo App** - Python FastAPI + Modern frontend

## 🌐 Available Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Argo CD** | https://argocd.local | admin / (kubectl secret) |
| **Grafana** | https://grafana.local | admin / admin |
| **Hubble UI** | https://hubble.local | - |
| **Guestbook** | https://guestbook.local | - |
| **Registry** | https://registry.local | - |
| **Demo App** | https://demo.local | - |
| **Demo API** | https://demo-api.local | - |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       KIND Cluster                          │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   Argo CD   │  │   Cilium     │  │ Ingress-NGINX  │  │
│  │   (GitOps)  │  │  (CNI+SM)    │  │   (Ingress)    │  │
│  └─────────────┘  └──────────────┘  └─────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              Applications (Namespaces)               │ │
│  │  • guestbook   • hotrod   • monitoring   • demo-app │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
        ↑                           ↑
        │                           │
   Git Repo                  Local Registry
   (GitHub)                  (localhost:5001)
```

## 🚀 Deploy Demo Application

The demo app showcases a modern microservices architecture with Python FastAPI backend and responsive frontend.

```bash
# 1. Build images
./scripts/build-demo-app.sh

# 2. Deploy via Argo CD (recommended)
kubectl apply -f cluster/infrastructure/argocd/demo-app.yaml

# 3. Access the app
open https://demo.local
open https://demo-api.local/docs  # FastAPI Swagger UI
```

**Demo App Features:**
- RESTful API with 2 endpoints (GET/POST messages)
- Modern responsive UI with auto-refresh
- Health checks and probes
- CORS configured
- Ready for production


## 📝 License

MIT License - feel free to use for learning and development.

---

## 🎉 What You Get

✅ **Complete Kubernetes platform** ready in ~5-7 minutes
✅ **GitOps with Argo CD** - Visual UI + Auto-sync
✅ **Modern CNI** - Cilium with Hubble observability
✅ **Local registry** - No external dependencies
✅ **Full monitoring** - Loki, Grafana, Tempo, Hubble
✅ **Demo applications** - Learn by example
✅ **Production patterns** - Security, monitoring, GitOps
✅ **Comprehensive docs** - Everything you need to know

**Ready to deploy your apps? Start with the Quick Start above!** 🚀
