#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
CACHE_NAME="${CACHE_NAME:-labnodejs-valkey}"
SUBNET_IDS="${SUBNET_IDS:?Informe SUBNET_IDS, exemplo: 'subnet-aaa subnet-bbb'}"
SECURITY_GROUP_IDS="${SECURITY_GROUP_IDS:?Informe SECURITY_GROUP_IDS, exemplo: 'sg-xxx'}"

aws elasticache create-serverless-cache \
  --region "$AWS_REGION" \
  --serverless-cache-name "$CACHE_NAME" \
  --engine valkey \
  --description "Valkey serverless para o lab Node.js Docker" \
  --subnet-ids $SUBNET_IDS \
  --security-group-ids $SECURITY_GROUP_IDS \
  --cache-usage-limits DataStorage='{Maximum=1,Unit=GB}',ECPUPerSecond='{Maximum=1000}' \
  --tags Key=Project,Value=labnodejs Key=Environment,Value=lab >/dev/null

echo "Aguardando o cache ficar disponível..."
for i in $(seq 1 60); do
  STATUS=$(aws elasticache describe-serverless-caches \
    --region "$AWS_REGION" \
    --serverless-cache-name "$CACHE_NAME" \
    --query 'ServerlessCaches[0].Status' \
    --output text)
  echo "Status atual: ${STATUS}"
  if [ "$STATUS" = "AVAILABLE" ]; then
    break
  fi
  if [ "$STATUS" = "CREATE-FAILED" ]; then
    echo "Falha ao criar cache Valkey." >&2
    exit 1
  fi
  sleep 20
done

if [ "${STATUS:-}" != "AVAILABLE" ]; then
  echo "Timeout aguardando cache Valkey ficar AVAILABLE." >&2
  exit 1
fi

CACHE_HOST=$(aws elasticache describe-serverless-caches \
  --region "$AWS_REGION" \
  --serverless-cache-name "$CACHE_NAME" \
  --query 'ServerlessCaches[0].Endpoint.Address' \
  --output text)
CACHE_PORT=$(aws elasticache describe-serverless-caches \
  --region "$AWS_REGION" \
  --serverless-cache-name "$CACHE_NAME" \
  --query 'ServerlessCaches[0].Endpoint.Port' \
  --output text)

echo "CACHE_HOST=${CACHE_HOST}"
echo "CACHE_PORT=${CACHE_PORT}"
echo "CACHE_TLS=true"
