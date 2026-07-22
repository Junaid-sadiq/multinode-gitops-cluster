# React App - Docker & GitOps Setup

## 🚀 Quick Start

### Local Development
```bash
npm install
npm run dev
# Visit http://localhost:5173
```

### Docker (Local)
```bash
# Build and run (Linux/Mac)
./docker-run.sh build
./docker-run.sh run

# Build and run (Windows)
.\docker-run.ps1 build
.\docker-run.ps1 run

# Visit http://localhost:8080
```

### Production Deployment
```bash
# Push to main branch
git push origin main

# GitHub Actions automatically:
# 1. Builds Docker image
# 2. Pushes to GitHub Container Registry
# 3. Updates Kubernetes manifests
# 4. ArgoCD deploys to cluster
```

## 📁 Project Structure

```
reactapp/
├── src/                      # React source code
│   ├── components/           # React components
│   │   ├── ui/              # UI components (shadcn)
│   │   │   └── shader-lines.tsx
│   │   └── demo.tsx         # Landing page
│   ├── lib/                 # Utilities
│   ├── test/                # Test setup
│   ├── App.tsx              # Main app
│   └── main.tsx             # Entry point
├── public/                  # Static assets
├── Dockerfile               # Multi-stage build
├── nginx.conf               # Nginx configuration
├── docker-run.sh            # Docker helper (Linux/Mac)
├── docker-run.ps1           # Docker helper (Windows)
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
└── DEPLOYMENT.md            # Full deployment guide

k8s/reactapp/                # Kubernetes manifests
├── namespace.yaml
├── deployment.yaml
├── service.yaml
├── ingress.yaml
├── hpa.yaml
├── kustomization.yaml
├── argocd-application.yaml
└── README.md

.github/workflows/           # CI/CD pipelines
├── pr-checks.yml            # PR validation
├── ci-build.yml             # Build & deploy
└── README.md                # CI/CD documentation
```

## 🐳 Docker Setup

### Image Details
- **Base Image**: nginx:1.28.0-alpine (~25MB)
- **Build Time**: ~2-3 minutes
- **Multi-platform**: linux/amd64, linux/arm64
- **Security**: Non-root user, read-only filesystem

### Nginx Features
- ✅ Gzip compression (70-80% bandwidth reduction)
- ✅ Security headers (XSS, Clickjacking protection)
- ✅ Static asset caching (1 year for fingerprinted files)
- ✅ SPA routing support (serves index.html for all routes)
- ✅ Health check endpoint (`/health`)

### Docker Commands

```bash
# Build
docker build -t reactapp:latest .

# Run
docker run -d -p 8080:80 --name reactapp reactapp:latest

# Logs
docker logs -f reactapp

# Shell
docker exec -it reactapp sh

# Stop
docker stop reactapp && docker rm reactapp

# Clean
docker rmi reactapp:latest
```

**📖 See [DOCKER.md](./DOCKER.md) for complete Docker documentation**

## ☸️ Kubernetes Deployment

### Resources
- **Namespace**: `reactapp`
- **Deployment**: 3 replicas (auto-scales 3-10)
- **Service**: ClusterIP on port 80
- **Ingress**: HTTPS with TLS
- **HPA**: CPU 70%, Memory 80%

### Resource Limits
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

### Deployment Methods

**Option 1: kubectl**
```bash
cd k8s/reactapp
kubectl apply -k .
```

**Option 2: ArgoCD (GitOps)**
```bash
kubectl apply -f k8s/reactapp/argocd-application.yaml
```

**📖 See [k8s/reactapp/README.md](../k8s/reactapp/README.md) for complete K8s documentation**

## 🔄 CI/CD Pipeline

### Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **pr-checks.yml** | Pull Request | Lint, type check, build |
| **ci-build.yml** | Push to main | Build image, deploy |

### Pipeline Flow

```
Developer Push
     ↓
[PR Created]
     ↓
pr-checks.yml runs:
  • ESLint
  • TypeScript check
  • Build test
     ↓
[PR Merged to main]
     ↓
ci-build.yml runs:
  • Build Docker image
  • Push to GHCR
  • Security scan (Trivy)
  • Update K8s manifests
  • Commit changes
     ↓
[ArgoCD Detects Change]
     ↓
[Deploy to Kubernetes]
     ↓
[Production Live! 🎉]
```

### Setup CI/CD

1. **Enable GitHub Actions**
   - Settings → Actions → Enable workflows

2. **Update placeholders in workflows**
   ```bash
   cd .github/workflows
   sed -i 's/YOUR_USERNAME/your-username/g' *.yml
   sed -i 's/YOUR_REPO/your-repo/g' *.yml
   ```

3. **Push to main**
   ```bash
   git push origin main
   ```

**📖 See [.github/workflows/README.md](../.github/workflows/README.md) for complete CI/CD documentation**

## 🔐 Security Features

### Container Security
- ✅ Non-root user (UID 101)
- ✅ Read-only root filesystem
- ✅ Dropped ALL capabilities
- ✅ No privilege escalation

### Application Security
- ✅ Security headers (CSP, X-Frame-Options, etc.)
- ✅ HTTPS/TLS enabled
- ✅ Vulnerability scanning (Trivy)
- ✅ SBOM generation
- ✅ Secrets not in Git

### Kubernetes Security
- ✅ Pod Security Context
- ✅ Network Policies
- ✅ RBAC configured
- ✅ Resource limits
- ✅ Health checks

## 📊 Monitoring

### Health Checks

```bash
# Application health
curl http://localhost:8080/health

# Kubernetes pod health
kubectl get pods -n reactapp

# HPA status
kubectl get hpa -n reactapp
```

### Logs

```bash
# Docker logs
docker logs -f reactapp

# Kubernetes logs
kubectl logs -n reactapp -l app=reactapp -f

# Specific pod
kubectl logs -n reactapp <pod-name> -f
```

### Metrics

```bash
# Container metrics
docker stats reactapp

# Pod metrics
kubectl top pods -n reactapp

# Node metrics
kubectl top nodes
```

## 🧪 Testing

### Unit Tests
```bash
npm run test              # Watch mode
npm run test:run          # Run once
npm run test:coverage     # Coverage report
```

### Integration Tests
```bash
# Build and test Docker image
./docker-run.sh build
./docker-run.sh run
./docker-run.sh test
```

### E2E Tests (Playwright)
```bash
npm install -D @playwright/test
npx playwright install
npx playwright test
```

**📖 See [TESTING-COMPREHENSIVE.md](./TESTING-COMPREHENSIVE.md) for complete testing documentation**

## 🔧 Configuration

### Environment Variables

**Development** (`.env.local`):
```bash
VITE_API_URL=http://localhost:3001
VITE_APP_VERSION=dev
```

**Production** (Kubernetes ConfigMap):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: reactapp-config
data:
  NODE_ENV: production
  API_URL: https://api.example.com
```

### Custom Domain

Update `k8s/reactapp/ingress.yaml`:
```yaml
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: your-domain-tls
  rules:
  - host: your-domain.com
```

## 🐛 Troubleshooting

### Build Issues
```bash
# Clear npm cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# Clear Docker cache
docker builder prune -a
```

### Deployment Issues
```bash
# Check pod status
kubectl get pods -n reactapp
kubectl describe pod -n reactapp <pod-name>

# Check events
kubectl get events -n reactapp --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n reactapp <pod-name>
```

### CI/CD Issues
```bash
# View workflow runs
gh run list

# View specific run
gh run view <run-id> --log

# Rerun failed jobs
gh run rerun <run-id>
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Complete deployment guide |
| [DOCKER.md](./DOCKER.md) | Docker setup and usage |
| [TESTING-COMPREHENSIVE.md](./TESTING-COMPREHENSIVE.md) | Testing guide |
| [k8s/reactapp/README.md](../k8s/reactapp/README.md) | Kubernetes manifests |
| [.github/workflows/README.md](../.github/workflows/README.md) | CI/CD workflows |

## 🚦 Status

| Component | Status |
|-----------|--------|
| Development Server | ✅ Working |
| Docker Build | ✅ Working |
| Docker Run | ✅ Working |
| CI/CD Pipeline | ✅ Active |
| Kubernetes Manifests | ✅ Ready |
| ArgoCD GitOps | ✅ Configured |
| Tests | ⏸️ Pending Tailwind v4 fix |
| Documentation | ✅ Complete |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is part of a multi-node Kubernetes GitOps cluster demonstration.

---

**Tech Stack**: React + TypeScript + Tailwind CSS + Vite + Docker + Nginx + Kubernetes + ArgoCD + GitHub Actions

**Last Updated**: July 22, 2026
