# k8s GitOps CI/CD Infrastructure

Automated production-ready Kubernetes cluster on CSC cPouta OpenStack with GitOps deployment pipeline.

## Architecture

- **Cloud Provider**: CSC cPouta (OpenStack)
- **Infrastructure**: Terraform
- **Configuration**: Ansible
- **Kubernetes**: k3s (lightweight)
- **GitOps**: Argo CD
- **CI/CD**: GitHub Actions

### Infrastructure Components

**Networking:**
- Private network: `k8s-internal-network` (192.168.1.0/24)
- OpenStack router with public gateway
- Floating IP attached to master node

**Security:**
- Public security group: SSH (22), HTTP (80), HTTPS (443), Argo CD (8080), K8s API (6443), NodePort (30007)
- Internal security group: Full internal subnet communication

**Compute:**
- `k8s-master` (192.168.1.10) - Control plane + Argo CD
- `k8s-worker` (192.168.1.11) - Worker node (internal only)

## Prerequisites

1. **Terraform** - Infrastructure provisioning
   ```powershell
   winget install HashiCorp.Terraform
   ```

2. **Ansible** - Configuration management (via WSL2 or Python)
   ```bash
   # In WSL Ubuntu
   sudo apt update && sudo apt install ansible
   
   # Or via Python
   pip install ansible
   ```

3. **SSH Key** - Already configured: `pouta-dokploy-key`

4. **OpenStack Credentials** - Update `terraform/terraform.tfvars`

## Quick Start

### One-Command Deployment

```powershell
.\deploy-k8s-cluster.ps1
```

This single script will:
1. Provision infrastructure with Terraform
2. Configure cluster with k3s (master + worker)
3. Install Argo CD
4. Display access credentials

### Options

```powershell
# Deploy everything from scratch
.\deploy-k8s-cluster.ps1

# Destroy existing infrastructure first, then deploy
.\deploy-k8s-cluster.ps1 -DestroyFirst

# Skip Terraform (if infrastructure already exists)
.\deploy-k8s-cluster.ps1 -SkipTerraform
```

## Accessing Services

### SSH Access

**Master Node (direct):**
```bash
ssh ubuntu@<FLOATING_IP> -i ~/.ssh/pouta-dokploy-key
```

**Worker Node (via master jump):**
```bash
ssh -J ubuntu@<FLOATING_IP> ubuntu@192.168.1.11 -i ~/.ssh/pouta-dokploy-key
```

### Argo CD UI

1. URL: `https://<FLOATING_IP>:30008`
2. Username: `admin`
3. Password: Check `.argocd-credentials` file
4. Accept self-signed certificate warning

### Kubernetes API

The k3s API is accessible at: `https://<FLOATING_IP>:6443`

## GitOps Workflow

1. **Push code** to application repository
2. **GitHub Actions** builds Docker image
3. **CI pipeline** updates image tag in `reactapp-manifests` repo
4. **Argo CD** detects change and deploys automatically
5. **Application** runs on NodePort 30007

## Project Structure

```
.
├── terraform/
│   ├── provider.tf           # OpenStack provider config
│   ├── variables.tf          # Variable declarations
│   ├── terraform.tfvars      # Credentials (gitignored)
│   ├── network_and_secgroups.tf  # Network + security
│   └── instances.tf          # VM instances + SSH key generation
├── deploy-k8s-cluster.ps1    # Main deployment script
├── .argocd-credentials       # Generated credentials (gitignored)
├── .gitignore                # Git ignore rules
├── QUICKSTART.md             # Quick reference guide
├── README.md                 # This file
└── ansible-reference-backup/ # Archived Ansible playbooks (optional)
```

## Alternative Deployment Methods

The `ansible-reference-backup/` directory contains Ansible playbooks as a reference alternative:
- Useful if deploying from Linux/macOS
- Not required for the main PowerShell deployment script
- Kept as reference for task structure and alternative approaches

**Note:** The main `deploy-k8s-cluster.ps1` script uses direct SSH commands for better Windows compatibility.

## Troubleshooting

### Terraform Issues

**Floating IP not attached:**
```powershell
cd terraform
terraform state rm openstack_compute_floatingip_associate_v2.fip_assoc
terraform apply
```

### Ansible Issues

**SSH connection fails:**
```bash
# Test SSH manually
ssh ubuntu@<MASTER_IP> -i ~/.ssh/pouta-dokploy-key

# Verify inventory
cat ansible/inventory.ini
```

**k3s installation fails:**
```bash
# SSH to node and check
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

### Cluster Issues

**Worker not joining:**
```bash
# On master
kubectl get nodes

# On worker
sudo systemctl status k3s-agent
sudo journalctl -u k3s-agent -f
```

## Cleanup

To destroy all infrastructure:

```powershell
cd terraform
terraform destroy
```

Or use the deployment script:

```powershell
.\deploy-k8s-cluster.ps1 -DestroyFirst
```

## Security Notes

- `.env` and `terraform.tfvars` are gitignored (contain credentials)
- `.k3s-token` is gitignored (cluster join token)
- `.argocd-credentials` is gitignored (Argo CD password)
- SSH keys should never be committed to git

## Next Steps

1. Configure GitHub Actions CI/CD pipeline
2. Create `reactapp-manifests` repository
3. Deploy React application
4. Configure Argo CD application sync
5. Set up monitoring (Prometheus/Grafana)

## Support

For issues or questions, check:
- Terraform logs: `terraform apply` output
- Ansible logs: Playbook execution output
- k3s logs: `sudo journalctl -u k3s`
- Argo CD logs: `kubectl logs -n argocd <pod-name>`
