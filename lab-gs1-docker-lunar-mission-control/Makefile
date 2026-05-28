.PHONY: up down build logs ps stats health scan obs-up obs-down ecr-login ecr-push clean prune

# ── Variáveis ECR ─────────────────────────────────────────────────────────────
include .env
export

ECR_REGISTRY = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# ── Lifecycle ─────────────────────────────────────────────────────────────────
up:
	docker compose up -d --build

down:
	docker compose down

build:
	docker compose build --no-cache

restart:
	docker compose restart

# ── Observabilidade ───────────────────────────────────────────────────────────
ps:
	docker compose ps

logs:
	docker compose logs -f

stats:
	docker stats $$(docker compose ps -q)

health:
	@echo "=== /health ==="
	@curl -s http://localhost/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost/health
	@echo "\n=== /ready ==="
	@curl -s http://localhost/ready  | python3 -m json.tool 2>/dev/null || curl -s http://localhost/ready

# ── Item Plus: Observabilidade (Prometheus + Grafana + cAdvisor) ──────────────
obs-up:
	docker compose -f docker-compose.observability.yml up -d
	@echo "Prometheus : http://localhost:9090"
	@echo "Grafana    : http://localhost:3001  (admin / LunarGrafana@2025)"

obs-down:
	docker compose -f docker-compose.observability.yml down

obs-logs:
	docker compose -f docker-compose.observability.yml logs -f

# ── Item Plus: CVE Scanning com Trivy ────────────────────────────────────────
scan: build
	@mkdir -p trivy-results
	docker compose -f docker-compose.scan.yml run --rm --profile scan trivy-scan
	@echo "Relatório salvo em trivy-results/trivy-report.txt"

# ── Item Plus: ECR — AWS Image Registry ──────────────────────────────────────
ecr-login:
	aws ecr get-login-password --region $(AWS_REGION) | \
	  docker login --username AWS --password-stdin $(ECR_REGISTRY)

ecr-create-repo:
	aws ecr create-repository \
	  --repository-name $(ECR_REPO) \
	  --region $(AWS_REGION) \
	  --image-scanning-configuration scanOnPush=true \
	  --no-cli-pager || true

ecr-push: build ecr-login
	docker tag lunar-mission-control-app:$(ECR_TAG) $(ECR_REGISTRY)/$(ECR_REPO):$(ECR_TAG)
	docker push $(ECR_REGISTRY)/$(ECR_REPO):$(ECR_TAG)
	@echo "Imagem publicada: $(ECR_REGISTRY)/$(ECR_REPO):$(ECR_TAG)"

# ── Cleanup ───────────────────────────────────────────────────────────────────
clean:
	docker compose down -v --remove-orphans
	docker compose -f docker-compose.observability.yml down -v --remove-orphans 2>/dev/null || true

prune:
	docker system prune -a --volumes -f
