# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom.xml first for dependency caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests -B

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -S cineluxe && adduser -S cineluxe -G cineluxe

# Copy the built JAR
COPY --from=builder /app/target/*.jar app.jar

# Set file ownership
RUN chown cineluxe:cineluxe app.jar
USER cineluxe

# Environment variables with defaults (override in docker run or compose)
# Requirements: 43.1, 43.3
ENV SERVER_PORT=8080 \
    SPRING_APPLICATION_NAME=cinema-booking-api \
    SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver \
    SPRING_JPA_HIBERNATE_DDL_AUTO=update \
    SPRING_JPA_SHOW_SQL=false \
    SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT=org.hibernate.dialect.PostgreSQLDialect \
    SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL=false

# Required secrets — must be provided at runtime (no defaults for security):
# DATABASE_URL       - jdbc:postgresql://host:port/dbname
# SPRING_DATASOURCE_URL      (alias for DATABASE_URL)
# SPRING_DATASOURCE_USERNAME
# SPRING_DATASOURCE_PASSWORD
# BOOKING_VNPAY_SECRET       - VNPay HMAC secret key
# FCM_SERVER_KEY             - Firebase Cloud Messaging server key
# CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
# CORS_ALLOWED_ORIGINS       - comma-separated list of allowed frontend origins

EXPOSE 8080

# Health check for container orchestration (Req 43.4)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]
