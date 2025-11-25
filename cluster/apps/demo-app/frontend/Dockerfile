FROM nginx:alpine

# Skopiuj pliki frontendu
COPY --chmod=644 index.html /usr/share/nginx/html/
COPY --chmod=644 style.css /usr/share/nginx/html/
COPY --chmod=644 app.js /usr/share/nginx/html/

# Konfiguracja nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
