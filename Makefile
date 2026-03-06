include local.env
export $(shell sed 's/=.*//' local.env)

NETWORK_NAME=evocelot-network

# Creates podman network.
create-podman-network:
	@echo "[>>>] Creating podman network"
	@podman network create $(NETWORK_NAME) 2>/dev/null || \
		echo "There is no need to create the network named $(NETWORK_NAME) because it already exists."
	@echo "[<<<]"

# Deletes the created podman network.
delete-podman-network:
	@echo "[>>>] Deleting podman network"
	@podman network rm $(NETWORK_NAME) 2>/dev/null || \
		echo "The network named $(NETWORK_NAME) cannot be deleted."
	@echo "[<<<]"

# Builds the liquibase docker image.
build-liquibase-image:
	@echo "[>>>] Building the liquibase docker image"
	@podman build -t $(IMAGE_NAME):$(VERSION) -f Dockerfile.prod
	@echo "[<<<]"

# Starts local postgresql container
start-postgres-container: create-podman-network stop-postgres-container
	mkdir -p evocelot-postgres-data
	@echo "[>>>] Starting postgresql container"
	@podman run -d \
		--name evocelot-postgres \
		--network $(NETWORK_NAME) \
		-p 5432:5432 \
		-e POSTGRES_DB=sample \
		-e POSTGRES_USER=admin \
		-e POSTGRES_PASSWORD=admin \
		-e TZ=Europe/Budapest \
		-v ./evocelot-postgres-data:/var/lib/postgresql/data \
		postgres:16; \
		\
		echo "evocelot-postgres started at: localhost:5432"
	@echo "[<<<]"

# Stops the postgresql container.
stop-postgres-container:
	@echo "[>>>] Stopping the evocelot-postgres container"
	@podman rm -f evocelot-postgres 2>/dev/null || true
	@echo "[<<<]"

# Starts the pgAdmin container.
start-pgadmin-container: stop-pgadmin-container
	@echo "[>>>] Starting pgAdmin container"
	@podman run -d \
		--name evocelot-pgadmin \
		--network $(NETWORK_NAME) \
		-p 5050:80 \
		-e PGADMIN_DEFAULT_EMAIL=admin@evocelot.com \
		-e PGADMIN_DEFAULT_PASSWORD=admin \
		-e PGADMIN_CONFIG_SERVER_MODE=False \
		-v ./pgadmin/servers.json:/pgadmin4/servers.json:ro \
		--restart always \
		dpage/pgadmin4:8; \
		\
		echo "pgAdmin started at: http://localhost:5050"
	@echo "[<<<]"

# Stops the pgAdmin container.
stop-pgadmin-container:
	@echo "[>>>] Stopping the evocelot-pgadmin container"
	@podman rm -f evocelot-pgadmin 2>/dev/null || true
	@echo "[<<<]"

# Starts the liquibase container to run the database migrations.
start-liquibase-container: build-liquibase-image create-podman-network
	@echo "[>>>] Starting liquibase container for postgres"
	@podman run \
		--network $(NETWORK_NAME) \
		-e CONTEXTS=local \
		-e DB_URL=jdbc:postgresql://evocelot-postgres:5432/samplr \
		-e DB_USERNAME=admin \
		-e DB_PASSWORD=admin \
		-e DB_DRIVER=org.postgresql.Driver \
		-v ./changelog:/liquibase/changelog \
		$(IMAGE_NAME):$(VERSION)
	@echo "[<<<]"