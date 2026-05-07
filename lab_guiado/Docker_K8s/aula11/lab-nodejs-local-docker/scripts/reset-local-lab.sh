#!/usr/bin/env bash
set -euo pipefail

docker compose down -v --remove-orphans

echo "Lab local removido com volumes. Para subir novamente: docker compose up -d --build"
