## ======================================
## STAGE 1: Build Spring Application
## ======================================
#FROM maven:3-eclipse-temurin-21-jdk-jammy AS spring-build
#
## Set the working directory for the Spring app
#WORKDIR /app
#
## Copy the entire monorepo structure for the Maven build
## This ensures we have access to the pom.xml and all dependencies
#COPY . .
#
## Navigate to the backend directory and build the Spring application
#WORKDIR /apps/monorepo-back
#RUN mvn package -DskipTests
#
## ======================================
## STAGE 2: Build Angular Application
## ======================================
#FROM node:20.18-slim AS angular-build
#
## Set the working directory for the monorepo
#WORKDIR /app
#
## Copy package.json, package-lock.json and nx configuration files
## We need to copy both the root package files AND the nx configuration
#COPY package.json package-lock.json* nx.json ./
#
## Copy the entire monorepo structure to ensure we have all necessary files
## This is more reliable than trying to selectively copy only what's needed
#COPY . .
#
## Install dependencies using npm install instead of npm ci
## This is more flexible when working with monorepos
#RUN npm install
#
## Build the Angular application using NX
#RUN npx nx build monorepo-front --configuration=production
#
## ======================================
## STAGE 3: Final Spring Runtime Image
## ======================================
#FROM eclipse-temurin:21-jdk-jammy AS spring-runtime
#
## Set working directory
#WORKDIR /app
#
## Copy the built JAR from the spring build stage
#COPY --from=spring-build /app/apps/monorepo-back/target/*.jar app.jar
#
## Create directory for scripts
#RUN mkdir -p /docker/entrypoint
#
## Create health check script
#RUN echo '#!/bin/sh \n\
#curl -f http://localhost:8080/actuator/health || exit 1' > /docker/entrypoint/healthcheck.sh && \
#    chmod +x /docker/entrypoint/healthcheck.sh
#
## Expose the port the Spring app runs on
#EXPOSE 8080
#
## Create a healthcheck for the Spring application using the script
#HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
#  CMD ["/bin/sh", "/docker/entrypoint/healthcheck.sh"]
#
## Command to run the Spring application
#ENTRYPOINT ["java", "-jar", "app.jar"]
#
## ======================================
## STAGE 4: Final Angular Runtime Image
## ======================================
#FROM nginx:alpine AS angular-runtime
#
## Copy the built Angular application to the Nginx html directory
## The path here matches the default NX output location
#COPY --from=angular-build /app/dist/apps/monorepo-front /usr/share/nginx/html/
#
## Create directory for scripts
#RUN mkdir -p /docker/entrypoint
#
## Create health check script
#RUN echo '#!/bin/sh \n\
#curl -f http://localhost:80/ || exit 1' > /docker/entrypoint/healthcheck.sh && \
#    chmod +x /docker/entrypoint/healthcheck.sh
#
## Expose port 80 for the web server
#EXPOSE 80
#
## Create a healthcheck for the Angular application using the script
#HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
#  CMD ["/bin/sh", "/docker/entrypoint/healthcheck.sh"]
#
## Start Nginx in the foreground to keep the container running
#ENTRYPOINT ["nginx", "-g", "daemon off;"]

# ======================================
# STAGE 1: Build Spring Application
# ======================================
FROM maven:3-eclipse-temurin-21-jdk-jammy AS spring-build

# Set the working directory for the Spring app
WORKDIR /app

# Copy the entire monorepo structure for the Maven build
# This ensures we have access to the pom.xml and all dependencies
COPY . .

# Navigate to the backend directory and build the Spring application
WORKDIR /app/apps/monorepo-back
RUN mvn package -DskipTests

# ======================================
# STAGE 2: Build Angular Application
# ======================================
FROM node:20.18-slim AS angular-build

# Set the working directory for the monorepo
WORKDIR /app

# Copy package.json, package-lock.json and nx configuration files
COPY package.json package-lock.json* nx.json ./

# Copy the entire monorepo structure to ensure we have all necessary files
COPY . .

# Install dependencies using npm install
RUN npm install

# Build the Angular application WITHOUT using NX dependencies
# This bypasses the backend build that requires Java
RUN npx nx build monorepo-front --configuration=production --skip-nx-cache --skip-dependencies

# ======================================
# STAGE 3: Final Spring Runtime Image
# ======================================
FROM eclipse-temurin:21-jdk-jammy AS spring-runtime

# Set working directory
WORKDIR /app

# Copy the built JAR from the spring build stage
COPY --from=spring-build /app/apps/monorepo-back/target/*.jar app.jar

# Create directory for scripts
RUN mkdir -p /docker/entrypoint

# Create health check script
RUN echo '#!/bin/sh \n\
curl -f http://localhost:8080/actuator/health || exit 1' > /docker/entrypoint/healthcheck.sh && \
    chmod +x /docker/entrypoint/healthcheck.sh

# Expose the port the Spring app runs on
EXPOSE 8080

# Create a healthcheck for the Spring application using the script
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD ["/bin/sh", "/docker/entrypoint/healthcheck.sh"]

# Command to run the Spring application
ENTRYPOINT ["java", "-jar", "app.jar"]

# ======================================
# STAGE 4: Final Angular Runtime Image
# ======================================
FROM nginx:alpine AS angular-runtime

# Copy the built Angular application to the Nginx html directory
# The path here matches the default NX output location
COPY --from=angular-build /app/dist/apps/monorepo-front /usr/share/nginx/html/

# Create directory for scripts
RUN mkdir -p /docker/entrypoint

# Create health check script
RUN echo '#!/bin/sh \n\
curl -f http://localhost:80/ || exit 1' > /docker/entrypoint/healthcheck.sh && \
    chmod +x /docker/entrypoint/healthcheck.sh

# Expose port 80 for the web server
EXPOSE 80

# Create a healthcheck for the Angular application using the script
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["/bin/sh", "/docker/entrypoint/healthcheck.sh"]

# Start Nginx in the foreground to keep the container running
ENTRYPOINT ["nginx", "-g", "daemon off;"]
