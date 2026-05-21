#!/usr/bin/env bash
set -euo pipefail

OLD_IMAGE="${OLD_IMAGE:-docker-scout-node-lab:node16}"
mkdir -p reports

echo "==> Recomendações de base image para ${OLD_IMAGE}"
docker scout recommendations "local://${OLD_IMAGE}" \
  | tee reports/recommendations-node16.txt || true

echo
echo "==> Apenas recomendações de update"
docker scout recommendations \
  --only-update \
  "local://${OLD_IMAGE}" \
  | tee reports/recommendations-node16-update.txt || true

echo
echo "==> Apenas recomendações de refresh"
docker scout recommendations \
  --only-refresh \
  "local://${OLD_IMAGE}" \
  | tee reports/recommendations-node16-refresh.txt || true

echo "==> Relatórios salvos em reports/"
