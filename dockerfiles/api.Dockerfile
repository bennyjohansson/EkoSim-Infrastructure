# Use Node 18 for compatibility
FROM node:18-alpine

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++ sqlite

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY api/package*.json ./

# Install dependencies with proper build environment
RUN npm install

# Copy source code (excluding node_modules due to .dockerignore or selective copy)
COPY api/*.js ./
COPY api/*.json ./ 
# Note: node_modules will be managed by anonymous volume

# Create data directory for database with proper permissions
RUN mkdir -p /app/data && chmod 755 /app/data

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
  adduser -S nextjs -u 1001 && \
  chown -R nextjs:nodejs /app

USER nextjs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); \
  http.get('http://localhost:3001/health', (res) => { \
  process.exit(res.statusCode === 200 ? 0 : 1); \
  }).on('error', () => process.exit(1));"

# Start the API server  
CMD ["node", "server.js"]