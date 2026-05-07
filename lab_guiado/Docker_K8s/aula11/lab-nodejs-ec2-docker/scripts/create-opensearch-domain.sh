#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN_NAME="${DOMAIN_NAME:-labnodejs-search}"
SUBNET_ID="${SUBNET_ID:?Informe SUBNET_ID}"
OPENSEARCH_SECURITY_GROUP_ID="${OPENSEARCH_SECURITY_GROUP_ID:?Informe OPENSEARCH_SECURITY_GROUP_ID}"
OPENSEARCH_MASTER_USER="${OPENSEARCH_MASTER_USER:-labnodejs_admin}"
OPENSEARCH_MASTER_PASSWORD="${OPENSEARCH_MASTER_PASSWORD:?Informe OPENSEARCH_MASTER_PASSWORD}"
ENV_FILE="${ENV_FILE:-.opensearch.env}"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DOMAIN_ARN="arn:aws:es:${AWS_REGION}:${AWS_ACCOUNT_ID}:domain/${DOMAIN_NAME}/*"

ACCESS_POLICY=$(python3 - <<PY
import json
policy = {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "*"},
      "Action": "es:*",
      "Resource": "${DOMAIN_ARN}"
    }
  ]
}
print(json.dumps(policy, separators=(",", ":")))
PY
)

get_opensearch_endpoint() {
  local endpoint_vpc
  local endpoint_public

  endpoint_vpc=$(aws opensearch describe-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" \
    --query 'DomainStatus.Endpoints.vpc' \
    --output text 2>/dev/null || true)

  endpoint_public=$(aws opensearch describe-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" \
    --query 'DomainStatus.Endpoint' \
    --output text 2>/dev/null || true)

  if [ -n "$endpoint_vpc" ] && [ "$endpoint_vpc" != "None" ]; then
    echo "$endpoint_vpc"
  elif [ -n "$endpoint_public" ] && [ "$endpoint_public" != "None" ]; then
    echo "$endpoint_public"
  else
    echo "None"
  fi
}

domain_exists() {
  aws opensearch describe-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" >/dev/null 2>&1
}

if domain_exists; then
  echo "Domínio OpenSearch ${DOMAIN_NAME} já existe. Pulando criação..."
else
  echo "Criando domínio OpenSearch ${DOMAIN_NAME}..."

  aws opensearch create-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" \
    --engine-version "OpenSearch_2.15" \
    --cluster-config "InstanceType=t3.small.search,InstanceCount=1,ZoneAwarenessEnabled=false" \
    --ebs-options "EBSEnabled=true,VolumeType=gp3,VolumeSize=10" \
    --vpc-options "SubnetIds=${SUBNET_ID},SecurityGroupIds=${OPENSEARCH_SECURITY_GROUP_ID}" \
    --node-to-node-encryption-options "Enabled=true" \
    --encryption-at-rest-options "Enabled=true" \
    --domain-endpoint-options "EnforceHTTPS=true,TLSSecurityPolicy=Policy-Min-TLS-1-2-2019-07" \
    --advanced-security-options "Enabled=true,InternalUserDatabaseEnabled=true,MasterUserOptions={MasterUserName=${OPENSEARCH_MASTER_USER},MasterUserPassword=${OPENSEARCH_MASTER_PASSWORD}}" \
    --access-policies "$ACCESS_POLICY" \
    --tag-list Key=Project,Value=labnodejs Key=Environment,Value=lab >/dev/null
fi

echo "Aguardando domínio ficar disponível..."

for i in $(seq 1 90); do
  PROCESSING=$(aws opensearch describe-domain \
    --region "$AWS_REGION" \
    --domain-name "$DOMAIN_NAME" \
    --query 'DomainStatus.Processing' \
    --output text)

  ENDPOINT=$(get_opensearch_endpoint)

  echo "Processing: ${PROCESSING} | Endpoint: ${ENDPOINT}"

  PROCESSING_NORMALIZED=$(echo "$PROCESSING" | tr '[:upper:]' '[:lower:]')

  if [ "$PROCESSING_NORMALIZED" = "false" ] && [ "$ENDPOINT" != "None" ] && [ -n "$ENDPOINT" ]; then
    break
  fi

  sleep 30
done

OPENSEARCH_HOST=$(get_opensearch_endpoint)

if [ "$OPENSEARCH_HOST" = "None" ] || [ -z "$OPENSEARCH_HOST" ]; then
  echo "Não foi possível obter o endpoint do OpenSearch ainda." >&2
  echo "Tente novamente depois com:" >&2
  echo "aws opensearch describe-domain --region \"$AWS_REGION\" --domain-name \"$DOMAIN_NAME\" --query 'DomainStatus.Endpoints.vpc' --output text" >&2
  exit 1
fi

OPENSEARCH_ENDPOINT="https://${OPENSEARCH_HOST}"
OPENSEARCH_INDEX="products"

cat > "$ENV_FILE" <<EOV
export OPENSEARCH_ENDPOINT="${OPENSEARCH_ENDPOINT}"
export OPENSEARCH_USERNAME="${OPENSEARCH_MASTER_USER}"
export OPENSEARCH_PASSWORD="${OPENSEARCH_MASTER_PASSWORD}"
export OPENSEARCH_INDEX="${OPENSEARCH_INDEX}"
EOV

echo
echo "OpenSearch pronto."
echo
echo "Variáveis geradas em ${ENV_FILE}:"
cat "$ENV_FILE"
echo
echo "Para carregar no terminal, execute:"
echo "source $ENV_FILE"
