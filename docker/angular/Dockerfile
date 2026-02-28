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
FROM node:22-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY . .
RUN npm run build -- --configuration production

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Remove default nginx config and copy custom
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy Angular build output
# Angular 17+ outputs to dist/<project-name>/browser
COPY --from=build /app/dist/my-app/browser /usr/share/nginx/html   # <-- CHANGE THIS: your Angular project name

# Security: run nginx as non-root
# nginx 1.25+ supports running as non-root out of the box
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && chown nginx:nginx /var/run/nginx.pid
USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
