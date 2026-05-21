OLD_IMAGE ?= docker-scout-node-lab:node16
UPDATED_IMAGE ?= docker-scout-node-lab:node26
OLD_BASE_IMAGE ?= node:16-alpine
UPDATED_BASE_IMAGE ?= node:26-alpine

.PHONY: help build up ps test quickview cves recommend compare reports clean

help:
	@echo "Comandos disponíveis:"
	@echo "  make build       - Build das imagens antiga e atualizada"
	@echo "  make up          - Sobe os containers com Docker Compose"
	@echo "  make ps          - Lista containers do LAB"
	@echo "  make test        - Testa endpoints das duas aplicações"
	@echo "  make quickview   - Docker Scout quickview nas duas imagens"
	@echo "  make cves        - Docker Scout cves nas duas imagens"
	@echo "  make recommend   - Recomendações de base image para a imagem antiga"
	@echo "  make compare     - Compara imagem antiga com imagem atualizada"
	@echo "  make reports     - Gera relatórios em reports/"
	@echo "  make clean       - Derruba containers e remove imagens do LAB"

build:
	docker build -f Dockerfile.vulnerable --build-arg NODE_BASE_IMAGE=$(OLD_BASE_IMAGE) -t $(OLD_IMAGE) .
	docker build -f Dockerfile.updated --build-arg NODE_BASE_IMAGE=$(UPDATED_BASE_IMAGE) -t $(UPDATED_IMAGE) .

up:
	docker compose up -d

ps:
	docker compose ps
	docker ps --filter "name=scout-node"

test:
	curl -s http://localhost:3001/ | jq . || curl -s http://localhost:3001/
	curl -s http://localhost:3002/ | jq . || curl -s http://localhost:3002/
	curl -s http://localhost:3001/healthz | jq . || curl -s http://localhost:3001/healthz
	curl -s http://localhost:3002/healthz | jq . || curl -s http://localhost:3002/healthz

quickview:
	docker scout quickview local://$(OLD_IMAGE) || true
	docker scout quickview local://$(UPDATED_IMAGE) || true

cves:
	docker scout cves --only-base local://$(OLD_IMAGE) || true
	docker scout cves --only-base local://$(UPDATED_IMAGE) || true
	docker scout cves --only-base --only-severity critical,high local://$(OLD_IMAGE) || true

recommend:
	docker scout recommendations local://$(OLD_IMAGE) || true
	docker scout recommendations --only-update local://$(OLD_IMAGE) || true

compare:
	docker scout compare local://$(OLD_IMAGE) --to local://$(UPDATED_IMAGE) --ignore-unchanged || true

reports:
	mkdir -p reports
	docker scout quickview local://$(OLD_IMAGE) > reports/quickview-node16.txt 2>&1 || true
	docker scout quickview local://$(UPDATED_IMAGE) > reports/quickview-node26.txt 2>&1 || true
	docker scout cves --format markdown --only-base local://$(OLD_IMAGE) > reports/cves-node16.md 2>&1 || true
	docker scout cves --format markdown --only-base local://$(UPDATED_IMAGE) > reports/cves-node26.md 2>&1 || true
	docker scout recommendations local://$(OLD_IMAGE) > reports/recommendations-node16.txt 2>&1 || true
	docker scout compare local://$(OLD_IMAGE) --to local://$(UPDATED_IMAGE) --ignore-unchanged --format markdown > reports/compare-node16-to-node26.md 2>&1 || true
	@echo "Relatórios salvos em reports/"

clean:
	docker compose down || true
	docker rm -f scout-node-old scout-node-updated 2>/dev/null || true
	docker rmi $(OLD_IMAGE) $(UPDATED_IMAGE) 2>/dev/null || true
