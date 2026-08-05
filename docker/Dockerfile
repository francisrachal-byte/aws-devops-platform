# syntax=docker/dockerfile:1

FROM node:24-alpine AS dependencies

WORKDIR /app

COPY app/package*.json ./

RUN npm ci --omit=dev \
    && npm cache clean --force


FROM node:24-alpine AS runtime

ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

COPY --from=dependencies --chown=node:node /app/node_modules ./node_modules

COPY --chown=node:node app/package*.json ./
COPY --chown=node:node app/server.js ./
COPY --chown=node:node app/public ./public

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health').then(response => process.exit(response.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "server.js"]