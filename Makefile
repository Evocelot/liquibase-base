NETWORK_NAME=evocelot-network

# Wrapper command to run a command and indent its output with a tab for better readability.
define run-with-output-indent
	@$(1) | sed 's/^/\t/'
endef

# Creates podman network.
create-podman-network:
	@echo "Creating podman network"
	$(call run-with-output-indent,\
		podman network create $(NETWORK_NAME) 2>/dev/null || \
		echo "There is no need to create the network named $(NETWORK_NAME) because it already exists.")

# Deletes the created podman network.
delete-podman-network:
	@echo "Deleting podman network"
	$(call run-with-output-indent,\
		podman network rm $(NETWORK_NAME) 2>/dev/null || \
		echo "The network named $(NETWORK_NAME) cannot be deleted.")

# Starts local mariadb container.
start-mariadb-container: create-podman-network stop-mariadb-container
	@echo "Starting mariadb container"
	$(call run-with-output-indent,\
		podman run -d \
		--name evocelot-mariadb \
		--network $(NETWORK_NAME) \
		-p 3306:3306 \
		-e MARIADB_ROOT_PASSWORD=admin \
      	-e TZ=Europe/Budapest \
      	-e LANG=C.UTF-8 \
      	-e LC_ALL=C.UTF-8 \
		--health-cmd "healthcheck.sh --connect --initialized" \
  		--health-interval 2s \
  		-v ./schema_local_create.sql:/docker-entrypoint-initdb.d/schema_local_create.sql:ro \
		mariadb:11.6.2; \
		\
		echo "evocelot-mariadb started at: http://localhost:3306")

# Stops the local mariadb container.
stop-mariadb-container:
	@echo "Stopping the evocelot-mariadb container"
	$(call run-with-output-indent,\
		podman rm -f evocelot-mariadb)

# Starts the local phpmyadmin container.
start-phpmyadmin-container: stop-phpmyadmin-container
	@echo "Starting phpmyadmin container"
	$(call run-with-output-indent,\
		podman run -d \
		--name evocelot-phpmyadmin \
		--network $(NETWORK_NAME) \
		-p 8000:80 \
		-e PMA_ARBITRARY=1 \
  		--restart always \
  		phpmyadmin:5.2.1; \
		\
		echo "evocelot-phpmyadmin started at: http://localhost:8000")

# Stops the local phpmyadmin container.
stop-phpmyadmin-container:
	@echo "Stopping the evocelot-phpmyadmin container"
	$(call run-with-output-indent,\
		podman rm -f evocelot-phpmyadmin)

# Starts the liquibase container (fire and forget).
start-liquibase-container:
	@echo "Starting liquibase container"
	$(call run-with-output-indent,\
		podman run \
		--network $(NETWORK_NAME) \
		-v ./changelog:/liquibase/changelog \
		liquibase:4.30-alpine \
		--contexts=local \
		--url="jdbc:mariadb://evocelot-mariadb:3306/sample" \
		--username=root \
		--password=admin \
		--changelog-file=/changelog/changelog.xml \
		--driver=org.mariadb.jdbc.Driver \
		update)
