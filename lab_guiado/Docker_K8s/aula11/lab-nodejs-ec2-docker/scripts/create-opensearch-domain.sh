#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN_NAME="${DOMAIN_NAME:-labnodejs-search}"
SUBNET_ID="${SUBNET_ID:?Informe SUBNET_ID, exemplo: subnet-aaa}"
OPENSEARCH_SECURITY_GROUP_ID="${OPENSEARCH_SECURITY_GROUP_ID:?Informe OPENSEARCH_SECURITY_GROUP_ID, exemplo: sg-xxx}"
OPENSEARCH_MASTER_USER="${OPENSEARCH_MASTER_USER:-labnodejs_admin}"
OPENSEARCH_MASTER_PASSWORD="${OPENSEARCH_MASTER_PASSWORD:?Informe OPENSEARCH_MASTER_PASSWORD com pelo menos 8 caracteres, letra, número e símbolo}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"

aws iam create-service-linked-role --aws-service-name opensearchservice.amazonaws.com >/dev/null 2>&1 || true

ACCESS_POLICY=$(mktemp)
cat > "$ACCESS_POLICY" <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "*" },
      "Action": "es:*",
      "Resource": "arn:aws:es:${AWS_REGION}:${AWS_ACCOUNT_ID}:domain/${DOMAIN_NAME}/*"
    }
  ]
}
JSON

echo "Criando domínio OpenSearch ${DOMAIN_NAME}..."
aws opensearch create-domain \
  --region "$AWS_REGION" \
  --domain-name "$DOMAIN_NAME" \
  --engine-version OpenSearch_2.19 \
  --cluster-config InstanceType=t3.small.search,InstanceCount=1,DedicatedMasterEnabled=false,ZoneAwarenessEnabled=false \
  --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=10 \
  --vpc-options SubnetIds="$SUBNET_ID",SecurityGroupIds="$OPENSEARCH_SECURITY_GROUP_ID" \
  --node-to-node-encryption-options Enabled=true \
  --encryption-at-rest-options Enabled=true \
  --domain-endpoint-options EnforceHTTPS=true,TLSSecurityPolicy=Policy-Min-TLS-1-2-2019-07 \
  --advanced-security-options Enabled=true,InternalUserDatabaseEnabled=true,MasterUserOptions="{MasterUserName=${OPENSEARCH_MASTER_USER},MasterUserPassword=${OPENSEARCH_MASTER_PASSWORD}}" \
  --access-policies "file://${ACCESS_POLICY}" >/dev/null

echo "Domínio solicitado. OpenSearch costuma demorar alguns minutos para ficar pronto."
echo "Aguardando endpoint ficar disponível..."

for i in $(seq 1 90); do
  PROCESSING=$(aws opensearch describe-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" \
    --query 'DomainStatus.Processing' \
    --output text 2>/dev/null || echo true)

  ENDPOINT=$(aws opensearch describe-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" \
    --query 'DomainStatus.Endpoint' \
    --output text 2>/dev/null || echo None)

  echo "Tentativa ${i}: Processing=${PROCESSING}; Endpoint=${ENDPOINT}"

  if [ "$PROCESSING" = "False" ] && [ -n "$ENDPOINT" ] && [ "$ENDPOINT" != "None" ]; then
    echo "OPENSEARCH_ENDPOINT=https://${ENDPOINT}"
    echo "OPENSEARCH_USERNAME=${OPENSEARCH_MASTER_USER}"
    echo "OPENSEARCH_PASSWORD=${OPENSEARCH_MASTER_PASSWORD}"
    echo "OPENSEARCH_INDEX=products"
    exit 0
  fi

  sleep 30
done

echo "Timeout aguardando OpenSearch. Consulte depois com:" >&2
echo "aws opensearch describe-domain --region ${AWS_REGION} --domain-name ${DOMAIN_NAME} --query 'DomainStatus.Endpoint' --output text" >&2
exit 1
