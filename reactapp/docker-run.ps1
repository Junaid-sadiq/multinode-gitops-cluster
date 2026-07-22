# React App Docker Quick Start Script (PowerShell)
# Usage: .\docker-run.ps1 [build|run|stop|logs|clean]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$IMAGE_NAME = "reactapp"
$CONTAINER_NAME = "reactapp-local"
$PORT = "8080"

function Build-Image {
    Write-Host "🔨 Building Docker image..." -ForegroundColor Cyan
    docker build -t "${IMAGE_NAME}:latest" .
    Write-Host "✅ Build complete: ${IMAGE_NAME}:latest" -ForegroundColor Green
    docker images $IMAGE_NAME
}

function Start-Container {
    Write-Host "🚀 Starting container..." -ForegroundColor Cyan
    docker run -d `
        -p "${PORT}:80" `
        --name $CONTAINER_NAME `
        --health-cmd="wget --no-verbose --tries=1 --spider http://localhost/health || exit 1" `
        --health-interval=30s `
        --health-timeout=3s `
        --health-retries=3 `
        "${IMAGE_NAME}:latest"
    
    Write-Host "✅ Container started: $CONTAINER_NAME" -ForegroundColor Green
    Write-Host "🌐 Access app at: http://localhost:$PORT" -ForegroundColor Yellow
    Write-Host "💚 Health check at: http://localhost:${PORT}/health" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run '.\docker-run.ps1 logs' to view logs" -ForegroundColor Gray
}

function Stop-AppContainer {
    Write-Host "🛑 Stopping container..." -ForegroundColor Cyan
    docker stop $CONTAINER_NAME 2>$null
    docker rm $CONTAINER_NAME 2>$null
    Write-Host "✅ Container stopped and removed" -ForegroundColor Green
}

function Show-Logs {
    Write-Host "📋 Viewing logs (Ctrl+C to exit)..." -ForegroundColor Cyan
    docker logs -f $CONTAINER_NAME
}

function Open-Shell {
    Write-Host "🐚 Opening shell in container..." -ForegroundColor Cyan
    docker exec -it $CONTAINER_NAME sh
}

function Test-Application {
    Write-Host "🧪 Testing application..." -ForegroundColor Cyan
    
    Write-Host "Checking if container is running..."
    $running = docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
    if (-not $running) {
        Write-Host "❌ Container is not running. Run '.\docker-run.ps1 run' first" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Testing health endpoint..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:${PORT}/health" -UseBasicParsing
        Write-Host "✅ Health check passed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Health check failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Testing main page..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:${PORT}/" -UseBasicParsing
        Write-Host "✅ Main page accessible" -ForegroundColor Green
    } catch {
        Write-Host "❌ Main page failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🎉 All tests passed!" -ForegroundColor Green
}

function Clean-All {
    Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
    Stop-AppContainer
    docker rmi "${IMAGE_NAME}:latest" 2>$null
    Write-Host "✅ Cleanup complete" -ForegroundColor Green
}

function Show-Help {
    Write-Host "React App Docker Manager" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\docker-run.ps1 {build|run|stop|logs|shell|test|clean}" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  build  - Build Docker image" -ForegroundColor Gray
    Write-Host "  run    - Start container" -ForegroundColor Gray
    Write-Host "  stop   - Stop and remove container" -ForegroundColor Gray
    Write-Host "  logs   - View container logs" -ForegroundColor Gray
    Write-Host "  shell  - Open shell in container" -ForegroundColor Gray
    Write-Host "  test   - Run health checks" -ForegroundColor Gray
    Write-Host "  clean  - Stop container and remove image" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example workflow:" -ForegroundColor Cyan
    Write-Host "  .\docker-run.ps1 build   # Build the image" -ForegroundColor Gray
    Write-Host "  .\docker-run.ps1 run     # Start the container" -ForegroundColor Gray
    Write-Host "  .\docker-run.ps1 test    # Test the application" -ForegroundColor Gray
    Write-Host "  .\docker-run.ps1 logs    # View logs" -ForegroundColor Gray
    Write-Host "  .\docker-run.ps1 stop    # Stop when done" -ForegroundColor Gray
}

switch ($Command.ToLower()) {
    "build" { Build-Image }
    "run" { Start-Container }
    "stop" { Stop-AppContainer }
    "logs" { Show-Logs }
    "shell" { Open-Shell }
    "test" { Test-Application }
    "clean" { Clean-All }
    default { Show-Help }
}
