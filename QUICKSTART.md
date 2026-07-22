# Quick Start Guide

## Prerequisites

1. ✅ Terraform installed
2. ✅ OpenStack credentials in `terraform/terraform.tfvars`
3. ✅ PowerShell (Windows)

## Deploy Everything

```powershell
.\deploy-k8s-cluster.ps1
```

**That's it!** The script will:
- Provision 2 VMs on OpenStack
- Install k3s (Kubernetes)
- Set up worker node
- Install Argo CD
- Display all credentials

## Access Your Cluster

### Argo CD UI
- URL: Check `.argocd-credentials` file or script output
- Username: `admin`
- Password: In `.argocd-credentials` file

### SSH Access
```powershell
# Master node
ssh -i terraform\cpouta_key.pem ubuntu@<MASTER_IP>

# Worker node (via master)
ssh -i terraform\cpouta_key.pem -J ubuntu@<MASTER_IP> ubuntu@192.168.1.11
```

### Kubectl Commands
```bash
# SSH to master first
ssh -i terraform\cpouta_key.pem ubuntu@<MASTER_IP>

# Then run kubectl
kubectl get nodes
kubectl get pods -A
```

## Deployment Options

```powershell
# Standard deployment
.\deploy-k8s-cluster.ps1

# Destroy and rebuild everything
.\deploy-k8s-cluster.ps1 -DestroyFirst

# Skip Terraform (if VMs already exist)
.\deploy-k8s-cluster.ps1 -SkipTerraform
```

## Destroy Everything

```powershell
cd terraform
terraform destroy
```

## Troubleshooting

### Can't SSH to master?
```powershell
# Remove old SSH keys
ssh-keygen -R <MASTER_IP>

# Try again
ssh -i terraform\cpouta_key.pem ubuntu@<MASTER_IP>
```

### Want to redeploy?
```powershell
.\deploy-k8s-cluster.ps1 -DestroyFirst
```

### Check cluster status
```powershell
ssh -i terraform\cpouta_key.pem ubuntu@<MASTER_IP> "kubectl get nodes"
ssh -i terraform\cpouta_key.pem ubuntu@<MASTER_IP> "kubectl get pods -A"
```

## Important Files

- `deploy-k8s-cluster.ps1` - Main deployment script
- `.argocd-credentials` - All access credentials (gitignored)
- `terraform/cpouta_key.pem` - SSH private key (gitignored)
- `terraform/terraform.tfvars` - OpenStack credentials (gitignored)
- `README.md` - Full documentation

## Next Steps

1. ✅ Login to Argo CD
2. Configure your Git repository in Argo CD
3. Deploy your React application
4. Access it on NodePort 30007

## Ports Available

- **22** - SSH
- **80** - HTTP
- **443** - HTTPS
- **6443** - Kubernetes API
- **8080** - Argo CD Dashboard (direct)
- **30007** - React App NodePort (available for your app)
- **30008** - Argo CD NodePort (configured)
