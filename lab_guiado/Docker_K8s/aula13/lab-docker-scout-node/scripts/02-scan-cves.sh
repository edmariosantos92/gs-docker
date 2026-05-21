#!/usr/bin/env bash
set -euo pipefail

OLD_IMAGE="${OLD_IMAGE:-docker-scout-node-lab:node16}"
UPDATED_IMAGE="${UPDATED_IMAGE:-docker-scout-node-lab:node26}"
mkdir -p reports

echo "==> Docker Scout Quickview - imagem antiga"
docker scout quickview "local://${OLD_IMAGE}" | tee reports/quickview-node16.txt || true

echo
echo "==> Docker Scout Quickview - imagem atualizada"
docker scout quickview "local://${UPDATED_IMAGE}" | tee reports/quickview-node26.txt || true

echo
echo "==> CVEs da base image antiga"
docker scout cves \
  --only-base \
  "local://${OLD_IMAGE}" \
  | tee reports/cves-node16.txt || true

echo
echo "==> CVEs da base image atualizada"
docker scout cves \
  --only-base \
  "local://${UPDATED_IMAGE}" \
  | tee reports/cves-node26.txt || true

echo
echo "==> CVEs críticas e altas da imagem antiga"
docker scout cves \
  --only-base \
  --only-severity critical,high \
  "local://${OLD_IMAGE}" \
  | tee reports/cves-node16-critical-high.txt || true

echo
echo "==> Gerando relatório Markdown da imagem antiga em reports/cves-node16.md"
docker scout cves \
  --format markdown \
  --only-base \
  "local://${OLD_IMAGE}" \
  > reports/cves-node16.md 2>&1 || true

echo "==> Relatórios salvos em reports/"
