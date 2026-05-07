# Lab Local: Docker + Node.js + MySQL + Redis + Elasticsearch

Este laboratório é uma versão **100% local** do lab AWS Node.js. Aqui não usamos nenhum serviço da AWS, não usamos Cloudflare e não precisamos de domínio público.

Tudo roda no seu notebook usando **Docker Compose**:

- **Aplicação Node.js** com site webcommerce simples;
- **Dockerfile multi-stage** para build da aplicação;
- **MySQL em container** para produtos, clientes e login;
- **Redis em container** para cache da busca;
- **Elasticsearch em container** como motor de busca dos produtos;
- **Docker volume** para armazenar as mídias/imagens dos produtos;
- **Arquivo `.env`** para variáveis de ambiente.

> A aplicação contém:
>
> - Home com 3 produtos;
> - Página de detalhe do produto;
> - Página de busca;
> - Cadastro de cliente;
> - Login do cliente;
> - API em `/api/*`;
> - Sem checkout e sem carrinho.



## 1) Arquitetura do LAB local

```text
Usuário no notebook
  |
  v
http://localhost:8080
  |
  v
Container app Node.js
  |
  +--> Container MySQL
  |       - produtos
  |       - clientes
  |       - eventos de login
  |
  +--> Container Redis
  |       - cache da busca
  |
  +--> Container Elasticsearch
  |       - índice products
  |
  +--> Docker volume media-data
          - imagens dos produtos
```

Fluxo da busca:

```text
1ª busca por "fone"
App -> Redis cache miss -> Elasticsearch -> salva no Redis -> resposta source=elasticsearch

2ª busca por "fone"
App -> Redis cache hit -> resposta source=redis-cache
```



## 2) Recursos locais que vamos usar

### Containers

- `labnodejs-local-app`
- `labnodejs-local-mysql`
- `labnodejs-local-redis`
- `labnodejs-local-elasticsearch`
- `labnodejs-local-media-seeder`

### Volumes Docker

- `labnodejs-local-mysql-data`
- `labnodejs-local-redis-data`
- `labnodejs-local-elasticsearch-data`
- `labnodejs-local-media-data`

### Portas no host

| Serviço | Porta no host | Porta no container |
||:|:|
| App Node.js | `8080` | `3000` |
| MySQL | `3307` | `3306` |
| Redis | `6379` | `6379` |
| Elasticsearch | `9200` | `9200` |

> Se alguma porta já estiver em uso no seu notebook, altere no arquivo `.env`.



## 3) Estrutura do projeto

```text
lab-nodejs-local-docker/
├── app
│   ├── package.json
│   ├── package-lock.json
│   ├── public
│   │   ├── assets
│   │   │   └── style.css
│   │   └── media
│   │       └── .gitkeep
│   └── src
│       ├── cache.js
│       ├── config.js
│       ├── db.js
│       ├── reindex-elasticsearch.js
│       ├── search.js
│       ├── server.js
│       └── views.js
├── compose.yaml
├── db
│   └── schema.sql
├── docker
│   └── node
│       └── Dockerfile
├── media
│   ├── fone-bluetooth-pro.jpg
│   ├── mochila-urban-tech.jpg
│   └── smartwatch-fit-one.jpg
├── scripts
│   ├── reset-local-lab.sh
│   └── status-local-lab.sh
├── .env
├── .env.example
└── README.md
```



## 4) Pré-requisitos

No notebook/host:

- Docker Engine ou Docker Desktop;
- Docker Compose plugin;
- `curl`;
- `jq` opcional, mas recomendado para visualizar JSON.

Verifique:

```bash
docker --version
docker compose version
```

### Atenção para Linux: Elasticsearch

Em alguns hosts Linux, o Elasticsearch pode exigir ajuste de `vm.max_map_count`.

Se o container do Elasticsearch não subir, rode no host:

```bash
sudo sysctl -w vm.max_map_count=262144
```

Para persistir após reboot:

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```



## 5) Variáveis de ambiente

Este lab usa o arquivo `.env` diretamente no Docker Compose.

O projeto já vem com um `.env` pronto para uso local:

```bash
cat .env
```

Se quiser recriar a partir do exemplo:

```bash
cp .env.example .env
```

Principais variáveis:

```env
APP_PORT=8080
MYSQL_HOST_PORT=3307
REDIS_HOST_PORT=6379
ELASTICSEARCH_PORT=9200

DB_HOST=mysql
DB_PORT=3306
DB_NAME=labnodejs
DB_USER=labnodejs_user
DB_PASSWORD=labnodejs_pass

CACHE_HOST=redis
CACHE_PORT=6379
CACHE_TLS=false

ELASTICSEARCH_ENDPOINT=http://elasticsearch:9200
ELASTICSEARCH_INDEX=products
MEDIA_DIR=/app/public/media
```



## 6) Subindo o lab local

Na raiz do projeto:

```bash
docker compose up -d --build
```

A primeira subida pode demorar alguns minutos porque o Docker precisa baixar as imagens:

- Node.js;
- MySQL;
- Redis;
- Elasticsearch;
- BusyBox.

Acompanhe:

```bash
docker compose ps
```

Ver logs gerais:

```bash
docker compose logs -f
```

Ver logs apenas da aplicação:

```bash
docker compose logs -f app
```

Ver logs apenas do Elasticsearch:

```bash
docker compose logs -f elasticsearch
```



## 7) Acessando o site

Abra no navegador:

```text
http://localhost:8080
```

Rotas web:

```text
http://localhost:8080/
http://localhost:8080/produto/fone-bluetooth-pro
http://localhost:8080/busca?q=fone
http://localhost:8080/cadastro
http://localhost:8080/login
http://localhost:8080/status
```



## 8) Testes de saúde

### Healthcheck da aplicação

```bash
curl -i http://localhost:8080/healthz
```

Esperado:

```json
{"status":"ok"}
```

### Readiness da aplicação

```bash
curl -s http://localhost:8080/readyz | jq
```

Exemplo esperado:

```json
{
  "ok": true,
  "db": {
    "ok": true
  },
  "cache": {
    "configured": true,
    "ok": true
  },
  "elasticsearch": {
    "configured": true,
    "ok": true
  }
}
```



## 9) Testando API de produtos

```bash
curl -s http://localhost:8080/api/products | jq
```

Deve retornar os 3 produtos cadastrados no MySQL.

Buscar produto por slug:

```bash
curl -s http://localhost:8080/api/products/fone-bluetooth-pro | jq
```



## 10) Verificando as mídias via Docker volume

As imagens ficam em um volume Docker chamado:

```text
labnodejs-local-media-data
```

O serviço `media-seeder` copia os arquivos da pasta local `./media` para o volume na primeira subida.

Validar dentro do container da aplicação:

```bash
docker compose exec app ls -lah /app/public/media/products
```

Testar uma imagem pelo navegador:

```text
http://localhost:8080/media/products/fone-bluetooth-pro.jpg
```

Ou por `curl`:

```bash
curl -I http://localhost:8080/media/products/fone-bluetooth-pro.jpg
```



## 11) Reindexando produtos no Elasticsearch

O MySQL sobe com os produtos iniciais por causa do arquivo:

```text
db/schema.sql
```

Mas o Elasticsearch precisa receber esses produtos no índice `products`.

Rode:

```bash
docker compose exec app npm run reindex:elasticsearch
```

Saída esperada:

```text
Indexação concluída. Produtos enviados para o Elasticsearch: 3
```

Verificar índice no Elasticsearch:

```bash
curl -s http://localhost:9200/products/_search | jq
```



## 12) Testando busca + cache

Primeira chamada:

```bash
curl -s "http://localhost:8080/api/search?q=fone" | jq
```

Esperado:

```json
{
  "data": [
    ...
  ],
  "source": "elasticsearch"
}
```

Segunda chamada igual:

```bash
curl -s "http://localhost:8080/api/search?q=fone" | jq
```

Esperado:

```json
{
  "data": [
    ...
  ],
  "source": "redis-cache"
}
```

Isso demonstra:

```text
1ª busca -> Elasticsearch
2ª busca -> Redis cache
```

Limpar cache Redis e repetir o teste:

```bash
docker compose exec redis redis-cli FLUSHALL
```

## 13) Cadastro e login

### Pela interface web

Abra:

```text
http://localhost:8080/cadastro
```

Cadastre um cliente.

Depois acesse:

```text
http://localhost:8080/login
```

### Pela API

Criar cliente:

```bash
curl -s -X POST http://localhost:8080/api/customers \
  -H 'Content-Type: application/json' \
  -d '{"name":"Paulo Ferrari","email":"paulo@example.com","password":"123456"}' | jq
```

Login:

```bash
curl -s -X POST http://localhost:8080/api/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"paulo@example.com","password":"123456"}' | jq
```



## 14) Acessando MySQL local

Entrar no container MySQL:

```bash
docker compose exec mysql mysql -u labnodejs_user -plabnodejs_pass labnodejs
```

Consultar produtos:

```sql
SELECT id, sku, name, price, image_url FROM products;
```

Ou direto em uma linha:

```bash
docker compose exec mysql mysql -u labnodejs_user -plabnodejs_pass labnodejs \
  -e "SELECT id, sku, name, price FROM products;"
```



## 15) Acessando Redis local

```bash
docker compose exec redis redis-cli PING
```

Listar chaves:

```bash
docker compose exec redis redis-cli KEYS '*'
```

Ver TTL das chaves de busca:

```bash
docker compose exec redis redis-cli TTL 'search:v1:fone'
```

Limpar tudo:

```bash
docker compose exec redis redis-cli FLUSHALL
```



## 16) Acessando Elasticsearch local

Health:

```bash
curl -s http://localhost:9200/_cluster/health | jq
```

Listar índices:

```bash
curl -s http://localhost:9200/_cat/indices?v
```

Buscar no índice `products`:

```bash
curl -s "http://localhost:9200/products/_search?q=fone" | jq
```

Apagar índice para testar reindex novamente:

```bash
curl -X DELETE http://localhost:9200/products
```

Depois rode:

```bash
docker compose exec app npm run reindex:elasticsearch
```



## 17) Comandos úteis de operação

Ver containers:

```bash
docker compose ps
```

Ver consumo:

```bash
docker stats
```

Logs da app:

```bash
docker compose logs -f app
```

Logs do MySQL:

```bash
docker compose logs -f mysql
```

Logs do Redis:

```bash
docker compose logs -f redis
```

Logs do Elasticsearch:

```bash
docker compose logs -f elasticsearch
```

Recriar somente a aplicação:

```bash
docker compose up -d --build --force-recreate app
```

Parar sem apagar dados:

```bash
docker compose down
```

Subir novamente mantendo dados:

```bash
docker compose up -d
```



## 18) Reset completo do lab local

Para apagar containers, rede e volumes:

```bash
./scripts/reset-local-lab.sh
```

Ou manualmente:

```bash
docker compose down -v --remove-orphans
```

Depois suba novamente:

```bash
docker compose up -d --build
```

> Atenção: usando `-v`, os dados do MySQL, Redis, Elasticsearch e mídias serão apagados.



## 19) Troubleshooting

### App não sobe

Ver logs:

```bash
docker compose logs --tail=200 app
```

Validar variáveis dentro do container:

```bash
docker compose exec app env | sort
```

### MySQL não inicializou o schema

O schema só roda automaticamente na primeira criação do volume `mysql-data`.

Se o volume já existia, recrie o lab:

```bash
docker compose down -v

docker compose up -d --build
```

### Elasticsearch não sobe no Linux

Ajuste:

```bash
sudo sysctl -w vm.max_map_count=262144
```

Depois recrie:

```bash
docker compose up -d --force-recreate elasticsearch
```

### Busca retorna `mysql-fallback`

Isso significa que o Elasticsearch não está configurado, não está saudável ou o índice ainda não foi criado.

Rode:

```bash
docker compose exec app npm run reindex:elasticsearch
curl -s "http://localhost:8080/api/search?q=fone" | jq
```

### Busca sempre retorna `elasticsearch`, nunca `redis-cache`

Verifique se o Redis está OK:

```bash
docker compose exec redis redis-cli PING
curl -s http://localhost:8080/readyz | jq
```

Também confira o TTL:

```bash
docker compose exec redis redis-cli KEYS '*'
```

### Porta já está em uso

Altere no `.env`:

```env
APP_PORT=8081
MYSQL_HOST_PORT=3308
REDIS_HOST_PORT=6380
ELASTICSEARCH_PORT=9201
```

Depois:

```bash
docker compose up -d
```

## 20) Diferença para a versão AWS:

| Recurso no lab AWS | Recurso neste lab local |
|||
| EC2 Ubuntu | Host local/notebook |
| RDS MySQL | MySQL container |
| ElastiCache Valkey | Redis container |
| Amazon OpenSearch | Elasticsearch container |
| S3 para imagens | Docker volume de mídias |
| SSM Parameter Store | Arquivo `.env` |
| ECR | Imagem local `labnodejs-local-app:1.0` |
| Cloudflare | `localhost:8080` |