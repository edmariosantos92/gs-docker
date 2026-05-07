#!/usr/bin/env bash
set -euo pipefail

OUT_FILE="${1:-.env.runtime}"
PARAM_PREFIX="${2:-/labnodejs/prod}"
AWS_REGION="${AWS_REGION:-us-east-1}"

PARAMS=(
  AWS_REGION
  APP_IMAGE
  APP_NAME
  APP_URL
  APP_SESSION_NAME
  ADMIN_TOKEN
  DB_HOST
  DB_PORT
  DB_NAME
  DB_USER
  DB_PASSWORD
  DB_SSL
  S3_BUCKET
  S3_REGION
  CACHE_HOST
  CACHE_PORT
  CACHE_TLS
  CACHE_TTL_SECONDS
  OPENSEARCH_ENDPOINT
  OPENSEARCH_USERNAME
  OPENSEARCH_PASSWORD
  OPENSEARCH_INDEX
)

: > "$OUT_FILE"
for key in "${PARAMS[@]}"; do
  name="${PARAM_PREFIX}/${key}"
  value=$(aws ssm get-parameter \
    --region "$AWS_REGION" \
    --name "$name" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text 2>/dev/null || true)
  if [ -n "$value" ] && [ "$value" != "None" ]; then
    printf '%s=%q\n' "$key" "$value" >> "$OUT_FILE"
  fi
done

chmod 600 "$OUT_FILE"
echo "Arquivo gerado: $OUT_FILE"
