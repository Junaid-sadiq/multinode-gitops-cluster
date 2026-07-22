# Docker Setup Documentation

## Overview

The React application is containerized using a multi-stage Docker build with Nginx as the production web server.

## Docker Architecture

### Multi-Stage Build

```dockerfile
Stage 1: Builder (node:20-alpine)
  ├── Install dependencies
  ├── Build React app
  └── Output: /app/dist

Stage 2: Production (nginx:1.28.0-alpine)
  ├── Copy built assets from builder
  ├── Copy nginx configuration
  └── Serve static files
```

### Benefits

- **Small image size**: ~25MB (Alpine-based)
- **Security**: Minimal attack surface
- **Performance**: Nginx optimized for static content
- **Production-ready**: Proper caching, compression, headers

## Building the Image

### Local Build

```bash
# Basic build
cd reactapp
docker build -t reactapp:latest .

# Build with custom tag
docker build -t reactapp:v1.0.0 .

# Build with build args
docker build \
  --build-arg NODE_ENV=production \
  -t reactapp:latest .

# Multi-platform build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t reactapp:latest .
```

### Build Context Optimization

The `.dockerignore` file excludes unnecessary files:
- node_modules (reinstalled in container)
- dist (built in container)
- Test files
- Documentation
- Git files

**Reduces build context from ~500MB to ~5MB**

## Running the Container

### Basic Run

```bash
# Run on port 8080
docker run -d -p 8080:80 --name reactapp reactapp:latest

# Run with custom name
docker run -d -p 3000:80 --name my-react-app reactapp:latest

# Run in foreground (for debugging)
docker run -p 8080:80 reactapp:latest
```

### With Environment Variables

```bash
docker run -d \
  -p 8080:80 \
  -e NODE_ENV=production \
  --name reactapp \
  reactapp:latest
```

### With Volume Mount (Development)

```bash
# Mount source code for live reload
docker run -d \
  -p 8080:80 \
  -v $(pwd)/src:/app/src \
  reactapp:latest
```

### With Health Check

```bash
docker run -d \
  -p 8080:80 \
  --health-cmd="wget --no-verbose --tries=1 --spider http://localhost/health || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  --name reactapp \
  reactapp:latest
```

## Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  reactapp:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

**Run with Docker Compose:**

```bash
# Start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

## Nginx Configuration

### Key Features

1. **Gzip Compression**
   - Reduces bandwidth usage by 70-80%
   - Compresses JS, CSS, JSON, HTML

2. **Security Headers**
   - X-Frame-Options: SAMEORIGIN
   - X-Content-Type-Options: nosniff
   - X-XSS-Protection: 1; mode=block
   - Referrer-Policy: no-referrer-when-downgrade

3. **Caching Strategy**
   - Static assets: 1 year cache
   - Immutable cache for fingerprinted assets

4. **SPA Routing**
   - All routes serve index.html
   - Enables client-side routing

5. **Health Check**
   - `/health` endpoint for monitoring

### Custom Nginx Configuration

To modify nginx.conf:

```bash
# Edit nginx.conf
vim reactapp/nginx.conf

# Rebuild image
docker build -t reactapp:latest .

# Test configuration
docker run --rm reactapp:latest nginx -t
```

## GitHub Container Registry

### Authentication

```bash
# Create Personal Access Token (PAT) with write:packages permission
# Then login:
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

### Push Image

```bash
# Tag image
docker tag reactapp:latest ghcr.io/USERNAME/REPO/reactapp:latest
docker tag reactapp:latest ghcr.io/USERNAME/REPO/reactapp:v1.0.0

# Push
docker push ghcr.io/USERNAME/REPO/reactapp:latest
docker push ghcr.io/USERNAME/REPO/reactapp:v1.0.0
```

### Pull Image

```bash
# Pull specific version
docker pull ghcr.io/USERNAME/REPO/reactapp:v1.0.0

# Pull latest
docker pull ghcr.io/USERNAME/REPO/reactapp:latest

# Run pulled image
docker run -d -p 8080:80 ghcr.io/USERNAME/REPO/reactapp:latest
```

## Image Analysis

### Size Optimization

```bash
# Check image size
docker images reactapp

# Analyze layers
docker history reactapp:latest

# Use dive for detailed analysis
dive reactapp:latest
```

### Security Scanning

```bash
# Scan with Trivy
trivy image reactapp:latest

# Scan for high/critical vulnerabilities
trivy image --severity HIGH,CRITICAL reactapp:latest

# Generate SBOM
syft reactapp:latest -o spdx-json > sbom.json

# Scan with Grype
grype reactapp:latest
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs reactapp

# Check if port is in use
lsof -i :8080

# Inspect container
docker inspect reactapp

# Run in interactive mode
docker run -it --rm reactapp:latest sh
```

### Build Failures

```bash
# Build with verbose output
docker build --progress=plain -t reactapp:latest .

# Clear build cache
docker builder prune -a

# Check disk space
docker system df
```

### Nginx Configuration Errors

```bash
# Test nginx config
docker run --rm reactapp:latest nginx -t

# Access nginx logs
docker exec reactapp cat /var/log/nginx/error.log
docker exec reactapp cat /var/log/nginx/access.log
```

### Permission Issues

```bash
# Check user inside container
docker exec reactapp whoami
docker exec reactapp id

# Fix permissions (if needed)
docker exec reactapp chown -R nginx:nginx /usr/share/nginx/html
```

## Performance Tuning

### Build Performance

```bash
# Use BuildKit
export DOCKER_BUILDKIT=1
docker build -t reactapp:latest .

# Use build cache from registry
docker build \
  --cache-from ghcr.io/USERNAME/REPO/reactapp:latest \
  -t reactapp:latest .
```

### Runtime Performance

**Adjust Nginx worker processes:**

```nginx
worker_processes auto;
worker_connections 1024;
```

**Enable HTTP/2:**

```nginx
listen 443 ssl http2;
```

## Development Workflow

### Local Development with Docker

```bash
# Build development image
docker build --target builder -t reactapp:dev .

# Run development server
docker run -it --rm \
  -p 5173:5173 \
  -v $(pwd):/app \
  -v /app/node_modules \
  reactapp:dev \
  npm run dev -- --host
```

### Hot Reload Setup

Create `Dockerfile.dev`:

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host"]
```

Run:

```bash
docker build -f Dockerfile.dev -t reactapp:dev .
docker run -p 5173:5173 -v $(pwd)/src:/app/src reactapp:dev
```

## CI/CD Integration

The image is automatically built and pushed by GitHub Actions on push to main branch.

**Workflow**: `.github/workflows/ci-build.yml`

### Manual Trigger

```bash
# Trigger workflow via GitHub CLI
gh workflow run ci-build.yml

# Or push to main
git push origin main
```

## Best Practices

1. **Use specific versions** - Avoid `latest` tag in production
2. **Multi-stage builds** - Keep images small
3. **Security scanning** - Run Trivy/Grype in CI
4. **Health checks** - Always define health endpoints
5. **Non-root user** - Run as nginx user (UID 101)
6. **Read-only filesystem** - Enhance security
7. **Resource limits** - Set memory/CPU limits
8. **Logging** - Use structured logging
9. **Secrets management** - Never bake secrets into images
10. **Version pinning** - Pin base image versions

## Image Tags Strategy

```
ghcr.io/USERNAME/REPO/reactapp:
  - latest                  # Latest stable
  - main-abc1234           # Branch + commit SHA
  - v1.0.0                 # Semantic version
  - main-2024-07-22        # Branch + date
```

## Cleanup

```bash
# Remove container
docker rm -f reactapp

# Remove image
docker rmi reactapp:latest

# Remove all unused images
docker image prune -a

# Clean up everything
docker system prune -a --volumes
```

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
