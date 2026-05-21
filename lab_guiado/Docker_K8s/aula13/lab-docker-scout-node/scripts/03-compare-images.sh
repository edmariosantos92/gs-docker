#!/usr/bin/env bash
set -euo pipefail

OLD_IMAGE="${OLD_IMAGE:-docker-scout-node-lab:node16}"
UPDATED_IMAGE="${UPDATED_IMAGE:-docker-scout-node-lab:node26}"
mkdir -p reports

echo "==> Comparando imagem antiga com imagem atualizada"
echo "    Origem:  ${OLD_IMAGE}"
echo "    Destino: ${UPDATED_IMAGE}"
echo
docker scout compare \
  "local://${OLD_IMAGE}" \
  --to "local://${UPDATED_IMAGE}" \
  --ignore-unchanged \
  | tee reports/compare-node16-to-node26.txt || true

echo
echo "==> Gerando comparação em Markdown"
docker scout compare \
  "local://${OLD_IMAGE}" \
  --to "local://${UPDATED_IMAGE}" \
  --ignore-unchanged \
  --format markdown \
  > reports/compare-node16-to-node26.md 2>&1 || true

echo "==> Relatórios salvos em reports/"
