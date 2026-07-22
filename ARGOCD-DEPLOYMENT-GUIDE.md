# ArgoCD Deployment Guide

## Your ArgoCD Application Configuration

You already have a properly configured ArgoCD application manifest at:
```
k8s/reactapp/argocd-application.yaml
```

### Comparison: Your Config vs Proposed

#### ✅ Your Existing Configuration (CORRECT)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: reactapp-ui           # ✅ Matches your deployment name
  namespace: argocd            # ✅ ArgoCD namespace
spec:
  project: default
  source:
    repoURL: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
    targetRevision: main       # ✅ Tracks main branch
    path: k8s/reactapp         # ✅ Specific path to your app
  destination:
    server: https://kubernetes.default.svc
    namespace: reactapp        # ✅ Deploys to reactapp namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true   # ✅ Auto-creates namespace
```

#### ⚠️ Proposed Configuration (Needs Adjustment)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: reactapp              # ❌ Should be: reactapp-ui
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
    targetRevision: HEAD       # ⚠️ Should be: main (more explicit)
    path: k8s                  # ❌ Should be: k8s/reactapp (too broad)
  destination:
    server: https://kubernetes.default.svc
    namespace: default         # ❌ Should be: reactapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    # ❌ Missing: CreateNamespace=true
```

## Key Differences Explained

### 1. Application Name
```yaml
# Your config (CORRECT)
name: reactapp-ui    # Matches your deployment and service names

# Proposed
name: reactapp       # Generic, doesn't match resources
```
**Why yours is better**: Consistent with your Kubernetes resources (deployment: `reactapp-ui`, service: `react-app-service`)

### 2. Target Revision
```yaml
# Your config (BETTER)
targetRevision: main    # Explicit branch name

# Proposed
targetRevision: HEAD    # Points to default branch (works but less clear)
```
**Why yours is better**: Explicit and clear what branch you're tracking

### 3. Path
```yaml
# Your config (CORRECT)
path: k8s/reactapp      # Specific to your React app

# Proposed
path: k8s               # Would try to deploy ALL apps in k8s/
```
**Why yours is better**: Only deploys React app, not entire k8s directory

### 4. Destination Namespace
```yaml
# Your config (CORRECT)
namespace: reactapp     # Dedicated namespace

# Proposed
namespace: default      # Generic default namespace
```
**Why yours is better**: Isolation, better security, matches your service configuration

### 5. Sync Options
```yaml
# Your config (CORRECT)
syncOptions:
  - CreateNamespace=true    # Auto-creates reactapp namespace

# Proposed
# Missing this option      # Would require manual namespace creation
```
**Why yours is better**: Fully automated, no manual steps needed

## How to Deploy with ArgoCD

### Method 1: Apply the Manifest (Recommended)

```bash
# Apply your existing ArgoCD application
kubectl apply -f k8s/reactapp/argocd-application.yaml

# Expected output:
# application.argoproj.io/reactapp-ui created
```

### Method 2: Using ArgoCD CLI

```bash
argocd app create reactapp-ui \
  --repo https://github.com/Junaid-sadiq/multinode-gitops-cluster.git \
  --path k8s/reactapp \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace reactapp \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --sync-option CreateNamespace=true
```

### Method 3: Using ArgoCD Web UI

1. Open ArgoCD UI: `https://argocd.yourdomain.com`
2. Click "+ NEW APP"
3. Fill in:
   - **Application Name**: `reactapp-ui`
   - **Project**: `default`
   - **Sync Policy**: `Automatic`
   - **Repository URL**: `https://github.com/Junaid-sadiq/multinode-gitops-cluster.git`
   - **Revision**: `main`
   - **Path**: `k8s/reactapp`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `reactapp`
   - **Sync Options**: Check "Auto-Create Namespace"
4. Click "CREATE"

## Verification Steps

### Step 1: Check ArgoCD Application Status

```bash
# List applications
argocd app list

# Get detailed status
argocd app get reactapp-ui

# Expected output:
# Name:               reactapp-ui
# Project:            default
# Server:             https://kubernetes.default.svc
# Namespace:          reactapp
# URL:                https://argocd.yourdomain.com/applications/reactapp-ui
# Repo:               https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
# Target:             main
# Path:               k8s/reactapp
# SyncWindow:         Sync Allowed
# Sync Policy:        Automated (Prune)
# Sync Status:        Synced to main (cf57f5b)
# Health Status:      Healthy
```

### Step 2: Check Kubernetes Resources

```bash
# Check namespace
kubectl get namespace reactapp

# Check deployment
kubectl get deployment -n reactapp
# Expected: reactapp-ui with 3/3 READY

# Check pods
kubectl get pods -n reactapp
# Expected: 3 running pods

# Check service
kubectl get svc -n reactapp
# Expected: react-app-service (NodePort 30007)

# Check ingress
kubectl get ingress -n reactapp

# Check HPA
kubectl get hpa -n reactapp
```

### Step 3: Verify Auto-Sync

Make a change to test auto-sync:

```bash
# Edit deployment replica count locally
kubectl scale deployment reactapp-ui -n reactapp --replicas=5

# Wait ~30 seconds, ArgoCD will detect drift and heal
kubectl get deployment reactapp-ui -n reactapp
# Should show 3/3 again (self-healed)

# Check ArgoCD logs
argocd app get reactapp-ui
# Should show recent sync event
```

## ArgoCD GitOps Workflow

### How It Works

```
Developer Push → GitHub → GitHub Actions → Update Manifest → ArgoCD Detects → Deploy to K8s
```

Detailed flow:

1. **Developer pushes code** to `main` branch
   ```bash
   git push origin main
   ```

2. **GitHub Actions runs**
   - Builds Docker image
   - Tags with `sha-COMMIT_SHA`
   - Pushes to GHCR
   - Updates `k8s/reactapp/deployment.yaml` with new image
   - Commits changes back to repo

3. **ArgoCD detects change**
   - Polls repository every 3 minutes (default)
   - Detects updated `deployment.yaml`
   - Compares desired state vs actual state

4. **ArgoCD syncs**
   - Pulls new image from GHCR
   - Performs rolling update
   - Updates deployment
   - Verifies health

5. **Application updated**
   - Zero downtime
   - Gradual rollout
   - Automatic rollback on failure

### Sync Timing

- **Automatic sync interval**: 3 minutes (default)
- **Manual sync**: Immediate via CLI or UI
- **Webhook sync**: Immediate (if configured)

## Monitoring ArgoCD

### ArgoCD UI Dashboard

Access the ArgoCD UI to see:
- Application health status
- Sync status
- Resource tree view
- Deployment history
- Live logs

### CLI Monitoring

```bash
# Watch application status
watch argocd app get reactapp-ui

# View sync history
argocd app history reactapp-ui

# View recent logs
argocd app logs reactapp-ui --tail 100

# View specific resource logs
kubectl logs -n reactapp -l app=reactapp-ui --tail=100 -f
```

### Health Status Indicators

- **Healthy** ✅: All resources running correctly
- **Progressing** 🔄: Deployment in progress
- **Degraded** ⚠️: Some resources unhealthy
- **Suspended** ⏸️: Application suspended
- **Missing** ❌: Resources not found
- **Unknown** ❓: Health cannot be determined

### Sync Status Indicators

- **Synced** ✅: Git matches cluster
- **OutOfSync** ⚠️: Git differs from cluster
- **Unknown** ❓: Cannot determine sync status

## Troubleshooting

### Issue: Application Not Syncing

**Check 1: Repository Access**
```bash
# Verify ArgoCD can access repo
argocd repo list

# If not listed, add it
argocd repo add https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
```

**Check 2: Application Status**
```bash
argocd app get reactapp-ui

# Look for errors in "Conditions" section
```

**Check 3: Manual Sync**
```bash
# Force sync
argocd app sync reactapp-ui --force

# Sync with prune
argocd app sync reactapp-ui --prune
```

### Issue: Image Pull Errors

**Problem**: Pods stuck in `ImagePullBackOff`

**Solution**: Create GHCR image pull secret
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=Junaid-sadiq \
  --docker-password=YOUR_GITHUB_PAT \
  -n reactapp
```

Then update `deployment.yaml`:
```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: ghcr-secret
      containers:
        - name: reactapp-ui
          image: ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp:sha-xxx
```

### Issue: Health Check Failing

**Problem**: Application shows as "Degraded"

**Check 1: Pod Status**
```bash
kubectl get pods -n reactapp
kubectl describe pod <pod-name> -n reactapp
kubectl logs <pod-name> -n reactapp
```

**Check 2: Health Probes**
```bash
# Test readiness probe manually
kubectl exec -n reactapp <pod-name> -- wget -O- http://localhost:80/

# Check probe configuration
kubectl get deployment reactapp-ui -n reactapp -o yaml | grep -A 10 "livenessProbe"
```

### Issue: Sync Policy Not Working

**Problem**: Auto-sync not triggering

**Solution 1: Check Sync Policy**
```bash
argocd app get reactapp-ui -o yaml | grep -A 5 syncPolicy
```

**Solution 2: Manually Trigger Sync**
```bash
argocd app sync reactapp-ui
```

**Solution 3: Set Up Webhook** (Instant sync)
```bash
# In GitHub repo settings → Webhooks → Add webhook
# Payload URL: https://argocd.yourdomain.com/api/webhook
# Content type: application/json
# Events: Just the push event
```

## Advanced Configuration

### Sync Waves (Multi-App Deployment)

If you have dependencies (e.g., database before app):

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploys in wave 1
```

### Resource Hooks (Pre/Post Sync)

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync  # Runs before sync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

### Sync Windows (Maintenance Windows)

Prevent syncs during business hours:

```yaml
spec:
  syncPolicy:
    syncOptions:
      - AllowConcurrent=false
    syncWindows:
      - kind: allow
        schedule: '0 22 * * *'  # Only sync at 10 PM
        duration: 2h
```

### Ignore Differences

Ignore fields that change frequently:

```yaml
spec:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Ignore HPA changes
```

## Best Practices

### ✅ Do's

1. **Use specific paths**: `k8s/reactapp` not `k8s`
2. **Use dedicated namespaces**: `reactapp` not `default`
3. **Enable auto-prune**: Removes deleted resources
4. **Enable self-heal**: Automatically fixes drift
5. **Create namespace automatically**: `CreateNamespace=true`
6. **Use main branch**: Explicit target revision
7. **Monitor sync status**: Regular health checks

### ❌ Don'ts

1. **Don't use `default` namespace**: Poor isolation
2. **Don't use `HEAD`**: Use explicit branch names
3. **Don't disable auto-sync**: Defeats GitOps purpose
4. **Don't modify resources manually**: Use Git instead
5. **Don't use root path (`/`)**: Too broad scope
6. **Don't skip health checks**: Important for reliability

## Quick Commands Reference

```bash
# Create application
kubectl apply -f k8s/reactapp/argocd-application.yaml

# Check status
argocd app get reactapp-ui

# Sync manually
argocd app sync reactapp-ui

# View logs
argocd app logs reactapp-ui

# Delete application (keeps resources)
argocd app delete reactapp-ui

# Delete application and resources
argocd app delete reactapp-ui --cascade

# Refresh (detect changes)
argocd app refresh reactapp-ui

# Get sync history
argocd app history reactapp-ui

# Rollback to previous version
argocd app rollback reactapp-ui <history-id>
```

## Summary

### Your Current Configuration: ✅ EXCELLENT

Your existing `k8s/reactapp/argocd-application.yaml` is already properly configured with:

- ✅ Correct application name (`reactapp-ui`)
- ✅ Specific path (`k8s/reactapp`)
- ✅ Dedicated namespace (`reactapp`)
- ✅ Main branch tracking
- ✅ Auto-sync enabled
- ✅ Auto-prune enabled
- ✅ Self-heal enabled
- ✅ Namespace auto-creation

### To Deploy

Simply run:
```bash
kubectl apply -f k8s/reactapp/argocd-application.yaml
```

Then monitor:
```bash
argocd app get reactapp-ui
kubectl get pods -n reactapp -w
```

Your setup follows GitOps best practices! 🎯
