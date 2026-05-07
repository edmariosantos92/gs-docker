#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO="${ECR_REPO:-labnodejs-app}"
CACHE_NAME="${CACHE_NAME:-labnodejs-valkey}"
DOMAIN_NAME="${DOMAIN_NAME:-labnodejs-search}"
BUCKET_NAME="${BUCKET_NAME:-}"
PARAM_PREFIX="${PARAM_PREFIX:-/labnodejs/prod}"

cat <<MSG
Este script remove os recursos do lab criados via CLI/script quando possível:
- Docker Compose local
- ElastiCache Valkey serverless
- Amazon OpenSearch Service domain
- SSM Parameter Store em ${PARAM_PREFIX}
- Bucket S3 informado em BUCKET_NAME, se você passar a variável
- ECR repository ${ECR_REPO}

A EC2 e o RDS foram criados via Console no roteiro da aula, então remova manualmente no Console.
MSG

echo "Removendo stack local Docker..."
docker compose down || true

echo "Removendo cache Valkey serverless..."
aws elasticache delete-serverless-cache \
  --region "$AWS_REGION" \
  --serverless-cache-name "$CACHE_NAME" >/dev/null 2>&1 || true

echo "Removendo domínio OpenSearch..."
aws opensearch delete-domain \
  --region "$AWS_REGION" \
  --domain-name "$DOMAIN_NAME" >/dev/null 2>&1 || true

echo "Removendo parâmetros SSM..."
for p in $(aws ssm get-parameters-by-path --region "$AWS_REGION" --path "$PARAM_PREFIX" --recursive --query 'Parameters[].Name' --output text 2>/dev/null || true); do
  aws ssm delete-parameter --region "$AWS_REGION" --name "$p" >/dev/null 2>&1 || true
done

if [ -n "$BUCKET_NAME" ]; then
  echo "Removendo objetos do bucket S3 ${BUCKET_NAME}..."
  aws s3 rm "s3://${BUCKET_NAME}" --recursive || true
  aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" || true
else
  echo "BUCKET_NAME não informado. Pulando remoção do S3."
fi

echo "Removendo repositório ECR..."
aws ecr delete-repository \
  --region "$AWS_REGION" \
  --repository-name "$ECR_REPO" \
  --force >/dev/null 2>&1 || true

echo "Finalizado. Verifique o Console AWS para confirmar EC2/RDS/Security Groups restantes."
