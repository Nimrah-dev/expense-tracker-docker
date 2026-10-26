# Expenses Tracker: Docker Setup

A Docker and Docker Compose setup for the open-source Expenses Tracker web app (Java and MySQL). The app runs in one container and the database in another, started with a single command.

> The application source code belongs to its original author: [mohamed0sawy/Expenses-Tracker-WebApp](https://github.com/mohamed0sawy/Expenses-Tracker-WebApp). This repository contains only the Docker setup I wrote for it.

![Expenses Tracker running in Docker](Screenshots/app.png)

## What is in this repo

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build: Maven builds the JAR, a small JRE image runs it |
| `docker-compose.yaml` | The app and MySQL services, network, volume and health check |
| `.dockerignore` | Keeps build output, Git data and database files out of the image |
| `.env.example` | Template for the required variable (the real `.env` is not committed) |
| `.gitignore` | Ignores `.env` and local database data |

## Architecture

```
Browser --> java_app (port 8080) --> mysql_db (internal only)
            custom network: expenses-app-nw
```

- Only the app port (8080) is published. MySQL is reachable only from inside the Compose network.
- The app reaches the database by its service name, `mysql_db`.

## How it works

- **Multi-stage Dockerfile.** The first stage uses a Maven image to build the JAR. The second stage copies only the JAR into an `eclipse-temurin:17-jre-alpine` image, so the final image has no Maven and no source code.
- **Database.** `mysql:8` with a named volume (`mysqldata`) mounted at `/var/lib/mysql`, so data survives container removal.
- **Start order.** MySQL has a health check (`mysqladmin ping`), and the app waits for it with `depends_on` and `condition: service_healthy`.
- **Secrets.** The database password comes from a `.env` file that is not committed. Compose fails with a clear message if it is missing.
- **Restart policy.** Both services use `restart: unless-stopped`.

## Run it

**Prerequisites:** Docker with Docker Compose v2.

```bash
# 1. get the application source
git clone https://github.com/mohamed0sawy/Expenses-Tracker-WebApp.git
cd Expenses-Tracker-WebApp

# 2. copy Dockerfile, docker-compose.yaml, .dockerignore and .env.example
#    from this repository into this folder

# 3. create the .env file with a random password
echo "MYSQL_ROOT_PASSWORD=$(openssl rand -hex 12)" > .env

# 4. build and start
docker compose up -d --build
docker compose ps
```

Open **http://localhost:8080**. The first start can take 20 to 40 seconds while the app connects to the database.

To stop:

```bash
docker compose down        # removes containers and the network, keeps the data
docker compose down -v     # also removes the volume (deletes the database)
```

## Configuration

| Variable | Where | Purpose |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | `.env` | MySQL root password, also used by the app |
| `SPRING_DATASOURCE_URL` | `docker-compose.yaml` | JDBC URL, `jdbc:mysql://mysql_db:3306/expenses_tracker` |
| `SPRING_DATASOURCE_USERNAME` | `docker-compose.yaml` | Database user (`root`) |
| `SPRING_DATASOURCE_PASSWORD` | `docker-compose.yaml` | Taken from `MYSQL_ROOT_PASSWORD` |

## Problems I fixed along the way

1. **The app container kept restarting.** The logs showed it could not find the JAR. The final Docker stage had no `WORKDIR`, so `java -jar` ran from `/` while the JAR was in `/app`. I added `WORKDIR /app`.
2. **JDBC URL typo.** The URL started with `jbdc:` instead of `jdbc:`, so Spring could not pick a database driver.
3. **Health check with `curl`.** The Alpine JRE image does not include `curl`, so that health check could never pass. I removed it and made the app wait for the MySQL health check instead.
4. **Database files in the build context.** The `mysql-data` folder sat inside the project, so `COPY . .` copied it into the build. I switched to a named volume and added a `.dockerignore`.
5. **Plain-text password in the compose file.** I moved it to a `.env` file and added `.env.example`.

## What I practiced

- Multi-stage builds for a Java application
- Docker Compose with a database, a custom network and a named volume
- Reading container logs to find why a container restarts
- Health checks and start order with `service_healthy`
- Keeping credentials in `.env` out of Git and out of images
