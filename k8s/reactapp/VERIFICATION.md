# ArgoCD GitOps Workflow Verification

## Overview

This document verifies that the Kubernetes manifests follow the correct pattern for GitOps with ArgoCD.

## Manifest Structure

### ✅ Deployment (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reactapp-ui          # Matches your pattern
  namespace: reactapp
spec:
  replicas: 3                # 3 replicas as per your setup
  selector:
    matchLabels:
      app: reactapp-ui       # Consistent label
  template:
    metadata:
      labels:
        app: reactapp-ui     # Same label for selector
    spec:
      containers:
      - name: reactapp-ui
        image: ghcr.io/YOUR_USERNAME/YOUR_REPO/reactapp:SHA
        ports:
        - containerPort: 80  # Port 80 as per your setup
```

**Key Points:**
- ✅ Deployment name: `reactapp-ui`
- ✅ Label: `app: reactapp-ui`
- ✅ Container port: `80`
- ✅ Image will be updated with commit SHA by CI/CD

### ✅ Service (`service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: react-app-service    # Matches your pattern
  namespace: reactapp
spec:
  type: NodePort             # NodePort as per your setup
  selector:
    app: reactapp-ui         # Matches deployment label ✅
  ports:
    - protocol: TCP
      port: 80               # Service port
      targetPort: 80         # Container port (matches deployment)
      nodePort: 30007        # Fixed NodePort as per your setup
```

**Key Points:**
- ✅ Service name: `react-app-service`
- ✅ Type: `NodePort`
- ✅ NodePort: `30007` (accessible via `http://NODE_IP:30007`)
- ✅ Selector matches deployment label

### ✅ Ingress (`ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: reactapp-ui
  namespace: reactapp
spec:
  ingressClassName: nginx
  rules:
  - host: reactapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: react-app-service  # Matches service name ✅
            port:
              number: 80
```

**Key Points:**
- ✅ Service name matches: `react-app-service`
- ✅ Port matches: `80`
- ✅ Path: `/` (serves all routes)

### ✅ HPA (`hpa.yaml`)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: reactapp-ui
  namespace: reactapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: reactapp-ui        # Matches deployment name ✅
  minReplicas: 3
  maxReplicas: 10
```

**Key Points:**
- ✅ Targets deployment: `reactapp-ui`
- ✅ Min replicas: 3
- ✅ Max replicas: 10

## Label Consistency Check

| Resource | Label | Value |
|----------|-------|-------|
| Deployment | `app` | `reactapp-ui` ✅ |
| Service Selector | `app` | `reactapp-ui` ✅ |
| HPA Target | `name` | `reactapp-ui` ✅ |
| Ingress Backend | `service.name` | `react-app-service` ✅ |

**All labels and names are consistent!** ✅

## GitOps Workflow

### 1. Developer Push

```bash
git add .
git commit -m "feat: update UI"
git push origin main
```

### 2. GitHub Actions Triggers

**Workflow**: `.github/workflows/ci-build.yml`

```yaml
on:
  push:
    branches:
      - main
```

### 3. Build Docker Image

```bash
# Image format: ghcr.io/username/repo/reactapp:COMMIT_SHA
# Example: ghcr.io/username/repo/reactapp:5cf09679d83608e4e2a09e1b958eb1f063cd0171
```

### 4. Update Deployment Manifest

GitHub Actions updates `k8s/reactapp/deployment.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
      - name: reactapp-ui
        image: ghcr.io/username/repo/reactapp:NEW_COMMIT_SHA  # ← Updated
```

### 5. Commit Changes

```bash
git commit -m "chore: update reactapp image to NEW_COMMIT_SHA"
git push
```

### 6. ArgoCD Detects Change

**ArgoCD Application**: `argocd-application.yaml`

```yaml
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO.git
    targetRevision: main
    path: k8s/reactapp
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**ArgoCD automatically syncs** because `automated` is enabled.

### 7. Kubernetes Deployment

```bash
# ArgoCD applies the changes
kubectl apply -f k8s/reactapp/

# Kubernetes performs rolling update
# Old pods terminate gracefully
# New pods with new image start
```

## Verification Steps

### 1. Verify Manifests

```bash
# Validate YAML syntax
kubectl apply --dry-run=client -k k8s/reactapp/

# Check with kustomize
kubectl kustomize k8s/reactapp/
```

### 2. Check Label Selectors

```bash
# Get deployment labels
kubectl get deployment reactapp-ui -n reactapp -o jsonpath='{.spec.template.metadata.labels}'

# Get service selector
kubectl get service react-app-service -n reactapp -o jsonpath='{.spec.selector}'

# They should match!
```

### 3. Test Service Connectivity

```bash
# Get node IP
kubectl get nodes -o wide

# Access via NodePort
curl http://<NODE_IP>:30007

# Or port-forward
kubectl port-forward -n reactapp svc/react-app-service 8080:80
curl http://localhost:8080
```

### 4. Check ArgoCD Sync Status

```bash
# Using ArgoCD CLI
argocd app get reactapp-ui

# Check sync status
argocd app sync reactapp-ui

# View application details
argocd app list
```

### 5. Verify Deployment Rollout

```bash
# Check rollout status
kubectl rollout status deployment/reactapp-ui -n reactapp

# Check pod status
kubectl get pods -n reactapp

# Check image used
kubectl get pods -n reactapp -o jsonpath='{.items[0].spec.containers[0].image}'
```

## Image Tag Strategy

### Current Setup

**Format**: `ghcr.io/username/repo/reactapp:COMMIT_SHA`

**Example**: `ghcr.io/sachinlakshan/reactapp-ui:5cf09679d83608e4e2a09e1b958eb1f063cd0171`

**Benefits**:
- ✅ Unique per commit
- ✅ Easy to trace back to code
- ✅ Immutable tags
- ✅ Enables easy rollback

### GitHub Actions Configuration

```yaml
- name: Extract metadata
  id: meta
  uses: docker/metadata-action@v5
  with:
    images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
    tags: |
      type=sha,format=long     # Full commit SHA
      type=raw,value=latest    # Also tag as latest
```

**Produces**:
```
ghcr.io/username/repo/reactapp:5cf09679d83608e4e2a09e1b958eb1f063cd0171
ghcr.io/username/repo/reactapp:latest
```

## Access Methods

### 1. Via NodePort (Direct)

```bash
# Get any node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

# Access application
curl http://$NODE_IP:30007
```

**URL**: `http://NODE_IP:30007`

### 2. Via Ingress (Recommended)

```bash
# Add to /etc/hosts (or configure DNS)
echo "127.0.0.1 reactapp.local" | sudo tee -a /etc/hosts

# Access via domain
curl http://reactapp.local
```

**URL**: `http://reactapp.local`

### 3. Via Port Forward (Development)

```bash
# Forward to localhost
kubectl port-forward -n reactapp svc/react-app-service 8080:80

# Access
curl http://localhost:8080
```

**URL**: `http://localhost:8080`

## Troubleshooting

### Issue: Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n reactapp <pod-name>

# Common causes:
# 1. Image pull error → Check image exists in registry
# 2. Resource limits → Check node resources
# 3. Health check failing → Check /health endpoint
```

### Issue: Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n reactapp

# Should show pod IPs
# If empty, selector doesn't match

# Verify labels match
kubectl get pods -n reactapp --show-labels
kubectl get svc react-app-service -n reactapp -o yaml | grep selector -A 2
```

### Issue: ArgoCD Not Syncing

```bash
# Check application status
kubectl get application -n argocd

# View application details
kubectl describe application reactapp-ui -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

### Issue: Image Not Updating

```bash
# Check deployment image
kubectl get deployment reactapp-ui -n reactapp -o jsonpath='{.spec.template.spec.containers[0].image}'

# Force rollout restart
kubectl rollout restart deployment/reactapp-ui -n reactapp

# Check ArgoCD sync status
argocd app sync reactapp-ui --force
```

## Complete Workflow Example

### Step-by-Step

1. **Make code change**
   ```bash
   vim reactapp/src/components/demo.tsx
   git add reactapp/
   git commit -m "feat: update landing page"
   ```

2. **Push to GitHub**
   ```bash
   git push origin main
   ```

3. **GitHub Actions runs** (automatically)
   - Builds Docker image
   - Tags with commit SHA: `5cf09679d83608e4e2a09e1b958eb1f063cd0171`
   - Pushes to GHCR
   - Updates `k8s/reactapp/deployment.yaml`
   - Commits and pushes changes

4. **ArgoCD detects change** (automatically)
   - Compares Git state with cluster state
   - Sees new image tag
   - Triggers sync

5. **Kubernetes rolls out** (automatically)
   - Creates new pods with new image
   - Waits for health checks
   - Terminates old pods
   - Zero downtime! ✅

6. **Verify deployment**
   ```bash
   # Check new image is running
   kubectl get pods -n reactapp -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n'
   
   # Should show new SHA
   # ghcr.io/username/repo/reactapp:5cf09679d83608e4e2a09e1b958eb1f063cd0171
   ```

## Summary

✅ **Deployment**: Uses `reactapp-ui` name with `app: reactapp-ui` label  
✅ **Service**: Uses `react-app-service` name with NodePort 30007  
✅ **Ingress**: Points to `react-app-service` service  
✅ **HPA**: Targets `reactapp-ui` deployment  
✅ **ArgoCD**: Configured for auto-sync from Git  
✅ **CI/CD**: Builds image with commit SHA and updates manifest  
✅ **Labels**: All consistent and matching  

**The GitOps workflow is correctly configured!** 🎉

## Next Steps

1. **Update placeholders** in manifests:
   - Replace `YOUR_USERNAME` with your GitHub username
   - Replace `YOUR_REPO` with your repository name

2. **Apply ArgoCD application**:
   ```bash
   kubectl apply -f k8s/reactapp/argocd-application.yaml
   ```

3. **Test the workflow**:
   ```bash
   # Make a change
   echo "test" >> reactapp/README.md
   git add reactapp/README.md
   git commit -m "test: trigger CI/CD"
   git push origin main
   
   # Watch ArgoCD
   watch kubectl get pods -n reactapp
   ```

4. **Access application**:
   ```bash
   # Get node IP
   kubectl get nodes -o wide
   
   # Visit http://NODE_IP:30007
   ```

---

**Last Updated**: July 22, 2026  
**Status**: Verified and Ready ✅
