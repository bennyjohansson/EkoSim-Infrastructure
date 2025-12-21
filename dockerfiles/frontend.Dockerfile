# Development Frontend Dockerfile for Vue 3 + TypeScript
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY modern/package*.json ./
COPY modern/tsconfig*.json ./
COPY modern/vite.config.ts ./

# Install dependencies
RUN npm ci

# Copy source code (excluding node_modules)
COPY modern/src ./src
COPY modern/public ./public
COPY modern/index.html ./
COPY modern/vite.config.ts ./

# Expose the dev server port
EXPOSE 3000

# Start development server with host binding for container access
# Override the host setting to bind to all interfaces
CMD ["npx", "vite", "--host", "0.0.0.0"]