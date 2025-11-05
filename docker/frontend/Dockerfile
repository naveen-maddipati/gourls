# Build stage
FROM node:22-alpine AS build
WORKDIR /app

# Copy package files
COPY go-urls-app/package*.json ./
RUN npm ci

# Copy source code (excluding node_modules)
COPY go-urls-app/src ./src
COPY go-urls-app/public ./public
COPY go-urls-app/angular.json ./angular.json
COPY go-urls-app/tsconfig*.json ./
COPY go-urls-app/vite.config.ts ./vite.config.ts

# Build arguments for dynamic configuration
ARG BASE_URL=/
ARG GO_DOMAIN=go
ARG API_URL=/api
ARG IS_PRODUCTION=true

# Generate constants.ts for production
RUN echo "// 🚀 Application Constants" > src/app/core/constants.ts && \
    echo "// Auto-generated for Docker production build" >> src/app/core/constants.ts && \
    echo "" >> src/app/core/constants.ts && \
    echo "export const Base_Url = '${BASE_URL}';" >> src/app/core/constants.ts && \
    echo "export const Go_Domain = 'http://${GO_DOMAIN}';" >> src/app/core/constants.ts && \
    echo "" >> src/app/core/constants.ts && \
    echo "export const Environment = {" >> src/app/core/constants.ts && \
    echo "  apiUrl: '${API_URL}'," >> src/app/core/constants.ts && \
    echo "  goDomain: 'http://${GO_DOMAIN}'," >> src/app/core/constants.ts && \
    echo "  domain: '${GO_DOMAIN}'," >> src/app/core/constants.ts && \
    echo "  isProduction: ${IS_PRODUCTION}," >> src/app/core/constants.ts && \
    echo "  generatedAt: '$(date -u +%Y-%m-%dT%H:%M:%SZ)'" >> src/app/core/constants.ts && \
    echo "};" >> src/app/core/constants.ts

# Build Angular app for production
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Install curl for health checks
RUN apk add --no-cache curl

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy built Angular app
COPY --from=build /app/dist/go-urls-app /usr/share/nginx/html

# Copy custom nginx config for Angular routing
COPY docker/frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY docker/frontend/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]