#!/bin/bash

set -e

# Create a users table in the pong database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "pong" <<-EOSQL
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(128) NOT NULL
    );
EOSQL

echo "Database initialization complete."
