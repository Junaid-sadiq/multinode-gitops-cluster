#!/bin/bash

# GitOps Setup Verification Script
# Repository: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git

set -e

echo "================================================"
echo "GitOps Setup Verification"
echo "Repository: Junaid-sadiq/multinode-gitops-cluster"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found: $1"
        return 0
    else
        echo -e "${RED}✗${NC} Missing: $1"
        return 1
    fi
}

check_placeholder() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${RED}✗${NC} Found placeholder '$2' in $1"
        return 1
    else
        echo -e "${GREEN}✓${NC} No placeholder '$2' in $1"
        return 0
    fi
}

echo "1. Checking Kubernetes Manifests..."
echo "-----------------------------------"
check_file "k8s/reactapp/namespace.yaml"
check_file "k8s/reactapp/deployment.yaml"
check_file "k8s/reactapp/service.yaml"
check_file "k8s/reactapp/ingress.yaml"
check_file "k8s/reactapp/hpa.yaml"
check_file "k8s/reactapp/kustomization.yaml"
check_file "k8s/reactapp/argocd-application.yaml"
echo ""

echo "2. Checking Docker Files..."
echo "-----------------------------------"
check_file "reactapp/Dockerfile"
check_file "reactapp/nginx.conf"
check_file "reactapp/.dockerignore"
echo ""

echo "3. Checking GitHub Actions..."
echo "-----------------------------------"
check_file ".github/workflows/pr-checks.yml"
check_file ".github/workflows/ci-build.yml"
echo ""

echo "4. Checking for Placeholders..."
echo "-----------------------------------"
check_placeholder "k8s/reactapp/deployment.yaml" "YOUR_USERNAME"
check_placeholder "k8s/reactapp/deployment.yaml" "YOUR_REPO"
check_placeholder "k8s/reactapp/kustomization.yaml" "YOUR_USERNAME"
check_placeholder "k8s/reactapp/argocd-application.yaml" "YOUR_USERNAME"
echo ""

echo "5. Verifying Image References..."
echo "-----------------------------------"
if grep -q "ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp" k8s/reactapp/deployment.yaml; then
    echo -e "${GREEN}✓${NC} Correct image reference in deployment.yaml"
else
    echo -e "${RED}✗${NC} Incorrect image reference in deployment.yaml"
fi

if grep -q "ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp" k8s/reactapp/kustomization.yaml; then
    echo -e "${GREEN}✓${NC} Correct image reference in kustomization.yaml"
else
    echo -e "${RED}✗${NC} Incorrect image reference in kustomization.yaml"
fi
echo ""

echo "6. Verifying Repository URL..."
echo "-----------------------------------"
if grep -q "https://github.com/Junaid-sadiq/multinode-gitops-cluster.git" k8s/reactapp/argocd-application.yaml; then
    echo -e "${GREEN}✓${NC} Correct repository URL in argocd-application.yaml"
else
    echo -e "${RED}✗${NC} Incorrect repository URL in argocd-application.yaml"
fi
echo ""

echo "7. Checking Label Consistency..."
echo "-----------------------------------"
if grep -q "app: reactapp-ui" k8s/reactapp/deployment.yaml; then
    echo -e "${GREEN}✓${NC} Deployment has label: app: reactapp-ui"
else
    echo -e "${RED}✗${NC} Deployment missing label: app: reactapp-ui"
fi

if grep -q "app: reactapp-ui" k8s/reactapp/service.yaml; then
    echo -e "${GREEN}✓${NC} Service selector: app: reactapp-ui"
else
    echo -e "${RED}✗${NC} Service selector incorrect"
fi
echo ""

echo "8. Checking Service Configuration..."
echo "-----------------------------------"
if grep -q "type: NodePort" k8s/reactapp/service.yaml; then
    echo -e "${GREEN}✓${NC} Service type: NodePort"
else
    echo -e "${RED}✗${NC} Service type not NodePort"
fi

if grep -q "nodePort: 30007" k8s/reactapp/service.yaml; then
    echo -e "${GREEN}✓${NC} NodePort configured: 30007"
else
    echo -e "${RED}✗${NC} NodePort not configured correctly"
fi
echo ""

echo "9. Validating YAML Syntax..."
echo "-----------------------------------"
for file in k8s/reactapp/*.yaml; do
    if command -v kubectl &> /dev/null; then
        if kubectl apply --dry-run=client -f "$file" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Valid YAML: $(basename $file)"
        else
            echo -e "${RED}✗${NC} Invalid YAML: $(basename $file)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} kubectl not found, skipping YAML validation"
        break
    fi
done
echo ""

echo "================================================"
echo "Verification Complete!"
echo "================================================"
echo ""
echo "Next Steps:"
echo "1. Build and push Docker image:"
echo "   cd reactapp"
echo "   docker build -t ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp:latest ."
echo ""
echo "2. Deploy to Kubernetes:"
echo "   kubectl apply -k k8s/reactapp/"
echo ""
echo "3. Or use ArgoCD:"
echo "   kubectl apply -f k8s/reactapp/argocd-application.yaml"
echo ""
echo "4. Access application:"
echo "   http://NODE_IP:30007"
echo ""
