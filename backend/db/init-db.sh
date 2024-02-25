#!/bin/bash

set -e

# Create a users table in the pong database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "pong" <<-EOSQL
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(128) NOT NULL,
		display_name VARCHAR(40) UNIQUE NOT NULL
    );
	CREATE TABLE IF NOT EXISTS matches (
		game VARCHAR(16) NOT NULL,
        player1 INT NOT NULL,
        player2 INT NOT NULL,
        winner INT NOT NULL,
		info VARCHAR(32)
    );
EOSQL

echo "Database initialization complete."
