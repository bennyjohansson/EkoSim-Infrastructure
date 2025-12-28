# Use Node 18 for compatibility
FROM node:18-alpine

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++ sqlite curl

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY api/package*.json ./

# Install dependencies with proper build environment
RUN npm install

# Copy all API source code including subdirectories
COPY api/ ./

# Create data directory for database with proper permissions
RUN mkdir -p /app/data && chmod 755 /app/data

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
  adduser -S nodejs -u 1001 && \
  chown -R nodejs:nodejs /app

USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

# Start the API server  
CMD ["node", "server.js"]