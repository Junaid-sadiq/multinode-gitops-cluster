# React App Deployment Guide

## Complete Deployment Pipeline

This document covers the entire deployment pipeline from development to production.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Local Development](#local-development)
4. [Docker Build](#docker-build)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- Node.js 20.x
- Docker 20.x+
- kubectl 1.24+
- GitHub account
- Kubernetes cluster

### 1. Local Development

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO/reactapp

# Install dependencies
npm install

# Start development server
npm run dev
# Visit http://localhost:5173
```

### 2. Build for Production

```bash
# Build static files
npm run build

# Preview production build
npm run preview
```

### 3. Docker Local Test

```bash
# Build Docker image
docker build -t reactapp:local .

# Run container
docker run -p 8080:80 reactapp:local

# Test
curl http://localhost:8080/health
```

### 4. Deploy to Kubernetes

```bash
# Update manifests with your details
cd ../k8s/reactapp
sed -i 's/YOUR_USERNAME/your-username/g' *.yaml
sed -i 's/YOUR_REPO/your-repo/g' *.yaml

# Apply with kubectl
kubectl apply -k .

# Or use ArgoCD
kubectl apply -f argocd-application.yaml
```

---

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Developer Workflow                       │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ React Source │  │  Dockerfile  │  │  K8s Manifests│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions CI/CD                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  PR Checks   │  │  Build Image │  │ Update GitOps│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│            GitHub Container Registry (GHCR)                  │
│                  ghcr.io/user/repo/reactapp                 │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                        ArgoCD                                │
│              (GitOps Continuous Deployment)                  │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Ingress    │  │   Service    │  │  Deployment  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                         (3-10 Pods with HPA)                │
└─────────────────────────────────────────────────────────────┘
```

### Component Stack

**Frontend**: React 18.3.1 + TypeScript + Tailwind CSS  
**Build Tool**: Vite 5.4.1  
**Web Server**: Nginx 1.28.0-alpine  
**Container**: Docker multi-stage build  
**Registry**: GitHub Container Registry  
**Orchestration**: Kubernetes 1.24+  
**GitOps**: ArgoCD  
**CI/CD**: GitHub Actions  

---

## Local Development

### Development Server

```bash
# Start with hot reload
npm run dev

# Custom port
npm run dev -- --port 3000 --host

# Debug mode
DEBUG=* npm run dev
```

### Testing

```bash
# Run tests (when enabled)
npm test

# Run tests once
npm run test:run

# Test with UI
npm run test:ui

# Coverage report
npm run test:coverage
```

### Linting

```bash
# Check for errors
npm run lint

# Auto-fix issues
npm run lint -- --fix

# Type check
npx tsc --noEmit
```

### Environment Variables

Create `.env.local`:

```bash
VITE_API_URL=http://localhost:3001
VITE_APP_VERSION=1.0.0
```

Access in code:

```typescript
const apiUrl = import.meta.env.VITE_API_URL
```

---

## Docker Build

### Build Process

The Dockerfile uses a two-stage build:

**Stage 1: Builder**
- Base: `node:20-alpine` (~5MB)
- Installs dependencies
- Builds production bundle
- Output: optimized `/app/dist`

**Stage 2: Production**
- Base: `nginx:1.28.0-alpine` (~25MB)
- Copies built assets
- Configured with custom nginx.conf
- Runs as non-root user

### Build Commands

```bash
# Standard build
docker build -t reactapp:latest ./reactapp

# With custom tag
docker build -t reactapp:v1.0.0 ./reactapp

# Multi-platform
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t reactapp:latest \
  ./reactapp

# With build cache
docker build \
  --cache-from ghcr.io/user/repo/reactapp:latest \
  -t reactapp:latest \
  ./reactapp
```

### Testing Docker Image

```bash
# Run locally
docker run -d -p 8080:80 --name reactapp reactapp:latest

# Check health
curl http://localhost:8080/health

# View logs
docker logs -f reactapp

# Execute commands
docker exec -it reactapp sh

# Stop and remove
docker stop reactapp && docker rm reactapp
```

### Push to Registry

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Tag image
docker tag reactapp:latest ghcr.io/USERNAME/REPO/reactapp:v1.0.0

# Push
docker push ghcr.io/USERNAME/REPO/reactapp:v1.0.0
```

---

## CI/CD Pipeline

### Workflow Triggers

**PR Checks** (`pr-checks.yml`):
- Trigger: Pull request to `main` or `develop`
- Runs: Lint, type check, build
- Must pass before merge

**CI Build** (`ci-build.yml`):
- Trigger: Push to `main` branch
- Builds: Docker image
- Pushes: To GHCR
- Updates: GitOps manifests
- Deploys: Via ArgoCD

### Setup Steps

1. **Enable GitHub Actions**
   ```bash
   Settings → Actions → General
   Workflow permissions: Read and write ✅
   ```

2. **Configure Repository Variables**
   ```bash
   gh variable set DOCKER_REGISTRY --body "ghcr.io"
   gh variable set IMAGE_NAME --body "${{ github.repository }}/reactapp"
   ```

3. **Update Workflow Files**
   - Replace `YOUR_USERNAME` with your GitHub username
   - Replace `YOUR_REPO` with your repository name

4. **Test Workflows**
   ```bash
   # Create feature branch
   git checkout -b feature/test
   git push origin feature/test
   
   # Create PR (triggers pr-checks.yml)
   gh pr create --title "Test PR"
   
   # Merge PR (triggers ci-build.yml)
   gh pr merge --squash
   ```

### Monitoring CI/CD

```bash
# List workflow runs
gh run list

# Watch specific run
gh run watch

# View logs
gh run view --log

# Rerun failed jobs
gh run rerun <run-id>
```

---

## Kubernetes Deployment

### Prerequisites

```bash
# Verify kubectl
kubectl version --client

# Verify cluster access
kubectl cluster-info

# Verify ArgoCD (optional)
kubectl get pods -n argocd
```

### Deployment Methods

#### Method 1: Direct kubectl Apply

```bash
cd k8s/reactapp

# Apply all manifests
kubectl apply -k .

# Or apply individually
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

#### Method 2: ArgoCD (Recommended)

```bash
# Install ArgoCD (if not installed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply Application manifest
kubectl apply -f argocd-application.yaml

# Or use ArgoCD CLI
argocd app create reactapp \
  --repo https://github.com/USERNAME/REPO.git \
  --path k8s/reactapp \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace reactapp \
  --sync-policy automated
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n reactapp

# Check pods
kubectl get pods -n reactapp

# Check deployment status
kubectl rollout status deployment/reactapp -n reactapp

# Check HPA
kubectl get hpa -n reactapp

# Check ingress
kubectl get ingress -n reactapp
```

### Access Application

```bash
# Port-forward (local testing)
kubectl port-forward -n reactapp svc/reactapp 8080:80

# Get ingress URL
kubectl get ingress -n reactapp
```

---

## Monitoring & Maintenance

### Health Checks

```bash
# Pod health
kubectl get pods -n reactapp

# Deployment health
kubectl describe deployment reactapp -n reactapp

# Service endpoints
kubectl get endpoints -n reactapp
```

### Logs

```bash
# All pods
kubectl logs -n reactapp -l app=reactapp --tail=100 -f

# Specific pod
kubectl logs -n reactapp <pod-name> -f

# Previous pod (if crashed)
kubectl logs -n reactapp <pod-name> --previous
```

### Metrics

```bash
# Pod metrics
kubectl top pods -n reactapp

# Node metrics
kubectl top nodes

# HPA status
kubectl get hpa -n reactapp --watch
```

### Scaling

```bash
# Manual scale
kubectl scale deployment reactapp -n reactapp --replicas=5

# HPA will auto-scale between 3-10 replicas
```

### Updates

**Zero-downtime rolling update:**

```bash
# Update image
kubectl set image deployment/reactapp \
  reactapp=ghcr.io/user/repo/reactapp:v2.0.0 \
  -n reactapp

# Watch rollout
kubectl rollout status deployment/reactapp -n reactapp
```

### Rollback

```bash
# View rollout history
kubectl rollout history deployment/reactapp -n reactapp

# Rollback to previous version
kubectl rollout undo deployment/reactapp -n reactapp

# Rollback to specific revision
kubectl rollout undo deployment/reactapp -n reactapp --to-revision=2
```

---

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n reactapp <pod-name>

# Common causes:
# - Image pull error → Check image tag and registry access
# - Resource limits → Adjust requests/limits
# - Health check failure → Check /health endpoint
```

#### 2. Image Pull Errors

```bash
# Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=USERNAME \
  --docker-password=GITHUB_TOKEN \
  -n reactapp

# Update deployment to use secret
spec:
  template:
    spec:
      imagePullSecrets:
      - name: ghcr-secret
```

#### 3. Ingress Not Working

```bash
# Check ingress
kubectl describe ingress reactapp -n reactapp

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check TLS certificate
kubectl get certificate -n reactapp
kubectl describe certificate reactapp-tls -n reactapp
```

#### 4. Build Failures

```bash
# Check GitHub Actions logs
gh run view --log

# Common causes:
# - npm install failure → Clear cache
# - TypeScript errors → Run tsc locally
# - Docker build timeout → Optimize Dockerfile
```

### Debug Commands

```bash
# Shell into pod
kubectl exec -it -n reactapp <pod-name> -- sh

# Check nginx config
kubectl exec -n reactapp <pod-name> -- nginx -t

# View nginx logs
kubectl exec -n reactapp <pod-name> -- cat /var/log/nginx/error.log

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
wget -O- http://reactapp.reactapp.svc.cluster.local
```

---

## Performance Optimization

### Build Performance

- **Cache npm dependencies** in CI/CD
- **Use Docker layer caching**
- **Optimize bundle size** with tree-shaking
- **Enable compression** in Nginx

### Runtime Performance

- **Horizontal Pod Autoscaling** (3-10 pods)
- **Resource requests/limits** properly set
- **Nginx caching** for static assets
- **CDN** for global distribution

### Cost Optimization

- **Right-size resources** based on metrics
- **Use spot instances** for non-prod
- **Enable cluster autoscaling**
- **Clean up unused resources**

---

## Security Checklist

- ✅ Non-root container user
- ✅ Read-only root filesystem
- ✅ Security headers in Nginx
- ✅ TLS/HTTPS enabled
- ✅ Network policies configured
- ✅ Image vulnerability scanning
- ✅ SBOM generation
- ✅ Secrets management (not in Git)
- ✅ RBAC configured
- ✅ Pod security policies

---

## Related Documentation

- [DOCKER.md](./DOCKER.md) - Docker setup and usage
- [TESTING.md](./TESTING.md) - Testing documentation
- [../k8s/reactapp/README.md](../k8s/reactapp/README.md) - Kubernetes manifests
- [../.github/workflows/README.md](../.github/workflows/README.md) - CI/CD workflows

---

**Last Updated**: July 22, 2026  
**Status**: Production Ready ✅
