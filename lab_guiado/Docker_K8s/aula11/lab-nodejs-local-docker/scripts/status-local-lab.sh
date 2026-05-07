#!/usr/bin/env bash
set -euo pipefail

echo "== Containers =="
docker compose ps

echo
echo "== Health app =="
curl -s http://localhost:${APP_PORT:-8080}/healthz || true

echo
echo
echo "== Readiness =="
curl -s http://localhost:${APP_PORT:-8080}/readyz || true

echo
