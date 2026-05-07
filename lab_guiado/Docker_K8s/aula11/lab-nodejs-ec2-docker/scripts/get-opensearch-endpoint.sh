#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN_NAME="${DOMAIN_NAME:-labnodejs-search}"

ENDPOINT=$(aws opensearch describe-domain \
  --region "$AWS_REGION" \
  --domain-name "$DOMAIN_NAME" \
  --query 'DomainStatus.Endpoint' \
  --output text)

echo "OPENSEARCH_ENDPOINT=https://${ENDPOINT}"
