# React App Kubernetes Deployment

## Overview

This directory contains Kubernetes manifests for deploying the React application using GitOps with ArgoCD.

## Architecture

```
┌─────────────────┐
│   GitHub Repo   │
│  (Source Code)  │
└────────┬────────┘
         │
         │ Push to main
         ▼
┌─────────────────┐
│ GitHub Actions  │
│   CI Pipeline   │
└────────┬────────┘
         │
         │ Build & Push
         ▼
┌─────────────────┐
│ Container Reg   │
│ (ghcr.io)       │
└────────┬────────┘
         │
         │ Update manifest
         ▼
┌─────────────────┐
│ GitOps Repo     │
│ (k8s/reactapp)  │
└────────┬────────┘
         │
         │ Sync
         ▼
┌─────────────────┐
│    ArgoCD       │
└────────┬────────┘
         │
         │ Deploy
         ▼
┌─────────────────┐
│  K8s Cluster    │
│  (reactapp ns)  │
└─────────────────┘
```

## Manifests

- **namespace.yaml** - Dedicated namespace for isolation
- **deployment.yaml** - Application deployment with 3 replicas
- **service.yaml** - ClusterIP service
- **ingress.yaml** - HTTPS ingress with TLS
- **hpa.yaml** - Horizontal Pod Autoscaler (3-10 replicas)
- **kustomization.yaml** - Kustomize configuration
- **argocd-application.yaml** - ArgoCD Application CRD

## Prerequisites

1. Kubernetes cluster (v1.24+)
2. ArgoCD installed
3. NGINX Ingress Controller
4. cert-manager (for TLS certificates)
5. GitHub Container Registry access

## Quick Start

### 1. Update Configuration

Replace placeholders in the manifests:

```bash
# In all files, replace:
YOUR_USERNAME → your-github-username
YOUR_REPO → your-repo-name
reactapp.example.com → your-actual-domain.com
```

### 2. Deploy with ArgoCD

```bash
# Apply the ArgoCD Application
kubectl apply -f argocd-application.yaml

# Or use ArgoCD CLI
argocd app create reactapp \
  --repo https://github.com/YOUR_USERNAME/YOUR_REPO.git \
  --path k8s/reactapp \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace reactapp \
  --sync-policy automated
```

### 3. Manual Deployment (without ArgoCD)

```bash
# Using Kustomize
kubectl apply -k .

# Or apply manifests directly
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

## Configuration

### Environment Variables

Add environment variables in `kustomization.yaml`:

```yaml
configMapGenerator:
  - name: reactapp-config
    literals:
      - NODE_ENV=production
      - API_URL=https://api.example.com
```

### Resource Limits

Current settings in `deployment.yaml`:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

Adjust based on your needs.

### Scaling

**Manual scaling:**
```bash
kubectl scale deployment reactapp -n reactapp --replicas=5
```

**Auto-scaling** (HPA):
- Min: 3 replicas
- Max: 10 replicas
- CPU target: 70%
- Memory target: 80%

## Monitoring

### Check Deployment Status

```bash
# Get all resources
kubectl get all -n reactapp

# Check pods
kubectl get pods -n reactapp

# Check deployment
kubectl describe deployment reactapp -n reactapp

# Check HPA status
kubectl get hpa -n reactapp
```

### View Logs

```bash
# All pods
kubectl logs -n reactapp -l app=reactapp --tail=100 -f

# Specific pod
kubectl logs -n reactapp <pod-name> -f

# Previous pod (if crashed)
kubectl logs -n reactapp <pod-name> --previous
```

### Health Checks

```bash
# Check readiness
kubectl get pods -n reactapp

# Test health endpoint
kubectl port-forward -n reactapp svc/reactapp 8080:80
curl http://localhost:8080/health
```

## Troubleshooting

### Pods not starting

```bash
# Check pod events
kubectl describe pod -n reactapp <pod-name>

# Check image pull
kubectl get events -n reactapp --sort-by='.lastTimestamp'
```

### Image pull errors

Ensure GitHub Container Registry authentication:

```bash
# Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PAT \
  -n reactapp

# Add to deployment
spec:
  template:
    spec:
      imagePullSecrets:
      - name: ghcr-secret
```

### Ingress not working

```bash
# Check ingress
kubectl describe ingress reactapp -n reactapp

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check TLS certificate
kubectl get certificate -n reactapp
kubectl describe certificate reactapp-tls -n reactapp
```

## Security

### Pod Security

The deployment includes:
- Non-root user (UID 101)
- Read-only root filesystem
- Dropped capabilities
- No privilege escalation

### Network Policies

Create a network policy to restrict traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: reactapp-netpol
  namespace: reactapp
spec:
  podSelector:
    matchLabels:
      app: reactapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53
```

## Backup & Recovery

### Backup

```bash
# Export all manifests
kubectl get all -n reactapp -o yaml > reactapp-backup.yaml

# Backup with Velero
velero backup create reactapp-backup --include-namespaces reactapp
```

### Recovery

```bash
# Restore from backup
kubectl apply -f reactapp-backup.yaml

# Restore with Velero
velero restore create --from-backup reactapp-backup
```

## Updates & Rollbacks

### Rolling Update

Updates are automatic via GitOps:
1. Push code to main branch
2. GitHub Actions builds new image
3. Updates manifest with new tag
4. ArgoCD syncs changes
5. Kubernetes rolls out update

### Manual Rollback

```bash
# Check rollout history
kubectl rollout history deployment/reactapp -n reactapp

# Rollback to previous version
kubectl rollout undo deployment/reactapp -n reactapp

# Rollback to specific revision
kubectl rollout undo deployment/reactapp -n reactapp --to-revision=2
```

## Cost Optimization

### Resource Right-sizing

Monitor actual usage:

```bash
kubectl top pods -n reactapp
kubectl top nodes
```

Adjust requests/limits based on metrics.

### Cluster Autoscaling

Enable cluster autoscaler for node-level scaling based on HPA demands.

## CI/CD Integration

See `.github/workflows/` for:
- **pr-checks.yml** - Runs on pull requests
- **ci-build.yml** - Builds and deploys on main branch

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
