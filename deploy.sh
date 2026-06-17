#!/bin/bash
# ====================================================
# Deployment Script — Inventory Management System
# Usage: ./deploy.sh [environment]
#   environment: production (default) | staging
# ====================================================
set -euo pipefail

ENVIRONMENT="${1:-production}"
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
PROJECT_NAME="inventory-system"

echo "=========================================="
echo "  Deploying Inventory Management System"
echo "  Environment: ${ENVIRONMENT}"
echo "=========================================="

# 1. Check prerequisites
echo ""
echo "[1/6] Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 || { echo "ERROR: docker-compose not found"; exit 1; }
echo "  ✓ Docker available"

# 2. Pull latest code (if in git repo)
echo ""
echo "[2/6] Pulling latest code..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    git fetch --all
    git checkout main
    git pull origin main
    echo "  ✓ Code updated"
else
    echo "  ⚠ Not a git repository, skipping pull"
fi

# 3. Load environment variables
echo ""
echo "[3/6] Loading environment..."
if [ -f ".env.${ENVIRONMENT}" ]; then
    set -a; source ".env.${ENVIRONMENT}"; set +a
    echo "  ✓ Loaded .env.${ENVIRONMENT}"
else
    echo "  ⚠ .env.${ENVIRONMENT} not found, using defaults"
fi

# 4. Stop old containers
echo ""
echo "[4/6] Stopping old containers..."
docker compose ${COMPOSE_FILES} -p "${PROJECT_NAME}" down --remove-orphans 2>/dev/null || true
echo "  ✓ Old containers stopped"

# 5. Build and start services
echo ""
echo "[5/6] Building and starting services..."
docker compose ${COMPOSE_FILES} -p "${PROJECT_NAME}" build --pull
docker compose ${COMPOSE_FILES} -p "${PROJECT_NAME}" up -d
echo "  ✓ Services started"

# 6. Health check
echo ""
echo "[6/6] Running health check..."
RETRIES=12
for i in $(seq 1 ${RETRIES}); do
    if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
        echo "  ✓ Backend is healthy"
        break
    fi
    if [ "${i}" -eq "${RETRIES}" ]; then
        echo "  ✗ Backend health check failed after ${RETRIES} attempts"
        echo "  Run 'docker compose logs backend' for details"
        exit 1
    fi
    echo "  Waiting for backend... (${i}/${RETRIES})"
    sleep 5
done

echo ""
echo "=========================================="
echo "  Deployment complete!"
echo "  Backend:  http://localhost:8000"
echo "  API Docs: http://localhost:8000/docs"
echo "  Frontend: http://localhost:3000"
echo "=========================================="
