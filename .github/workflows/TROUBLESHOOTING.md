# GitHub Actions Troubleshooting Guide

## Issue: Build Hangs or Times Out

### Common Causes

#### 1. Multi-Platform Builds
**Problem**: Building for multiple platforms (`linux/amd64,linux/arm64`) takes 3-5x longer and can timeout.

**Solution**: 
- Changed to single platform: `linux/amd64` only
- If you need ARM support, build separately or increase timeout

#### 2. Missing .dockerignore
**Problem**: Docker sends entire `node_modules` folder (can be 200MB+) to build context.

**Status**: ✅ Fixed - `.dockerignore` exists and excludes `node_modules`

#### 3. SBOM Generation Timeout
**Problem**: Security scanning and SBOM generation can hang on slow networks.

**Solution**: Added `continue-on-error: true` to SBOM step

#### 4. Missing GitHub Token Permissions
**Problem**: Workflow can't push to GHCR or update manifests.

**Solution**: Added correct permissions:
```yaml
permissions:
  contents: write  # For updating manifests
  packages: write  # For pushing to GHCR
```

## Workflow Files

### Option 1: Full Workflow (ci-build.yml)
- Includes security scanning
- Includes SBOM generation
- Multiple jobs with dependencies
- **Timeout**: 20 minutes per job
- **Use when**: You want full security scanning

### Option 2: Simple Workflow (ci-build-simple.yml)
- Single job
- No security scanning
- Faster execution (5-10 minutes)
- **Timeout**: 15 minutes
- **Use when**: You want quick builds and will scan separately

## How to Switch Workflows

### Disable Current Workflow
Rename the file you want to disable:
```bash
# Disable full workflow
mv .github/workflows/ci-build.yml .github/workflows/ci-build.yml.disabled

# Enable simple workflow (it's already active)
```

### Enable Simple Workflow
The simple workflow is already created: `.github/workflows/ci-build-simple.yml`

It triggers on:
- Push to main (when reactapp files change)
- Manual trigger via GitHub UI

## Checking Build Progress

### View Logs
1. Go to GitHub repository
2. Click "Actions" tab
3. Click on the running workflow
4. Expand each step to see logs

### Key Indicators

**Build is progressing normally:**
```
#1 [internal] load build definition from Dockerfile
#2 [internal] load .dockerignore
#3 [internal] load metadata for docker.io/library/node:20-alpine
#4 [internal] load metadata for docker.io/library/nginx:1.28.0-alpine
#5 [builder 1/6] FROM docker.io/library/node:20-alpine
#6 [stage-1 1/3] FROM docker.io/library/nginx:1.28.0-alpine
```

**Build is stuck (bad):**
```
#1 [internal] load build definition from Dockerfile
... (no progress for 5+ minutes)
```

## Quick Fixes

### 1. Cancel Stuck Build
```bash
# Via GitHub UI
1. Go to Actions tab
2. Click on running workflow
3. Click "Cancel workflow"

# Via GitHub CLI
gh run cancel <run-id>
```

### 2. Re-run Build
```bash
# Push an empty commit to trigger rebuild
git commit --allow-empty -m "chore: trigger rebuild"
git push origin main
```

### 3. Test Locally First
```bash
cd reactapp

# Build Docker image locally
docker build -t test-build .

# If this hangs, check:
# 1. Is .dockerignore present?
# 2. Is node_modules excluded?
# 3. Is Docker Desktop running?
```

## Verification Checklist

Before pushing to GitHub:

- [ ] `.dockerignore` exists in `reactapp/` directory
- [ ] `node_modules` is listed in `.dockerignore`
- [ ] Dockerfile builds successfully locally
- [ ] GitHub token has correct permissions
- [ ] Workflow file has timeout set
- [ ] Single platform build (linux/amd64)

## Expected Build Times

### Local Build (Windows/Mac)
- First build: 3-5 minutes
- Cached build: 30-60 seconds

### GitHub Actions
- First build: 5-8 minutes
- Cached build: 2-3 minutes

If build takes longer than 15 minutes, something is wrong.

## Advanced Debugging

### Enable Debug Logging
Add to workflow file:
```yaml
env:
  ACTIONS_RUNNER_DEBUG: true
  ACTIONS_STEP_DEBUG: true
```

### Build Without Cache
Add to build step:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
no-cache: true  # Add this line
```

### Test Minimal Dockerfile
Create `Dockerfile.minimal` for testing:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json .
RUN npm install --production
COPY . .
RUN npm run build
```

## Getting Help

### Check GitHub Actions Status
https://www.githubstatus.com/

### Review Workflow Logs
1. Actions tab → Click workflow run
2. Download logs: Click ⋯ → "Download log archive"
3. Search for "error", "timeout", "failed"

### Common Error Messages

#### "error: failed to solve: process timeout"
**Cause**: Build took too long
**Fix**: Increase timeout or switch to simple workflow

#### "denied: permission_denied"
**Cause**: Missing GHCR permissions
**Fix**: Check repository settings → Actions → General → Workflow permissions

#### "fatal: could not read Username"
**Cause**: Git push failed in manifest update step
**Fix**: Ensure `contents: write` permission is set

## Monitoring

### Check Image in GHCR
```bash
# List packages
gh api user/packages

# Check specific package
gh api user/packages/container/multinode-gitops-cluster%2Freactapp
```

### Check Manifest Updates
```bash
# View recent commits
git log --oneline -5

# Check deployment.yaml
cat k8s/reactapp/deployment.yaml | grep image:
```

## Performance Optimization

### Current Optimizations
✅ Single platform build (linux/amd64)
✅ GitHub Actions cache enabled
✅ .dockerignore configured
✅ Multi-stage Dockerfile (builder + nginx)
✅ Build timeouts set

### Optional Optimizations
- Use smaller base images (alpine)
- Pre-build dependencies in separate layer
- Use external cache registry
- Split build into separate workflow

## Success Criteria

Your build is successful when:
1. ✅ Workflow completes in under 10 minutes
2. ✅ Image appears in GHCR
3. ✅ `deployment.yaml` is updated with new SHA
4. ✅ ArgoCD detects and syncs changes

## Next Steps After Successful Build

1. **Verify Image**:
   ```bash
   docker pull ghcr.io/junaid-sadiq/multinode-gitops-cluster/reactapp:latest
   ```

2. **Check Deployment**:
   ```bash
   kubectl get pods -n reactapp
   ```

3. **Check ArgoCD**:
   ```bash
   argocd app get reactapp-ui
   ```

4. **Access Application**:
   ```
   http://NODE_IP:30007
   ```
