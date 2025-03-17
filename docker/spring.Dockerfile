# ======================================
# STAGE 1: Build Spring Application
# ======================================
FROM maven:3-eclipse-temurin-21-jdk-jammy AS build

# Set the working directory
WORKDIR /app

# Copy the entire monorepo structure for the Maven build
COPY . .

# Navigate to the backend directory and build the Spring application
WORKDIR /app/apps/monorepo-back
RUN mvn package -DskipTests

# ======================================
# STAGE 2: Runtime
# ======================================
FROM eclipse-temurin:21-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/apps/monorepo-back/target/*.jar app.jar

# Create directory for scripts
RUN mkdir -p /docker/entrypoint

# Create health check script
RUN echo '#!/bin/sh \n\
curl -f http://localhost:8080/actuator/health || exit 1' > /docker/entrypoint/healthcheck.sh && \
    chmod +x /docker/entrypoint/healthcheck.sh

# Expose the port the Spring app runs on
EXPOSE 8080

# Create a healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD ["/bin/sh", "/docker/entrypoint/healthcheck.sh"]

# Command to run the Spring application
ENTRYPOINT ["java", "-jar", "app.jar"]
