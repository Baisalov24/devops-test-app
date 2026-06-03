# ── Базовый образ ────────────────────────────────────
FROM nginx:alpine

# ── Безопасность: non-root пользователь ──────────────
RUN addgroup -S appgroup \
    && adduser -S -G appgroup appuser

# ── Конфигурация nginx ────────────────────────────────
COPY nginx.conf /etc/nginx/nginx.conf

# ── Файлы сайта ───────────────────────────────────────
COPY ./src /usr/share/nginx/html

# ── Права на файлы ────────────────────────────────────
RUN chown -R appuser:appgroup /usr/share/nginx/html \
    /var/cache/nginx /var/log/nginx \
    && chmod -R 755 /var/cache/nginx /var/log/nginx

USER appuser

# ── Порт ─────────────────────────────────────────────
EXPOSE 80

# ── Запуск nginx в foreground ─────────────────────────
CMD ["nginx", "-g", "daemon off;"]
