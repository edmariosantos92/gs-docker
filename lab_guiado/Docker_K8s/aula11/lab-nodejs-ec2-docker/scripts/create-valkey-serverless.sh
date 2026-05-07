#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
CACHE_NAME="${CACHE_NAME:-labnodejs-valkey}"
SUBNET_IDS="${SUBNET_IDS:?Informe SUBNET_IDS, exemplo: 'subnet-aaa subnet-bbb'}"
SECURITY_GROUP_IDS="${SECURITY_GROUP_IDS:?Informe SECURITY_GROUP_IDS, exemplo: 'sg-xxx'}"
ENV_FILE="${ENV_FILE:-.valkey.env}"

echo "Criando ElastiCache Valkey Serverless: ${CACHE_NAME}"

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

  STATUS_NORMALIZED=$(echo "$STATUS" | tr '[:upper:]' '[:lower:]')

  echo "Status atual: ${STATUS_NORMALIZED}"

  if [ "$STATUS_NORMALIZED" = "available" ]; then
    break
  fi

  if [ "$STATUS_NORMALIZED" = "create-failed" ]; then
    echo "Falha ao criar cache Valkey." >&2
    exit 1
  fi

  sleep 20
done

if [ "${STATUS_NORMALIZED:-}" != "available" ]; then
  echo "Timeout aguardando cache Valkey ficar available." >&2
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

CACHE_TLS=true

cat > "$ENV_FILE" <<EOV
export CACHE_HOST="${CACHE_HOST}"
export CACHE_PORT="${CACHE_PORT}"
export CACHE_TLS="${CACHE_TLS}"
EOV

echo
echo "Valkey criado com sucesso."
echo
echo "Variáveis geradas:"
cat "$ENV_FILE"
echo
echo "Para carregar no terminal, execute:"
echo "source $ENV_FILE"