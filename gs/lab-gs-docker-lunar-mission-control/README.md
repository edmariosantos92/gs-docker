# Global Solution - Lunar Mission Control

## Contexto

Você recebeu de um time de desenvolvimento uma aplicação Node.js pronta para o projeto **Lunar Mission Control**.

A aplicação simula um painel de monitoramento de uma base lunar, exibindo:

- Energia disponível;
- Oxigênio;
- Temperatura externa;
- Comunicação com a Terra;
- Estoque de água;
- Status dos robôs.

A stack atual está funcionando para ambiente local/desenvolvimento, mas **não está preparada para produção**.

Sua missão é melhorar a parte da infra/arquitetura Docker, para que a aplicação possa ser executada de forma mais adequada em uma instância EC2.

## Arquitetura entregue pelo desenvolvedor

A aplicação possui os seguintes serviços:

- **Node.js**: aplicação web/API;
- **MySQL**: banco de dados da telemetria;
- **Redis**: cache da API;
- **Nginx**: webserver/reverse proxy;
- **Volume de mídia**: imagens persistentes usadas no frontend.

## Como subir a stack atual entregue pelo desenvolvedor

```bash
docker compose up -d --build
```

Acesse no navegador:

```text
http://IP_PUBLICO_DA_EC2/
```

Teste o healthcheck da aplicação:

```bash
curl http://localhost/health
```

Também é possível consultar diretamente a API:

```bash
curl http://localhost/api/status
```

## Dicas para a sua missão

Ajustar este repositório para uma subida mais próxima de produção, segue dicas do que você deve modificar/entregar:

### 1. Dockerfile;

### 2. docker-compose.yml;

### 3. Gestão dos containers;

### 4. Segurança;

### 5. Entregáveis:

Com a sua solução completa, fazer/documentar:

- Print do `docker compose ps`;
- Print do `docker stats`;
- Evidência do `curl /health`;
- Evidência de acesso à aplicação pelo navegador usando o IP público da sua EC2;
- Documentação rápida no seu README.md;
- Repositório completo com Dockerfile, docker-compose.yml, `.env` e demais arquivos.

## Itens Plus (++++)

Neste caso, há alguns itens adicionais que você pode acrescentar à stack da sua aplicação. Se você incluir pelo menos um item plus (+), poderá alcançar a nota máxima: 10!

Dicas dos itens plus:

- Observabilidade;
- Image Registry;
- Vulnerabilidade (CVEs).

## Endpoints úteis

```text
GET  /              Interface web
GET  /api/status    Dados da missão
POST /api/simulate  Simula nova telemetria
GET  /health        Healthcheck geral
GET  /ready         Readiness da aplicação
```

## Observação importante

A aplicação Node.js já está pronta. O foco da avaliação é a melhoria da solução Docker.