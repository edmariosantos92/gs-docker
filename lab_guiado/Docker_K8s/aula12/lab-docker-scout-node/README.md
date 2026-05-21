# Aula — LAB Docker Scout com Node.js

Este laboratório demonstra, na prática, como usar o **Docker Scout** para analisar vulnerabilidades de imagens Docker, comparar uma imagem antiga com uma imagem atualizada e entender a recomendação de troca da **base image**.

## Pré-requisitos

Antes de começar, tenha disponível:

- Docker instalado;
- Docker Compose Plugin disponível via `docker compose`;
- Docker Scout disponível na CLI;
- acesso ao terminal;
- internet para baixar imagens base e consultar dados de vulnerabilidade.

Validar Docker:

```bash
docker version
docker compose version
```

Validar Docker Scout:

```bash
docker scout version
```

Se o comando `docker scout` não existir, atualize/instale o Docker Desktop ou o plugin oficial do Docker Scout conforme a documentação oficial da Docker.

Fazer o clone do repositório de labs: ```git clone https://github.com/pauloferrari-prs/education.git```

Fazer o login no docker: 

```bash
docker login -u profprfbessa
```
A password (PAT) passarei em aula.

# 1) Preparar o projeto

Entre na pasta do laboratório:

```bash
cd /home/ubuntu/education/lab_guiado/Docker_K8s/aula13/lab-docker-scout-node
```

## 2) Build das imagens

```bash
docker compose build
```

# 3) Executar os containers

Subir as duas aplicações:

```bash
docker compose up -d
```

Testar a imagem antiga:

```bash
curl http://localhost:3001/

Abrir no navegador: http://[EC2_PUBLIC_IP]:3001/
```

Testar a imagem atualizada:

```bash
curl http://localhost:3002/

Abri no navedor: http://[EC2_PUBLIC_IP]:3002/
```

## 4) Ver visão rápida com Docker Scout

O `quickview` mostra um resumo rápido da imagem, incluindo contagem de vulnerabilidades e possíveis recomendações de base image.

Imagem antiga:

```bash
docker scout quickview local://docker-scout-node-lab:node16
```

Imagem atualizada:

```bash
docker scout quickview local://docker-scout-node-lab:node26
```

## 5) Detalhar CVEs com Docker Scout

Agora vamos detalhar as vulnerabilidades encontradas.

### CVEs da imagem antiga

```bash
docker scout cves local://docker-scout-node-lab:node16
```

### CVEs da imagem atualizada

```bash
docker scout cves local://docker-scout-node-lab:node26
```

### Filtrar apenas CVEs da base image

```bash
docker scout cves \
  --only-base \
  local://docker-scout-node-lab:node16
```

### Filtrar por severidade

Exemplo para olhar apenas CVEs críticas e altas:

```bash
docker scout cves \
  --only-base \
  --only-severity critical,high \
  local://docker-scout-node-lab:node16
```

### Exibir detalhes

```bash
docker scout cves \
  --details \
  --only-base \
  --only-severity high \
  local://docker-scout-node-lab:node16
```

### Gerar relatório em Markdown

```bash
mkdir -p reports

docker scout cves \
  --format markdown \
  --only-base \
  local://docker-scout-node-lab:node16 \
  > reports/cves-node16.md
```

## 6) Ver recomendação de atualização da base image

O comando abaixo mostra recomendações de atualização da imagem base:

```bash
docker scout recommendations local://docker-scout-node-lab:node16
```

Para mostrar apenas recomendações de atualização:

```bash
docker scout recommendations \
  --only-update \
  local://docker-scout-node-lab:node16
```

Para mostrar apenas recomendações de refresh:

```bash
docker scout recommendations \
  --only-refresh \
  local://docker-scout-node-lab:node16
```

### Diferença

- **Refresh**: manter a mesma linha de base, mas pegar uma versão mais nova da mesma tag/variante quando possível.
- **Update**: trocar para uma base image mais nova, por exemplo de `node:16-alpine` para `node:26-alpine`, `node:24-alpine` ou `node:22-alpine`.

## 7) Comparar imagem antiga com imagem atualizada

Agora compare diretamente as duas imagens:

```bash
docker scout compare \
  local://docker-scout-node-lab:node16 \
  --to local://docker-scout-node-lab:node26 \
  --ignore-unchanged
```

## Conclusão

Este LAB mostra de forma simples que a segurança de uma imagem Docker não depende apenas do código da aplicação.

Mesmo uma aplicação Node.js pequena, sem dependências externas, pode carregar vulnerabilidades por causa da **base image**.

A principal lição é:

> Imagem Docker também precisa de ciclo de vida, atualização, análise e validação contínua.

Com o Docker Scout, nós conseguiremos visualizar esse problema de forma prática, comparar antes e depois e entender como escolher uma imagem base mais adequada.