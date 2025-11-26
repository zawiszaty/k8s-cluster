# Build stage - Build OpenTelemetry bundle with webpack
FROM node:18-alpine AS builder

WORKDIR /build

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install

# Copy source files
COPY webpack.config.js ./
COPY src/ ./src/

# Build the bundle
RUN npm run build

# Production stage - Serve with nginx
FROM nginx:alpine

# Copy built bundle
COPY --from=builder --chmod=644 /build/dist/otel-bundle.js /usr/share/nginx/html/

# Copy frontend files
COPY --chmod=644 index.html /usr/share/nginx/html/
COPY --chmod=644 style.css /usr/share/nginx/html/
COPY --chmod=644 app.js /usr/share/nginx/html/

# Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
