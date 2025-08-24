# ---- Builder ----
    FROM node:20-alpine AS builder
    WORKDIR /app
    
    # Speed up installs in CI
    ENV CI=true
    
    COPY package.json yarn.lock ./
    RUN yarn install --frozen-lockfile
    
    COPY . .
    RUN yarn build
    
    # Prune dev deps after build
    RUN yarn install --production --frozen-lockfile
    
    # ---- Runner ----
    FROM node:20-alpine AS runner
    WORKDIR /app
    ENV NODE_ENV=production
    ENV PORT=3000
    
    # Non-root user for safety
    RUN addgroup -S nodejs && adduser -S nest -G nodejs
    USER nest
    
    # Copy built app and minimal deps
    COPY --from=builder /app/node_modules ./node_modules
    COPY --from=builder /app/package.json ./
    COPY --from=builder /app/dist ./dist
    
    EXPOSE 3000
    
    # Optional healthcheck (adjust path if needed)
    HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
      CMD wget -qO- http://localhost:3000/health || exit 1
    
    CMD ["node", "dist/main.js"]
    