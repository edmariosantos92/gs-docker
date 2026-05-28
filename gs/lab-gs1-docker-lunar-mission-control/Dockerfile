# ── Stage 1: install production dependencies ─────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund

# ── Stage 2: lean production image ───────────────────────────────────────────
FROM node:20-alpine AS runner

# dumb-init: proper PID 1 / SIGTERM forwarding to Node.js process
# curl: required by the HEALTHCHECK probe
RUN apk add --no-cache dumb-init curl

ENV NODE_ENV=production

WORKDIR /app

# Pull only the installed node_modules from the builder stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source with node:node ownership (avoids running as root)
COPY --chown=node:node . .

USER node

EXPOSE 3000

# Liveness probe: fails fast if the app stops responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fs http://localhost:3000/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/server.js"]
