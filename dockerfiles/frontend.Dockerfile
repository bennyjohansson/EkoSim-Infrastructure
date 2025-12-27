# Development Frontend Dockerfile for Vue 3 + TypeScript
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY frontend/package*.json ./
COPY frontend/tsconfig*.json ./
COPY frontend/vite.config.ts ./

# Install dependencies
RUN npm ci

# Copy source code (excluding node_modules)
COPY frontend/src ./src
COPY frontend/public ./public
COPY frontend/index.html ./
COPY frontend/vite.config.ts ./

# Expose the dev server port
EXPOSE 3000

# Start development server with host binding for container access
# Override the host setting to bind to all interfaces
CMD ["npx", "vite", "--host", "0.0.0.0"]