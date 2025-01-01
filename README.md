# liquibase-base

The project provides a general solution for starting Liquibase-based projects. The goal of the project is to define the folder structure and commands that make it easy to manage a database schema using Liquibase.

## Technologies Used

- Docker / Podman
- Make
- mariadb:11.6.2
- liquibase:4.30-alpine

## The steps of the startup

First, a running DBMS instance is required. If you want to start a local MariaDB container, you can do so by running the following command:

```bash
make start-mariadb-container
```

Next, to run the Liquibase scripts, execute the following command:

```bash
make start-liquibase-container
```

> **_NOTE:_** Note that in order to achieve proper functionality, it is essential that the MariaDB container completes its initialization process before you run this command.

### Starting the DBMS Client (optional)

If you need a DBMS client, you can start one in a local container by running the following command:

```bash
make start-phpmyadmin-container
```

> **_NOTE:_** The default username is `root` and the password is `admin`. The server name is `evocelot-mariadb`.

## DB init script

When the MariaDB container starts, the `schema_local_create.sql` script is automatically executed. Here you can define the default schema and other settings.
