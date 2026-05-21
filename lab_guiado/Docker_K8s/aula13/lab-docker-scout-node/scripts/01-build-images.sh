#!/usr/bin/env bash
set -euo pipefail

OLD_IMAGE="${OLD_IMAGE:-docker-scout-node-lab:node16}"
UPDATED_IMAGE="${UPDATED_IMAGE:-docker-scout-node-lab:node26}"
OLD_BASE_IMAGE="${OLD_BASE_IMAGE:-node:16-alpine}"
UPDATED_BASE_IMAGE="${UPDATED_BASE_IMAGE:-node:26-alpine}"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

echo "==> Build imagem antiga"
echo "    Base image: ${OLD_BASE_IMAGE}"
echo "    Tag:        ${OLD_IMAGE}"
docker build \
  -f Dockerfile.vulnerable \
  --build-arg NODE_BASE_IMAGE="${OLD_BASE_IMAGE}" \
  -t "${OLD_IMAGE}" \
  .

echo
echo "==> Build imagem atualizada"
echo "    Base image: ${UPDATED_BASE_IMAGE}"
echo "    Tag:        ${UPDATED_IMAGE}"
docker build \
  -f Dockerfile.updated \
  --build-arg NODE_BASE_IMAGE="${UPDATED_BASE_IMAGE}" \
  -t "${UPDATED_IMAGE}" \
  .

echo
echo "==> Imagens criadas"
docker images | grep -E 'docker-scout-node-lab|REPOSITORY' || true
