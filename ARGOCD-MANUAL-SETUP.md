# ArgoCD Manual Setup Guide (Without CLI)

## Overview

You can add your application to ArgoCD **3 ways without installing CLI tools**:

1. ✅ **Via ArgoCD Web UI** (Easiest - Recommended)
2. ✅ **Via Kubernetes Dashboard**
3. ✅ **Via Git Push** (Automated)

---

## Method 1: ArgoCD Web UI (Recommended - No CLI Needed!)

### Step 1: Access ArgoCD Web UI

First, you need to access the ArgoCD web interface. This depends on how ArgoCD is installed:

#### Option A: Using Port Forward (If you have kubectl)
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open: `http://localhost:8080`

#### Option B: Using NodePort (If ArgoCD exposed via NodePort)
```
http://NODE_IP:NODEPORT
```

#### Option C: Using Ingress (If ArgoCD has ingress configured)
```
https://argocd.yourdomain.com
```

#### Option D: Ask Your Cluster Admin
Ask for the ArgoCD URL from whoever set up your cluster.

### Step 2: Login to ArgoCD

**Default Credentials**:
- **Username**: `admin`
- **Password**: Get from your cluster admin, or if you have kubectl:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

### Step 3: Create Application in UI

Once logged in:

1. **Click "+ NEW APP"** button (top left)

2. **Fill in General Settings**:
   - **Application Name**: `reactapp-ui`
   - **Project Name**: `default`
   - **Sync Policy**: Select `Automatic`
     - ☑️ Check "PRUNE RESOURCES"
     - ☑️ Check "SELF HEAL"

3. **Fill in Source Settings**:
   - **Repository URL**: `https://github.com/Junaid-sadiq/multinode-gitops-cluster.git`
   - **Revision**: `main`
   - **Path**: `k8s/reactapp`

4. **Fill in Destination Settings**:
   - **Cluster URL**: Select `https://kubernetes.default.svc` (in-cluster)
   - **Namespace**: `reactapp`

5. **Sync Options** (expand this section):
   - ☑️ Check "AUTO-CREATE NAMESPACE"

6. **Click "CREATE"** button at the top

### Step 4: Verify Application Created

You should see your application in the ArgoCD UI:
- **Name**: reactapp-ui
- **Status**: Should show "OutOfSync" initially
- **Health**: Should show "Progressing" or "Healthy"

### Step 5: Sync the Application

If auto-sync doesn't trigger immediately:
1. Click on the `reactapp-ui` application card
2. Click "SYNC" button at the top
3. Click "SYNCHRONIZE" in the dialog

**That's it!** ArgoCD will now:
- Deploy your application to Kubernetes
- Monitor your GitHub repo for changes
- Auto-sync every time you push updates

---

## Method 2: Kubernetes Dashboard (Alternative)

If your cluster has Kubernetes Dashboard installed:

### Step 1: Access Kubernetes Dashboard

Get the dashboard URL from your cluster admin or:
```bash
kubectl proxy
```
Then open: `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`

### Step 2: Upload YAML File

1. Click the **"+" icon** (top right) to create resources
2. Click **"CREATE FROM FILE"** tab
3. Click **"UPLOAD FILE"**
4. Navigate to: `k8s/reactapp/argocd-application.yaml`
5. Click **"UPLOAD"**

Or paste the content directly:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: reactapp-ui
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
    targetRevision: main
    path: k8s/reactapp
  destination:
    server: https://kubernetes.default.svc
    namespace: reactapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

6. Click **"UPLOAD"**

---

## Method 3: Via Git Push (Fully Automated)

This is the **"GitOps way"** - ArgoCD watches a Git repo and automatically deploys!

### Prerequisites

Your ArgoCD must be configured with **App of Apps pattern** or have a bootstrap app.

### Steps

1. **Your file is already in Git**: `k8s/reactapp/argocd-application.yaml`

2. **Create an ArgoCD bootstrap application** (one-time setup by admin):

   Have your cluster admin create this bootstrap app in ArgoCD:

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: bootstrap
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
       targetRevision: main
       path: k8s/reactapp
       directory:
         recurse: false
         include: 'argocd-application.yaml'
     destination:
       server: https://kubernetes.default.svc
       namespace: argocd
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```

3. **Push your changes** to GitHub (already done!)

4. **ArgoCD automatically discovers** `argocd-application.yaml` and creates your app!

---

## Without Any Tools? Ask Your Admin!

If you don't have access to:
- ❌ ArgoCD Web UI
- ❌ Kubernetes Dashboard  
- ❌ kubectl CLI
- ❌ ArgoCD CLI

Then you need to **ask your Kubernetes cluster administrator** to:

### Option 1: Apply Your File
Send them the file location and ask them to run:
```bash
kubectl apply -f k8s/reactapp/argocd-application.yaml
```

### Option 2: Create via UI
Give them this information to create the app in ArgoCD UI:

```
Application Name: reactapp-ui
Project: default
Sync Policy: Automatic (with prune and self-heal)
Repository: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
Revision: main
Path: k8s/reactapp
Cluster: https://kubernetes.default.svc
Namespace: reactapp
Sync Options: Create namespace
```

---

## Installing Tools (Optional for Future)

### Install kubectl (Windows)

**Using Chocolatey**:
```powershell
choco install kubernetes-cli
```

**Using PowerShell (Manual)**:
```powershell
# Download kubectl
curl.exe -LO "https://dl.k8s.io/release/v1.31.0/bin/windows/amd64/kubectl.exe"

# Move to a directory in your PATH
Move-Item .\kubectl.exe C:\Windows\System32\kubectl.exe

# Verify
kubectl version --client
```

**Using winget**:
```powershell
winget install Kubernetes.kubectl
```

### Install ArgoCD CLI (Windows)

**Using Chocolatey**:
```powershell
choco install argocd-cli
```

**Using PowerShell (Manual)**:
```powershell
# Download latest version
$version = (Invoke-RestMethod https://api.github.com/repos/argoproj/argo-cd/releases/latest).tag_name
$url = "https://github.com/argoproj/argo-cd/releases/download/$version/argocd-windows-amd64.exe"
Invoke-WebRequest -Uri $url -OutFile argocd.exe

# Move to PATH
Move-Item .\argocd.exe C:\Windows\System32\argocd.exe

# Verify
argocd version --client
```

### Configure kubectl (After Installation)

You need a **kubeconfig file** from your cluster admin:

```powershell
# Place kubeconfig in default location
mkdir ~/.kube
# Copy kubeconfig file from admin to: ~/.kube/config

# Test connection
kubectl get nodes
```

### Login to ArgoCD (After Installation)

```bash
# Port forward (if needed)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login
argocd login localhost:8080

# Or login to external ArgoCD
argocd login argocd.yourdomain.com
```

---

## Your File Location

Your `argocd-application.yaml` is located at:

```
📁 multi-node-gitops-cluster/
  └── 📁 k8s/
      └── 📁 reactapp/
          ├── argocd-application.yaml  ← HERE!
          ├── deployment.yaml
          ├── service.yaml
          ├── ingress.yaml
          ├── hpa.yaml
          ├── namespace.yaml
          └── kustomization.yaml
```

**Full path**: 
```
c:\Users\dauds\Documents\New Folder\multi-node-gitops-cluster\k8s\reactapp\argocd-application.yaml
```

**In Git**:
```
https://github.com/Junaid-sadiq/multinode-gitops-cluster/blob/main/k8s/reactapp/argocd-application.yaml
```

---

## File Content (For Copy-Paste)

If you need to copy-paste into ArgoCD UI or send to admin:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: reactapp-ui
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git
    targetRevision: main
    path: k8s/reactapp
  destination:
    server: https://kubernetes.default.svc
    namespace: reactapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Verification (After Adding to ArgoCD)

### Via ArgoCD Web UI

1. Open ArgoCD UI
2. You should see `reactapp-ui` application card
3. Click on it to see:
   - **Sync Status**: Should be "Synced" (green)
   - **Health Status**: Should be "Healthy" (green)
   - **Resources**: Should show all your Kubernetes resources (deployment, service, etc.)

### Via Web Browser

Access your application:
```
http://NODE_IP:30007
```

You should see your React app with the shader animation!

### Ask Your Admin to Check

Ask them to run:
```bash
# Check ArgoCD application
kubectl get application -n argocd

# Check deployed resources
kubectl get all -n reactapp

# Check service
kubectl get svc react-app-service -n reactapp
```

---

## Quick Reference Card

### ArgoCD Application Details

| Field | Value |
|-------|-------|
| **Application Name** | `reactapp-ui` |
| **Project** | `default` |
| **Repository** | `https://github.com/Junaid-sadiq/multinode-gitops-cluster.git` |
| **Branch** | `main` |
| **Path** | `k8s/reactapp` |
| **Destination Cluster** | `https://kubernetes.default.svc` |
| **Namespace** | `reactapp` |
| **Sync Policy** | Automatic |
| **Auto-Prune** | Enabled |
| **Self-Heal** | Enabled |
| **Create Namespace** | Enabled |

### Access Points

| Resource | Location |
|----------|----------|
| **Source YAML** | `k8s/reactapp/argocd-application.yaml` |
| **GitHub URL** | `https://github.com/Junaid-sadiq/multinode-gitops-cluster` |
| **Application URL** | `http://NODE_IP:30007` |
| **ArgoCD UI** | Ask your admin |

---

## Troubleshooting

### Can't Access ArgoCD UI

**Problem**: Don't know ArgoCD URL

**Solution**: Ask your cluster administrator for:
- ArgoCD URL
- Username and password
- Or ask them to create the application for you

### Can't Install Tools

**Problem**: No admin rights on Windows

**Solution**: 
1. Use ArgoCD Web UI (no installation needed)
2. Ask your admin to create the application
3. Use Kubernetes Dashboard
4. Use portable versions of tools (no installation required)

### Don't Have Cluster Access

**Problem**: No kubeconfig file

**Solution**:
1. Ask your cluster admin for access
2. Or ask them to deploy the application
3. Share the `argocd-application.yaml` file with them

---

## Summary

### Easiest Methods (No CLI Required)

1. **🥇 ArgoCD Web UI** - Just copy-paste values
2. **🥈 Ask Admin** - Send them the file location
3. **🥉 Kubernetes Dashboard** - Upload YAML file

### Your File is Ready!

✅ File exists: `k8s/reactapp/argocd-application.yaml`
✅ Already in Git: `https://github.com/Junaid-sadiq/multinode-gitops-cluster`
✅ Properly configured for your application
✅ Ready to deploy!

**Next Step**: Use ArgoCD Web UI to create the application, or ask your admin to apply the file!
