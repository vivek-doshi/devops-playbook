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
# Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
FROM node:25-alpine AS build
# Note 2: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
WORKDIR /app
# Note 3: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY package*.json ./
# Note 4: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN npm ci --ignore-scripts
# Note 5: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY . .
# Note 6: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN npm run build

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
# Note 7: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
FROM nginx:1.29-alpine AS runtime
# Note 8: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN rm /etc/nginx/conf.d/default.conf
# Note 9: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# CRA outputs to build/, Vite outputs to dist/ — adjust as needed
# Note 10: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
# <-- CHANGE THIS: use /app/dist for Vite builds
COPY --from=build /app/build /usr/share/nginx/html

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
