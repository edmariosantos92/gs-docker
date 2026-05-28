# syntax=docker/dockerfile:1

FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

RUN addgroup -S lunar && adduser -S lunar -G lunar

COPY --from=build /app/node_modules ./node_modules
COPY --chown=lunar:lunar package*.json ./
COPY --chown=lunar:lunar src ./src
COPY --chown=lunar:lunar public ./public

EXPOSE 3000
USER lunar

CMD ["node", "src/server.js"]
