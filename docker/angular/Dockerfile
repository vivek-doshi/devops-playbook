# syntax=docker/dockerfile:1
# ============================================================
# TEMPLATE: Dockerfile — Angular (Multi-stage: Node build → nginx serve)
# WHEN TO USE: Any Angular 17+ application
# PREREQUISITES: Angular CLI project with package.json
# SECRETS NEEDED: None
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: docker/angular/nginx.conf, docker/angular/.dockerignore
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
RUN npm run build -- --configuration production

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
# Note 7: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
FROM nginx:1.29-alpine AS runtime

# Remove default nginx config and copy custom
# Note 8: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN rm /etc/nginx/conf.d/default.conf
# Note 9: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy Angular build output
# Angular 17+ outputs to dist/<project-name>/browser
# Note 10: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
# <-- CHANGE THIS: your Angular project name
COPY --from=build /app/dist/my-app/browser /usr/share/nginx/html

# Security: run nginx as non-root
# nginx 1.25+ supports running as non-root out of the box
# Note 11: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && chown nginx:nginx /var/run/nginx.pid
USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
