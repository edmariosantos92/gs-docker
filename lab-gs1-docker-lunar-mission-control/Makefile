.PHONY: up down build logs ps stats health scan clean prune

# ── Lifecycle ─────────────────────────────────────────────────────────────────
up:
	docker compose up -d --build

down:
	docker compose down

build:
	docker compose build --no-cache

restart:
	docker compose restart

# ── Observability ─────────────────────────────────────────────────────────────
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

# ── CVE scanning (Item Plus) ──────────────────────────────────────────────────
scan: build
	@mkdir -p trivy-results
	docker compose -f docker-compose.scan.yml run --rm trivy-scan
	@echo "Report saved to trivy-results/trivy-report.txt"

# ── Cleanup ───────────────────────────────────────────────────────────────────
clean:
	docker compose down -v --remove-orphans

prune:
	docker system prune -a --volumes -f
