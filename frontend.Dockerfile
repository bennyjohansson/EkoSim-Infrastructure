# Vue.js Frontend Dockerfile
FROM node:20-alpine as build

WORKDIR /app

# Copy package files from EkoWeb frontend
COPY EkoWeb/frontend/package*.json ./
RUN npm ci --only=production

# Copy source code
COPY EkoWeb/frontend/ .

# Build the application
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY EkoSim-Infrastructure/config/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]