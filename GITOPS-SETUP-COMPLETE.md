# ✅ GitOps Setup Complete

## What Was Updated

I've updated all Kubernetes manifests to match your working pattern:

### Resource Names (Updated)

| Resource | Old Name | New Name |
|----------|----------|----------|
| Deployment | `reactapp` | `reactapp-ui` ✅ |
| Service | `reactapp` | `react-app-service` ✅ |
| Service Type | `ClusterIP` | `NodePort` ✅ |
| NodePort | N/A | `30007` ✅ |
| Label | `app: reactapp` | `app: reactapp-ui` ✅ |

### Image Tag Strategy

**Format**: `ghcr.io/username/repo/reactapp:COMMIT_SHA`

**Example**: `ghcr.io/sachinlakshan/reactapp-ui:5cf09679d83608e4e2a09e1b958eb1f063cd0171`

## Updated Files

```
k8s/reactapp/
├── deployment.yaml        ✅ Updated - uses reactapp-ui
├── service.yaml           ✅ Updated - NodePort 30007
├── ingress.yaml           ✅ Updated - points to react-app-service
├── hpa.yaml               ✅ Updated - targets reactapp-ui
├── kustomization.yaml     ✅ Updated - consistent labels
├── argocd-application.yaml ✅ Updated - simplified
└── VERIFICATION.md        ✅ New - complete workflow guide

.github/workflows/
└── ci-build.yml           ✅ Updated - uses commit SHA as tag
```

## GitOps Workflow

```
Developer Push → GitHub Actions → Build Image → Update Manifest → ArgoCD → K8s Deploy
      ↓              ↓                ↓              ↓             ↓          ↓
   git push      ci-build.yml     Docker Build   deployment.yaml  Sync   Rolling Update
    main                           + Push GHCR     (auto-commit)                
```

## Quick Start

### 1. Update Placeholders

```bash
cd k8s/reactapp

# Replace YOUR_USERNAME and YOUR_REPO
sed -i 's/YOUR_USERNAME/your-github-username/g' *.yaml
sed -i 's/YOUR_REPO/your-repo-name/g' *.yaml

# Also update in .github/workflows/ci-build.yml
```

### 2. Deploy with kubectl

```bash
# Apply all manifests
kubectl apply -k k8s/reactapp/

# Verify deployment
kubectl get pods -n reactapp
kubectl get svc -n reactapp
```

### 3. Deploy with ArgoCD

```bash
# Apply ArgoCD application
kubectl apply -f k8s/reactapp/argocd-application.yaml

# Check status
argocd app get reactapp-ui

# Or via kubectl
kubectl get application -n argocd
```

### 4. Access Application

**Via NodePort**:
```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

# Access app
curl http://$NODE_IP:30007
# Or open in browser: http://NODE_IP:30007
```

**Via Ingress** (if configured):
```bash
# Add to /etc/hosts
echo "127.0.0.1 reactapp.local" | sudo tee -a /etc/hosts

# Access
curl http://reactapp.local
```

**Via Port Forward**:
```bash
kubectl port-forward -n reactapp svc/react-app-service 8080:80
# Access: http://localhost:8080
```

## Test the Workflow

### Trigger CI/CD

```bash
# Make a change
echo "# Test" >> reactapp/README.md

# Commit and push
git add reactapp/README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

### Watch the Process

**Terminal 1 - GitHub Actions**:
```bash
gh run watch
```

**Terminal 2 - Kubernetes Pods**:
```bash
watch kubectl get pods -n reactapp
```

**Terminal 3 - ArgoCD**:
```bash
watch argocd app get reactapp-ui
```

### Expected Flow

1. **GitHub Actions starts** (~2 min)
   - Builds Docker image
   - Tags with commit SHA
   - Pushes to GHCR
   - Updates deployment.yaml
   - Commits changes

2. **ArgoCD detects change** (~30 sec)
   - Compares Git vs Cluster
   - Sees new image tag
   - Starts sync

3. **Kubernetes rolls out** (~1-2 min)
   - Creates new pods
   - Health checks pass
   - Removes old pods
   - **Zero downtime!** ✅

4. **Application updated** ✅
   ```bash
   kubectl get pods -n reactapp -o jsonpath='{.items[*].spec.containers[*].image}'
   # Should show new SHA
   ```

## Verification Checklist

- [ ] Deployment name is `reactapp-ui`
- [ ] Service name is `react-app-service`
- [ ] Service type is `NodePort`
- [ ] NodePort is `30007`
- [ ] Labels are `app: reactapp-ui`
- [ ] Service selector matches deployment labels
- [ ] Ingress points to `react-app-service`
- [ ] HPA targets `reactapp-ui`
- [ ] Image uses commit SHA as tag
- [ ] ArgoCD auto-sync is enabled
- [ ] GitHub Actions workflow is active

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your GitHub Repository                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ React Source │  │  Dockerfile  │  │  K8s Manifests│     │
│  │   /reactapp  │  │   nginx.conf │  │  /k8s/reactapp│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└──────────────────────┬──────────────────────────────────────┘
                       │
            Push to main branch
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions (ci-build.yml)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Build Image  │→ │  Push GHCR   │→ │Update Manifest│     │
│  │  (with SHA)  │  │              │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         GitHub Container Registry (ghcr.io)                  │
│                                                              │
│  ghcr.io/username/repo/reactapp:5cf09679d83608...          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ ArgoCD pulls
                       │ new manifest
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                        ArgoCD                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Detect Change│→ │  Sync State  │→ │    Apply     │     │
│  │              │  │              │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Ingress    │→ │   Service    │→ │  Deployment  │     │
│  │              │  │  NodePort    │  │  3-10 Pods   │     │
│  │              │  │   30007      │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
              Your Application Live! 🎉
              http://NODE_IP:30007
```

## Resource Configuration

### Deployment

```yaml
name: reactapp-ui
replicas: 3 (auto-scales to 10)
image: ghcr.io/username/repo/reactapp:COMMIT_SHA
port: 80
resources:
  requests: {cpu: 100m, memory: 128Mi}
  limits: {cpu: 500m, memory: 256Mi}
health:
  liveness: /health
  readiness: /health
```

### Service

```yaml
name: react-app-service
type: NodePort
selector: app=reactapp-ui
port: 80
targetPort: 80
nodePort: 30007
```

### Ingress

```yaml
name: reactapp-ui
host: reactapp.local
backend: react-app-service:80
path: /
```

### HPA

```yaml
name: reactapp-ui
target: deployment/reactapp-ui
min: 3 replicas
max: 10 replicas
cpu: 70%
memory: 80%
```

## Monitoring

### Check Deployment Status

```bash
# All resources
kubectl get all -n reactapp

# Just pods
kubectl get pods -n reactapp

# Pod details
kubectl describe pod -n reactapp <pod-name>

# Logs
kubectl logs -n reactapp -l app=reactapp-ui -f
```

### Check ArgoCD Status

```bash
# Application status
argocd app get reactapp-ui

# Application logs
argocd app logs reactapp-ui -f

# Sync history
argocd app history reactapp-ui
```

### Check Image Tags

```bash
# Current image in deployment
kubectl get deployment reactapp-ui -n reactapp \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Images in running pods
kubectl get pods -n reactapp \
  -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n'
```

## Troubleshooting

### Problem: Pods Pending

```bash
kubectl describe pod -n reactapp <pod-name>
# Look for: "Insufficient cpu" or "Insufficient memory"
# Solution: Scale down or increase node resources
```

### Problem: Image Pull Error

```bash
kubectl describe pod -n reactapp <pod-name>
# Look for: "Failed to pull image"
# Solution: Check image exists in GHCR and permissions
```

### Problem: Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n reactapp

# Should list pod IPs
# If empty, labels don't match

# Verify
kubectl get pods -n reactapp --show-labels
kubectl get svc react-app-service -n reactapp -o yaml
```

### Problem: ArgoCD Not Syncing

```bash
# Check application
kubectl get application -n argocd

# Force sync
argocd app sync reactapp-ui --force

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## Documentation

| File | Description |
|------|-------------|
| [k8s/reactapp/VERIFICATION.md](k8s/reactapp/VERIFICATION.md) | Complete workflow verification |
| [reactapp/DEPLOYMENT.md](reactapp/DEPLOYMENT.md) | Full deployment guide |
| [reactapp/DOCKER.md](reactapp/DOCKER.md) | Docker documentation |
| [.github/workflows/README.md](.github/workflows/README.md) | CI/CD documentation |

## Success Criteria

✅ Manifests updated to match your pattern  
✅ Labels are consistent across all resources  
✅ Service selector matches deployment labels  
✅ NodePort configured on port 30007  
✅ Image uses commit SHA as tag  
✅ CI/CD workflow builds and updates manifest  
✅ ArgoCD configured for auto-sync  
✅ Complete documentation provided  

## Next Steps

1. **Update placeholders** (YOUR_USERNAME, YOUR_REPO)
2. **Push to GitHub** to trigger CI/CD
3. **Apply ArgoCD application** (or use kubectl)
4. **Access application** via NodePort (30007)
5. **Monitor deployment** and verify workflow

---

**Status**: ✅ Complete and Ready for Deployment  
**Last Updated**: July 22, 2026

🎉 Your GitOps pipeline is ready!
