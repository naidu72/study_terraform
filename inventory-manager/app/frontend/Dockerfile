# Multi-stage build for React frontend

# Stage 1: Build the React application
FROM node:18-alpine AS builder

WORKDIR /app

# Set environment variables to optimize build
ENV NODE_ENV=production
ENV GENERATE_SOURCEMAP=false
ENV TSC_COMPILE_ON_ERROR=true
ENV DISABLE_ESLINT_PLUGIN=true

# Increase Node.js memory limit for build
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Copy package files
COPY package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build the application with optimizations
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Copy nginx config as template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy built files from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
