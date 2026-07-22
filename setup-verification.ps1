# GitOps Setup Verification Script (PowerShell)
# Repository: https://github.com/Junaid-sadiq/multinode-gitops-cluster.git

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "GitOps Setup Verification" -ForegroundColor Cyan
Write-Host "Repository: Junaid-sadiq/multinode-gitops-cluster" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

function Test-FileExists {
    param($Path)
    if (Test-Path $Path) {
        Write-Host "Found: $Path" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Missing: $Path" -ForegroundColor Red
        return $false
    }
}

function Test-NoPlaceholder {
    param($Path, $Placeholder)
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw
        if ($content -match $Placeholder) {
            Write-Host "Found placeholder '$Placeholder' in $Path" -ForegroundColor Red
            return $false
        } else {
            Write-Host "No placeholder '$Placeholder' in $Path" -ForegroundColor Green
            return $true
        }
    }
    return $false
}

Write-Host "1. Checking Kubernetes Manifests..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
Test-FileExists "k8s\reactapp\namespace.yaml"
Test-FileExists "k8s\reactapp\deployment.yaml"
Test-FileExists "k8s\reactapp\service.yaml"
Test-FileExists "k8s\reactapp\ingress.yaml"
Test-FileExists "k8s\reactapp\hpa.yaml"
Test-FileExists "k8s\reactapp\kustomization.yaml"
Test-FileExists "k8s\reactapp\argocd-application.yaml"
Write-Host ""

Write-Host "2. Checking Docker Files..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
Test-FileExists "reactapp\Dockerfile"
Test-FileExists "reactapp\nginx.conf"
Test-FileExists "reactapp\.dockerignore"
Write-Host ""

Write-Host "3. Checking GitHub Actions..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
Test-FileExists ".github\workflows\pr-checks.yml"
Test-FileExists ".github\workflows\ci-build.yml"
Write-Host ""

Write-Host "4. Checking for Placeholders..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
Test-NoPlaceholder "k8s\reactapp\deployment.yaml" "YOUR_USERNAME"
Test-NoPlaceholder "k8s\reactapp\deployment.yaml" "YOUR_REPO"
Test-NoPlaceholder "k8s\reactapp\kustomization.yaml" "YOUR_USERNAME"
Test-NoPlaceholder "k8s\reactapp\argocd-application.yaml" "YOUR_USERNAME"
Write-Host ""

Write-Host "5. Verifying Image References..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
$deployment = Get-Content "k8s\reactapp\deployment.yaml" -Raw
if ($deployment -match "ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp") {
    Write-Host "Correct image reference in deployment.yaml" -ForegroundColor Green
} else {
    Write-Host "Incorrect image reference in deployment.yaml" -ForegroundColor Red
}

$kustomization = Get-Content "k8s\reactapp\kustomization.yaml" -Raw
if ($kustomization -match "ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp") {
    Write-Host "Correct image reference in kustomization.yaml" -ForegroundColor Green
} else {
    Write-Host "Incorrect image reference in kustomization.yaml" -ForegroundColor Red
}
Write-Host ""

Write-Host "6. Verifying Repository URL..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
$argocd = Get-Content "k8s\reactapp\argocd-application.yaml" -Raw
if ($argocd -match "https://github.com/Junaid-sadiq/multinode-gitops-cluster.git") {
    Write-Host "Correct repository URL in argocd-application.yaml" -ForegroundColor Green
} else {
    Write-Host "Incorrect repository URL in argocd-application.yaml" -ForegroundColor Red
}
Write-Host ""

Write-Host "7. Checking Label Consistency..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
if ($deployment -match "app: reactapp-ui") {
    Write-Host "Deployment has label: app: reactapp-ui" -ForegroundColor Green
} else {
    Write-Host "Deployment missing label: app: reactapp-ui" -ForegroundColor Red
}

$service = Get-Content "k8s\reactapp\service.yaml" -Raw
if ($service -match "app: reactapp-ui") {
    Write-Host "Service selector: app: reactapp-ui" -ForegroundColor Green
} else {
    Write-Host "Service selector incorrect" -ForegroundColor Red
}
Write-Host ""

Write-Host "8. Checking Service Configuration..." -ForegroundColor Yellow
Write-Host "-----------------------------------"
if ($service -match "type: NodePort") {
    Write-Host "Service type: NodePort" -ForegroundColor Green
} else {
    Write-Host "Service type not NodePort" -ForegroundColor Red
}

if ($service -match "nodePort: 30007") {
    Write-Host "NodePort configured: 30007" -ForegroundColor Green
} else {
    Write-Host "NodePort not configured correctly" -ForegroundColor Red
}
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Verification Complete!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Build and push Docker image:" -ForegroundColor White
Write-Host "   cd reactapp" -ForegroundColor Gray
Write-Host "   docker build -t ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp:latest ." -ForegroundColor Gray
Write-Host ""
Write-Host "2. Deploy to Kubernetes:" -ForegroundColor White
Write-Host "   kubectl apply -k k8s/reactapp/" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Or use ArgoCD:" -ForegroundColor White
Write-Host "   kubectl apply -f k8s/reactapp/argocd-application.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Access application:" -ForegroundColor White
Write-Host "   http://NODE_IP:30007" -ForegroundColor Gray
Write-Host ""
