# Backend production image for monorepo layout.
FROM node:20-bookworm-slim

WORKDIR /app/backend

# curl is used by the container healthcheck; openssl is required by Prisma engine.
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install backend dependencies first for better build caching.
COPY backend/package*.json ./
RUN npm install

# Copy backend source.
COPY backend ./

# Generate Prisma client and compile TypeScript.
RUN npx prisma generate
RUN npm run build
RUN npm prune --omit=dev

# Ensure upload directories exist at runtime.
RUN mkdir -p src/public/uploads src/public/images src/public/videos

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]
