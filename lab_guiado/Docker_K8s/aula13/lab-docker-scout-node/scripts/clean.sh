#!/usr/bin/env bash
set -euo pipefail

OLD_IMAGE="${OLD_IMAGE:-docker-scout-node-lab:node16}"
UPDATED_IMAGE="${UPDATED_IMAGE:-docker-scout-node-lab:node26}"

echo "==> Parando containers do compose"
docker compose down || true

echo "==> Removendo containers avulsos, se existirem"
docker rm -f scout-node-old scout-node-updated 2>/dev/null || true

echo "==> Removendo imagens do LAB"
docker rmi "${OLD_IMAGE}" "${UPDATED_IMAGE}" 2>/dev/null || true

echo "==> Limpeza concluída"
