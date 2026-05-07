# syntax=docker/dockerfile:1.7

FROM node:22.22.2-bookworm-slim AS deps
WORKDIR /app
COPY app/package*.json ./
RUN npm ci --omit=dev

FROM node:22.22.2-bookworm-slim AS runner
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app

RUN groupadd --system nodeapp && useradd --system --gid nodeapp --home-dir /app nodeapp

COPY --from=deps --chown=nodeapp:nodeapp /app/node_modules ./node_modules
COPY --chown=nodeapp:nodeapp app/package*.json ./
COPY --chown=nodeapp:nodeapp app/src ./src
COPY --chown=nodeapp:nodeapp app/public ./public

USER nodeapp
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "src/server.js"]
