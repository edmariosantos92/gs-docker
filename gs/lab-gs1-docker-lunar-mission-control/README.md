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

Clonar repositório na EC2:
```bash
git clone https://github.com/pauloferrari-prs/education.git
```

Ir para a pasta da GS:

```bash
cd /home/ubuntu/education/gs/lab-gs-docker-lunar-mission-control
```

Subir a aplicação com a infra docker simples:
```bash
docker compose up -d --build
```

Acesse no navegador:

```text
http://IP_PUBLICO_DA_EC2/
```

Teste a aplicação

```bash
curl http://localhost
```

Teste o healthcheck da aplicação:

```bash
curl -s http://localhost/health | jq
```

Também é possível consultar diretamente a API:

```bash
curl -s http://localhost/api/status | jq
```

## Dicas para a sua missão

Ajustar este repositório para uma subida mais próxima de produção, segue dicas do que você deve modificar/entregar:

### 1. Dockerfile;

### 2. docker-compose.yml;

### 3. Gestão dos containers;

### 4. Segurança;

### 5. Volume e Network;

### 6. Outros;

### 7. Entregáveis:

Com a sua solução completa, fazer/documentar:

- Print do `docker compose ps`;
- Print do `docker stats`;
- Evidência do `curl /health`;
- Evidência de acesso à aplicação pelo navegador usando o IP público da sua EC2: ```http://IP_PUBLICO_DA_EC2/```
- Documentação rápida no seu README.md;
- Repositório completo com Dockerfile, docker-compose.yml, `.env` README.md, e demais arquivos.

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

## Docker System Prune (Purge arquivos não utilizados)

```bash
docker system prune -a --volumes -f
```

## Observação importante

- A aplicação Node.js já está pronta. O foco da avaliação é a melhoria da solução Docker;
- Não montar Redis (ElastiCache) e Banco (RDS) usando serviços na AWS (Tem que ser em container - docker mesmo);
- Único serviços na AWS que serão liberados é o ECR (Elastic Container Registry) e a instância EC2 já montada da dupla.

## Uso de IA

Conforme mencionado, o uso de IA está liberado para execução desta GS.


## Boa Prova!!

![alt text](image.png)