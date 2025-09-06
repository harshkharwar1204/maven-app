# syntax=docker/dockerfile:1

# ===== Build stage =====
FROM maven:3.9.8-eclipse-temurin-17 AS build
WORKDIR /workspace

# Cache dependencies first
COPY pom.xml ./
RUN mvn -q -e -B -DskipTests dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn -q -e -B -DskipTests clean package

# ===== Runtime stage =====
FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy built spring boot fat jar
COPY --from=build /workspace/target/*.jar /app/app.jar

# App runs on 8081 per application.properties
EXPOSE 8081

# Allow optional JVM flags via JAVA_OPTS
ENV JAVA_OPTS=""

# Use exec form and a tiny shell wrapper to allow JAVA_OPTS expansion
ENTRYPOINT ["sh","-c","exec java $JAVA_OPTS -jar /app/app.jar"] 