# stage 1 - build the JAR with Maven
FROM maven:3.8.3-openjdk-17 AS builder
WORKDIR /app
COPY . .
RUN mvn clean install -DskipTests=true

# stage 2 - run the JAR
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar /app/expenseapp.jar
EXPOSE 8080
CMD ["java", "-jar", "expenseapp.jar"]
