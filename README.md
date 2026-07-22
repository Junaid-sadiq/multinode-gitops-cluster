# Multi-Node GitOps Kubernetes Cluster

Production-ready Kubernetes on CSC cPouta with CI/CD GitOps pipeline using ArgoCD and GitHub Actions.

## 📋 Table of Contents

- [Overview](#overview) | [Architecture](#architecture) | [Prerequisites](#prerequisites) | [Setup](#infrastructure-setup) | [CI/CD](#cicd-pipeline) | [GitOps](#gitops-with-argocd) | [Access](#accessing-services) | [Troubleshooting](#monitoring--troubleshooting)

---

## 🎯 Overview

**Technology Stack**: Terraform + k3s + ArgoCD + GitHub Actions + React + GHCR  
**Key Features**: Zero-downtime deployments, auto-scaling (3-10 pods), automated security scanning, ~25MB images, 10-12 min deployment time

| Component | Technology |
|-----------|-----------|
| Cloud | CSC cPouta (OpenStack) |
| IaC | Terraform |
| Kubernetes | k3s |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Registry | GHCR |
| App | React + Vite + Tailwind |
| Runtime | Nginx Alpine |
| Security | Trivy  

---

## 🏗️ Architecture

```
Internet → Floating IP (86.50.229.25:30007) → Security Group → K8s Cluster
  ├─ k8s-master (192.168.1.10) - Control Plane + ArgoCD
  └─ k8s-worker (192.168.1.11) - App Pods (reactapp-ui ×3, HPA 3-10, CPU 70%)
```

**CI/CD Flow**: Push → GitHub Actions (build+scan) → GHCR (image) → Update manifest (SHA tag) → ArgoCD sync (3min poll) → K8s rolling update → Live (zero downtime)

**Network**: Private 192.168.1.0/24, public IP on master, NodePort 30007  
**Security**: Public SG (SSH/HTTP/HTTPS/6443/30007), Internal SG (full subnet access)

---

## 📦 Prerequisites

**Required**:
- Terraform (v1.0+): `winget install HashiCorp.Terraform`
- Git: `winget install Git.Git`
- CSC cPouta account with API access (2 VMs, 1 floating IP, 1 network quota)
- OpenStack credentials: `auth_url`, `user_name`, `password`, `tenant_name`, `region`

**Optional**:
- kubectl: `winget install Kubernetes.kubectl`
- ArgoCD CLI: [github.com/argoproj/argo-cd/releases](https://github.com/argoproj/argo-cd/releases)

---

## 🚀 Infrastructure Setup

### Quick Start (Automated - Recommended)

```powershell
# 1. Clone repo
git clone https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
cd multinode-gitops-cluster

# 2. Configure credentials - Create terraform/terraform.tfvars
auth_url    = "https://pouta.csc.fi:5001/v3"
user_name   = "your-username"
password    = "your-password"
tenant_name = "your-project-name"
region      = "regionOne"
# ssh_key_name = "pouta-dokploy-key"  # Optional

# 3. Deploy everything (~10-15 min)
.\deploy-k8s-cluster.ps1

# Options:
# .\deploy-k8s-cluster.ps1 -DestroyFirst    # Destroy + redeploy
# .\deploy-k8s-cluster.ps1 -SkipTerraform   # Skip Terraform step
```

**Script does**: Terraform apply → Create VMs → Install k3s (master+worker) → Install ArgoCD → Save credentials

**Output**:
```
✓ Cluster ready! Access at http://86.50.229.25:30007
✓ ArgoCD: https://86.50.229.25:30008 (admin / see .argocd-credentials)
```

### Manual Deployment (Step-by-Step)

<details>
<summary>Click to expand manual steps</summary>

**Terraform:**
```powershell
cd terraform
terraform init
terraform apply
$MASTER_IP = terraform output -raw master_floating_ip
```

**k3s Master:**
```bash
ssh -i terraform/cpouta_key.pem ubuntu@$MASTER_IP
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
sudo cat /var/lib/rancher/k3s/server/node-token  # Save token
```

**k3s Worker:**
```bash
ssh -J ubuntu@$MASTER_IP -i terraform/cpouta_key.pem ubuntu@192.168.1.11
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.10:6443 K3S_TOKEN=<TOKEN> sh -
```

**Verify:**
```bash
kubectl get nodes  # Both Ready
```

**ArgoCD:**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8080,"nodePort":30008}]}}'
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > .argocd-credentials
```

</details>

---

## ⚛️ React Application

**Location**: `reactapp/` - React 18 + Vite + Tailwind v4 + TypeScript  
**Features**: Animated shader background, newsletter signup, confetti celebration, responsive design  
**Build**: Multi-stage Docker (Node build → Nginx runtime, ~25MB final image)  
**Health**: `/health` endpoint, gzip compression, security headers, SPA routing

```powershell
# Local dev
cd reactapp
npm install && npm run dev  # → http://localhost:5173

# Docker test
docker build -t reactapp:local . && docker run -p 8080:80 reactapp:local
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

**1. PR Checks** (`pr-checks.yml`) - Runs on PRs to `main`:
```yaml
Trigger: pull_request (reactapp/**)
Jobs: Lint → Type check → Build verification
```

**2. Build & Deploy** (`ci-build-simple.yml`) - Runs on push to `main`:
```yaml
Trigger: push to main (reactapp/**)
Steps:
  1. Checkout code
  2. Build multi-stage Docker image (linux/amd64)
  3. Scan with Trivy (continue-on-error: true)
  4. Login to GHCR (ghcr.io)
  5. Push image: ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp:sha-{COMMIT_SHA}
  6. Update k8s/reactapp/deployment.yaml with new SHA
  7. Commit + push manifest changes
  8. Trigger ArgoCD sync (auto-detects in 3 min)
Timeout: 25 minutes
```

### Critical Configuration

⚠️ **GHCR requires lowercase**: Use `junaid-sadiq` not `Junaid-sadiq`  
⚠️ **Platform**: `linux/amd64` only (multi-platform causes 30min+ hangs)  
⚠️ **Image pull**: `imagePullPolicy: Always` in deployment.yaml forces fresh pulls  
⚠️ **Security**: Trivy scans but doesn't block deployment (`continue-on-error: true`)

### Secrets Required

Configure in GitHub repo → Settings → Secrets:
```
GHCR_TOKEN - GitHub Personal Access Token with packages:write
```

### Deployment Timeline

- Code push → GitHub Actions triggered (instant)
- Build + scan + push (4-6 min)
- Manifest update (30s)
- ArgoCD sync poll (up to 3 min)
- K8s rolling update (2-3 min)
- **Total: 10-12 minutes** ✅

---

## 🔄 GitOps with ArgoCD

### Setup ArgoCD Application

ArgoCD automatically deploys from Git. Application is pre-configured in `k8s/reactapp/argocd-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: reactapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
    targetRevision: HEAD
    path: k8s/reactapp
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true       # Delete resources not in Git
      selfHeal: true    # Auto-sync if manual changes made
    syncOptions:
      - CreateNamespace=true
```

### Deploy Application

```bash
# SSH to master node
ssh -i terraform/cpouta_key.pem ubuntu@86.50.229.25

# Apply ArgoCD application
kubectl apply -f https://raw.githubusercontent.com/Junaid-sadiq/multinode-gitops-cluster/main/k8s/reactapp/argocd-application.yaml

# Watch sync status
kubectl get applications -n argocd
# NAME       SYNC STATUS   HEALTH STATUS
# reactapp   Synced        Healthy

# Check deployed resources
kubectl get pods,svc,hpa
```

### Verify Deployment

```bash
# Check pods (should see 3 replicas)
kubectl get pods -l app=reactapp-ui

# Check service
kubectl get svc react-app-service
# TYPE: NodePort, PORT: 80:30007/TCP

# Check HPA
kubectl get hpa reactapp-ui-hpa
# MIN: 3, MAX: 10, TARGET: 70% CPU
```

**Application URL**: http://86.50.229.25:30007

### How GitOps Works

1. **Developer** commits code → Triggers GitHub Actions
2. **GitHub Actions** builds image → Pushes to GHCR → Updates `deployment.yaml` with new SHA
3. **ArgoCD** polls repo every 3 minutes → Detects manifest change
4. **ArgoCD** applies changes → `kubectl apply -k k8s/reactapp/`
5. **Kubernetes** performs rolling update → Zero downtime
6. **ArgoCD UI** shows sync status → Green = Healthy & Synced

### ArgoCD UI Access

- **URL**: https://86.50.229.25:30008
- **Username**: `admin`
- **Password**: Check `.argocd-credentials` file
- **Features**: Visual topology, sync history, logs, manual sync, rollback

---

## 🌐 Accessing Services

### Application Access

**Public URL**: http://86.50.229.25:30007

Features:
- Newsletter signup with email validation
- Confetti celebration on submit
- Success message: "Congrats! You're on the waiting list"
- Animated shader background
- Fully responsive design

### ArgoCD Dashboard

**URL**: https://86.50.229.25:30008  
**Login**: `admin` / (password in `.argocd-credentials`)

Dashboard shows:
- Application health (Healthy/Progressing/Degraded)
- Sync status (Synced/OutOfSync)
- Resource tree (deployments, pods, services, HPA)
- Deployment history and logs

### SSH Access

```powershell
# Master node (public access)
ssh -i terraform/cpouta_key.pem ubuntu@86.50.229.25

# Worker node (via master as jump host)
ssh -J ubuntu@86.50.229.25 -i terraform/cpouta_key.pem ubuntu@192.168.1.11
```

### kubectl Commands

```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl get all

# Get pods with details
kubectl get pods -o wide

# Check pod logs
kubectl logs -l app=reactapp-ui --tail=50

# Check HPA metrics
kubectl get hpa
kubectl top pods  # Requires metrics-server

# Check ArgoCD application
kubectl get applications -n argocd

# Describe pod (troubleshooting)
kubectl describe pod <pod-name>

# Port forward for local testing
kubectl port-forward svc/react-app-service 8080:80
# Access: http://localhost:8080
```

### Container Registry

**GHCR URL**: https://github.com/Junaid-sadiq?tab=packages  
**Image**: `ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp:sha-{COMMIT_SHA}`

View all published images and their scan results.

---

## 🔍 Monitoring & Troubleshooting

### Check Application Health

```bash
# Pod status
kubectl get pods -l app=reactapp-ui
# All should be Running

# Service endpoints
kubectl get endpoints react-app-service
# Should show 3 pod IPs

# HPA status
kubectl get hpa reactapp-ui-hpa
# REPLICAS should be 3/3 (or scaled up if under load)

# Check pod logs
kubectl logs -l app=reactapp-ui --tail=100 -f

# Health check
curl http://86.50.229.25:30007/health
# Should return 200 OK
```

### Common Issues

**Issue**: Pods stuck in `ImagePullBackOff`
```bash
# Check image name (must be lowercase)
kubectl describe pod <pod-name> | grep Image

# Verify GHCR image exists
# Go to: https://github.com/Junaid-sadiq?tab=packages

# Fix: Ensure workflow uses lowercase username
# GitHub Actions: GITHUB_REPOSITORY_OWNER | tr '[:upper:]' '[:lower:]'
```

**Issue**: ArgoCD shows `OutOfSync`
```bash
# Check application status
kubectl get application reactapp -n argocd -o yaml

# Manual sync
kubectl patch application reactapp -n argocd -p '{"operation":{"sync":{"prune":true}}}' --type merge

# Or via UI: Click "Sync" → "Synchronize"
```

**Issue**: Deployment not updating
```bash
# Check if imagePullPolicy is set to Always
kubectl get deployment reactapp-ui -o yaml | grep imagePullPolicy
# Should show: imagePullPolicy: Always

# Force pod recreation
kubectl rollout restart deployment reactapp-ui
```

**Issue**: Cannot access application
```bash
# Check service
kubectl get svc react-app-service
# Type: NodePort, NodePort: 30007

# Check security group allows port 30007
# Verify in cPouta dashboard: k8s-public-secgroup

# Test from master node
curl http://localhost:30007
```

### Monitoring Commands

```bash
# Watch pod status
kubectl get pods -l app=reactapp-ui -w

# Watch HPA scaling
kubectl get hpa -w

# Resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods

# Events (recent cluster activity)
kubectl get events --sort-by='.lastTimestamp' | tail -20

# ArgoCD sync history
kubectl get application reactapp -n argocd -o jsonpath='{.status.history}'
```

### Load Testing (Trigger HPA)

```bash
# Generate load to test auto-scaling
# Install hey: https://github.com/rakyll/hey
hey -z 60s -c 50 http://86.50.229.25:30007

# Watch HPA scale up
kubectl get hpa -w
# REPLICAS will increase from 3 → 10 based on CPU
```

### Logs & Debugging

```bash
# Application logs
kubectl logs -l app=reactapp-ui --tail=200 -f

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Deployment events
kubectl describe deployment reactapp-ui

# Pod describe (shows pull errors, crashes, etc.)
kubectl describe pod <pod-name>
```

---

## 📁 Project Structure

```
multinode-gitops-cluster/
├── .github/workflows/           # CI/CD pipelines
│   ├── ci-build-simple.yml     # Main build & deploy workflow
│   └── pr-checks.yml           # PR validation checks
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                 # OpenStack resources
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── terraform.tfvars        # Credentials (gitignored)
│   └── .terraform/             # Terraform state & providers
├── k8s/reactapp/               # Kubernetes manifests
│   ├── deployment.yaml         # App deployment (3 replicas, HPA)
│   ├── service.yaml            # NodePort service (30007)
│   ├── hpa.yaml                # Horizontal Pod Autoscaler
│   ├── ingress.yaml            # Ingress resource (optional)
│   ├── argocd-application.yaml # ArgoCD app definition
│   └── kustomization.yaml      # Kustomize config
├── reactapp/                    # React application source
│   ├── src/                    # React components
│   │   ├── App.tsx            # Main app component
│   │   ├── components/        # UI components
│   │   └── assets/            # Images, SVGs
│   ├── public/                 # Static assets
│   │   └── favicon.svg        # Rocket favicon
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── nginx.conf              # Nginx configuration
│   ├── package.json            # Dependencies
│   └── vite.config.js          # Vite build config
├── deploy-k8s-cluster.ps1      # Automated deployment script
├── .argocd-credentials         # ArgoCD password (gitignored)
├── .gitignore                  # Git ignore rules
├── README.md                   # This file
└── SECURITY.md                 # Security policies
```

### Key Files

- **`deploy-k8s-cluster.ps1`** - One-command deployment automation
- **`ci-build-simple.yml`** - GitHub Actions workflow (build → push → update manifest)
- **`deployment.yaml`** - K8s deployment with `imagePullPolicy: Always`
- **`argocd-application.yaml`** - GitOps application config
- **`Dockerfile`** - Multi-stage build (Node build → Nginx runtime)
- **`terraform.tfvars`** - OpenStack credentials (create this manually)

---

## 🔒 Security

### Infrastructure Security

✅ **Network Segmentation**: Private network (192.168.1.0/24), public access only on master  
✅ **Security Groups**: Minimal port exposure (SSH, HTTP, HTTPS, K8s API, NodePort)  
✅ **SSH Key Auth**: Password auth disabled, key-based only  
✅ **Firewall Rules**: OpenStack security groups restrict traffic  
✅ **Private Worker**: Worker node has no public IP

### Application Security

✅ **Container Scanning**: Trivy scans all images for vulnerabilities  
✅ **Minimal Base Image**: Alpine Linux (~25MB, reduced attack surface)  
✅ **Non-Root User**: Nginx runs as non-root  
✅ **Security Headers**: CSP, X-Frame-Options, X-Content-Type-Options  
✅ **HTTPS Ready**: ArgoCD exposed with TLS (self-signed)  
✅ **Image Integrity**: SHA-tagged images ensure immutable deployments

### CI/CD Security

✅ **Secrets Management**: GitHub Secrets for GHCR token  
✅ **Least Privilege**: GHCR token has only `packages:write` scope  
✅ **Audit Trail**: All deployments tracked in Git history  
✅ **Automated Scanning**: Every image scanned before deployment  
✅ **GitOps Principles**: No direct kubectl access needed

### Best Practices

- 🔐 Rotate ArgoCD admin password after first login
- 🔐 Use GitHub PAT with minimal scopes
- 🔐 Never commit `terraform.tfvars` or `.argocd-credentials`
- 🔐 Review Trivy scan results in GitHub Actions logs
- 🔐 Enable ArgoCD RBAC for team access
- 🔐 Use network policies for pod-to-pod communication
- 🔐 Regular security updates: `kubectl set image deployment/reactapp-ui ...`

### Security Contacts

Report vulnerabilities: See [SECURITY.md](SECURITY.md)

---

## 🚀 Quick Reference

### Common Commands

```bash
# Deploy application via ArgoCD
kubectl apply -f k8s/reactapp/argocd-application.yaml

# Check deployment status
kubectl get pods,svc,hpa

# View application logs
kubectl logs -l app=reactapp-ui -f

# Manual sync (if ArgoCD shows OutOfSync)
kubectl patch application reactapp -n argocd -p '{"operation":{"sync":{"prune":true}}}' --type merge

# Scale manually (overrides HPA temporarily)
kubectl scale deployment reactapp-ui --replicas=5

# Rollback to previous version
kubectl rollout undo deployment reactapp-ui

# Check rollout history
kubectl rollout history deployment reactapp-ui

# Restart pods (useful for pulling new image)
kubectl rollout restart deployment reactapp-ui
```

### URLs

- **Application**: http://86.50.229.25:30007
- **ArgoCD UI**: https://86.50.229.25:30008
- **GitHub Repo**: https://github.com/Junaid-sadiq/multinode-gitops-cluster
- **GHCR Images**: https://github.com/Junaid-sadiq?tab=packages

### Credentials

- **ArgoCD**: `admin` / (see `.argocd-credentials`)
- **SSH**: `terraform/cpouta_key.pem` or `~/.ssh/pouta-dokploy-key`
- **GHCR**: GitHub PAT in `GHCR_TOKEN` secret

---

## 📖 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [k3s Documentation](https://docs.k3s.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CSC cPouta Documentation](https://docs.csc.fi/cloud/pouta/)
- [Terraform OpenStack Provider](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)

---

## 📝 License

This project is provided as-is for educational purposes.

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

**Built with ❤️ using Terraform, k3s, ArgoCD, and GitHub Actions**
