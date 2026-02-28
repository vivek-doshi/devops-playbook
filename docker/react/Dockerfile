# syntax=docker/dockerfile:1
# ============================================================
# TEMPLATE: Dockerfile — React (Multi-stage: Node build → nginx serve)
# WHEN TO USE: Any React application (CRA, Vite, etc.)
# PREREQUISITES: React project with package.json and build script
# SECRETS NEEDED: None
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: docker/react/nginx.conf, docker/react/Dockerfile.dev
# MATURITY: Stable
# ============================================================

# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# CRA outputs to build/, Vite outputs to dist/ — adjust as needed
COPY --from=build /app/build /usr/share/nginx/html            # <-- CHANGE THIS: use /app/dist for Vite

# Security: run nginx as non-root
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && chown nginx:nginx /var/run/nginx.pid
USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
