# ======================================
# STAGE 1: Build Angular Application
# ======================================
FROM node:20.18-slim AS build

# Set the working directory
WORKDIR /app

# Copy package.json and related files first (for better caching)
COPY package.json package-lock.json* nx.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# For NX monorepos, we need to modify the build approach
# Use a direct command to bypass NX dependency checks
RUN node ./node_modules/.bin/nx build monorepo-front --configuration=production --skip-nx-cache

# ======================================
# STAGE 2: Runtime
# ======================================
FROM nginx:alpine

# Copy the built Angular application to the Nginx html directory
COPY --from=build /app/dist/apps/monorepo-front /usr/share/nginx/html/

# Create directory for scripts
RUN mkdir -p /docker/entrypoint

# Create health check script
RUN echo '#!/bin/sh \n\
curl -f http://localhost:80/ || exit 1' > /docker/entrypoint/healthcheck.sh && \
    chmod +x /docker/entrypoint/healthcheck.sh

# Expose port 80 for the web server
EXPOSE 80

# Create a healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["/bin/sh", "/docker/entrypoint/healthcheck.sh"]

# Start Nginx in the foreground
ENTRYPOINT ["nginx", "-g", "daemon off;"]
