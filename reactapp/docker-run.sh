#!/bin/bash

# React App Docker Quick Start Script
# Usage: ./docker-run.sh [build|run|stop|logs|clean]

set -e

IMAGE_NAME="reactapp"
CONTAINER_NAME="reactapp-local"
PORT="8080"

case "$1" in
  build)
    echo "🔨 Building Docker image..."
    docker build -t ${IMAGE_NAME}:latest .
    echo "✅ Build complete: ${IMAGE_NAME}:latest"
    docker images ${IMAGE_NAME}
    ;;
    
  run)
    echo "🚀 Starting container..."
    docker run -d \
      -p ${PORT}:80 \
      --name ${CONTAINER_NAME} \
      --health-cmd="wget --no-verbose --tries=1 --spider http://localhost/health || exit 1" \
      --health-interval=30s \
      --health-timeout=3s \
      --health-retries=3 \
      ${IMAGE_NAME}:latest
    
    echo "✅ Container started: ${CONTAINER_NAME}"
    echo "🌐 Access app at: http://localhost:${PORT}"
    echo "💚 Health check at: http://localhost:${PORT}/health"
    echo ""
    echo "Run './docker-run.sh logs' to view logs"
    ;;
    
  stop)
    echo "🛑 Stopping container..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || echo "Container not running"
    docker rm ${CONTAINER_NAME} 2>/dev/null || echo "Container already removed"
    echo "✅ Container stopped and removed"
    ;;
    
  logs)
    echo "📋 Viewing logs (Ctrl+C to exit)..."
    docker logs -f ${CONTAINER_NAME}
    ;;
    
  shell)
    echo "🐚 Opening shell in container..."
    docker exec -it ${CONTAINER_NAME} sh
    ;;
    
  test)
    echo "🧪 Testing application..."
    echo "Checking if container is running..."
    if ! docker ps | grep -q ${CONTAINER_NAME}; then
      echo "❌ Container is not running. Run './docker-run.sh run' first"
      exit 1
    fi
    
    echo "Testing health endpoint..."
    curl -f http://localhost:${PORT}/health || { echo "❌ Health check failed"; exit 1; }
    echo "✅ Health check passed"
    
    echo "Testing main page..."
    curl -f http://localhost:${PORT}/ > /dev/null || { echo "❌ Main page failed"; exit 1; }
    echo "✅ Main page accessible"
    
    echo "🎉 All tests passed!"
    ;;
    
  clean)
    echo "🧹 Cleaning up..."
    ./docker-run.sh stop
    docker rmi ${IMAGE_NAME}:latest 2>/dev/null || echo "Image already removed"
    echo "✅ Cleanup complete"
    ;;
    
  *)
    echo "React App Docker Manager"
    echo ""
    echo "Usage: $0 {build|run|stop|logs|shell|test|clean}"
    echo ""
    echo "Commands:"
    echo "  build  - Build Docker image"
    echo "  run    - Start container"
    echo "  stop   - Stop and remove container"
    echo "  logs   - View container logs"
    echo "  shell  - Open shell in container"
    echo "  test   - Run health checks"
    echo "  clean  - Stop container and remove image"
    echo ""
    echo "Example workflow:"
    echo "  $0 build   # Build the image"
    echo "  $0 run     # Start the container"
    echo "  $0 test    # Test the application"
    echo "  $0 logs    # View logs"
    echo "  $0 stop    # Stop when done"
    exit 1
    ;;
esac
