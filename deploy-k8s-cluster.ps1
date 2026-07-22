# ============================================
# Complete k8s + Argo CD Deployment Script
# ============================================
# This script provisions and configures a complete k3s cluster with Argo CD
# on CSC cPouta OpenStack
#
# Usage: .\deploy-k8s-cluster.ps1 [-DestroyFirst] [-SkipTerraform]
# ============================================

param(
    [switch]$DestroyFirst,
    [switch]$SkipTerraform
)

$ErrorActionPreference = "Continue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "k8s GitOps Cluster Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 1: Terraform Infrastructure
# ============================================
if (-not $SkipTerraform) {
    if ($DestroyFirst) {
        Write-Host "[STEP 1a] Destroying existing infrastructure..." -ForegroundColor Yellow
        Set-Location "terraform"
        terraform destroy -auto-approve
        Set-Location ".."
        Write-Host ""
    }

    Write-Host "[STEP 1] Provisioning infrastructure with Terraform..." -ForegroundColor Cyan
    Set-Location "terraform"
    
    if (-not (Test-Path ".terraform")) {
        Write-Host "-> Running terraform init..." -ForegroundColor Yellow
        terraform init
    }
    
    Write-Host "-> Running terraform apply..." -ForegroundColor Yellow
    terraform apply -auto-approve
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform apply failed!"
        Set-Location ".."
        exit 1
    }
    
    Set-Location ".."
    Write-Host "✓ Infrastructure provisioned!" -ForegroundColor Green
    Write-Host "Waiting 30 seconds for instances to boot..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    Write-Host ""
} else {
    Write-Host "[STEP 1] Skipping Terraform (infrastructure already exists)" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# Get Infrastructure Details
# ============================================
Write-Host "Getting infrastructure details from Terraform..." -ForegroundColor Yellow
$MasterIP = (terraform -chdir="terraform" output -raw master_public_ip 2>$null)
$SSHKeyPath = "terraform\cpouta_key.pem"

if (-not $MasterIP) {
    Write-Error "Could not get Master IP from Terraform!"
    exit 1
}

Write-Host "Master IP: $MasterIP" -ForegroundColor Green
Write-Host "SSH Key: $SSHKeyPath" -ForegroundColor Green
Write-Host ""

# Remove old SSH host keys
Write-Host "Cleaning up old SSH host keys..." -ForegroundColor Yellow
ssh-keygen -R $MasterIP 2>$null
ssh-keygen -R 192.168.1.11 2>$null
Write-Host ""

# ============================================
# STEP 2: Install k3s on Master
# ============================================
Write-Host "[STEP 2] Setting up k3s on master node..." -ForegroundColor Cyan

Write-Host "-> Updating system packages" -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP "sudo apt update && sudo apt upgrade -y"

Write-Host "-> Installing Docker" -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP "sudo apt install -y docker.io docker-compose && sudo systemctl start docker && sudo systemctl enable docker && sudo usermod -aG docker ubuntu"

Write-Host "-> Configuring system for Kubernetes" -ForegroundColor Yellow
$sysConfig = "sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab && sudo modprobe overlay && sudo modprobe br_netfilter && echo -e 'overlay\nbr_netfilter' | sudo tee /etc/modules-load.d/k8s.conf && echo -e 'net.bridge.bridge-nf-call-iptables = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/k8s.conf && sudo sysctl --system"
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $sysConfig

Write-Host "-> Installing k3s" -ForegroundColor Yellow
$k3sInstall = "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --write-kubeconfig-mode=644 --disable=traefik' sh -s -"
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $k3sInstall

Write-Host "Waiting 60 seconds for k3s to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host "-> Setting up kubectl for ubuntu user" -ForegroundColor Yellow
$kubeconfigSetup = "mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config && chmod 600 ~/.kube/config"
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $kubeconfigSetup

Write-Host "-> Verifying k3s installation" -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP "kubectl get nodes"

Write-Host "✓ k3s master node ready!" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 3: Add Worker Node
# ============================================
Write-Host "[STEP 3] Setting up worker node..." -ForegroundColor Cyan

Write-Host "-> Getting k3s token" -ForegroundColor Yellow
$k3sToken = ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP "sudo cat /var/lib/rancher/k3s/server/node-token"

Write-Host "-> Copying SSH key to master for worker access" -ForegroundColor Yellow
$keyContent = Get-Content $SSHKeyPath -Raw
$setupSSH = @"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat > ~/.ssh/worker_key <<'EOFKEY'
$keyContent
EOFKEY
chmod 600 ~/.ssh/worker_key
"@
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $setupSSH

Write-Host "-> Installing k3s agent on worker" -ForegroundColor Yellow
$installWorker = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/worker_key ubuntu@192.168.1.11 'curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.10:6443 K3S_TOKEN=$k3sToken sh -s - agent'"
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $installWorker

Write-Host "Waiting 30 seconds for worker to join..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "-> Verifying worker joined cluster" -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP "kubectl get nodes"

Write-Host "✓ Worker node joined cluster!" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 4: Install Argo CD
# ============================================
Write-Host "[STEP 4] Installing Argo CD..." -ForegroundColor Cyan

Write-Host "-> Creating argocd namespace and installing" -ForegroundColor Yellow
$argocdInstall = "kubectl create namespace argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $argocdInstall

Write-Host "Waiting 90 seconds for Argo CD pods to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

Write-Host "-> Configuring Argo CD NodePort (port 30008)" -ForegroundColor Yellow
$patchCommand = @'
cat <<EOF > /tmp/argocd-nodeport.yaml
spec:
  type: NodePort
  ports:
  - name: https
    port: 443
    targetPort: 8080
    nodePort: 30008
    protocol: TCP
EOF
kubectl patch svc argocd-server -n argocd --patch-file /tmp/argocd-nodeport.yaml
'@
ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP $patchCommand

Write-Host "Waiting 10 seconds for service to update..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "-> Retrieving Argo CD admin password" -ForegroundColor Yellow
$argoPassword = ssh -o StrictHostKeyChecking=no -i $SSHKeyPath ubuntu@$MasterIP "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

Write-Host "✓ Argo CD installed and configured!" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 5: Save Credentials & Display Summary
# ============================================
Write-Host "[STEP 5] Saving credentials and displaying summary..." -ForegroundColor Cyan

$credFile = Join-Path $PSScriptRoot ".argocd-credentials"
$credContent = @"
k8s GitOps Cluster Credentials
===============================

Argo CD Access:
  URL: https://$MasterIP`:30008
  Username: admin
  Password: $argoPassword
  
SSH Access:
  Master: ssh -i $SSHKeyPath ubuntu@$MasterIP
  Worker: ssh -i $SSHKeyPath -J ubuntu@$MasterIP ubuntu@192.168.1.11

Kubectl Access:
  ssh -i $SSHKeyPath ubuntu@$MasterIP
  kubectl get nodes
  kubectl get pods -A

React App NodePort:
  Port 30007 is available for your React application

Notes:
  - Accept the self-signed certificate warning in your browser for Argo CD
  - Worker node is accessible only via SSH jump through master
  - All credentials are saved in this file
"@

$credContent | Out-File -FilePath $credFile -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cluster Information:" -ForegroundColor White
Write-Host "  Master IP: $MasterIP" -ForegroundColor Green
Write-Host "  Worker IP: 192.168.1.11 (internal)" -ForegroundColor Green
Write-Host ""
Write-Host "Argo CD Access:" -ForegroundColor White
Write-Host "  URL: https://$MasterIP`:30008" -ForegroundColor Cyan
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: $argoPassword" -ForegroundColor Cyan
Write-Host ""
Write-Host "SSH Access:" -ForegroundColor White
Write-Host "  Master: ssh -i $SSHKeyPath ubuntu@$MasterIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "Credentials saved to: $credFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Login to Argo CD at https://$MasterIP`:30008" -ForegroundColor Cyan
Write-Host "  2. Configure your GitHub repository in Argo CD" -ForegroundColor Cyan
Write-Host "  3. Deploy your React application" -ForegroundColor Cyan
Write-Host ""
