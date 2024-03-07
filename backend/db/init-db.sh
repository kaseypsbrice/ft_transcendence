#!/bin/bash

set -e

# Create a users table in the pong database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "pong" <<-EOSQL
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(128) NOT NULL,
		display_name VARCHAR(40) UNIQUE NOT NULL,
		friends INT [],
		blocked INT [],
		snake_wins INT DEFAULT 0,
		snake_losses INT DEFAULT 0,
		pong_wins INT DEFAULT 0,
		pong_losses INT DEFAULT 0,
		pong_tournament_wins INT DEFAULT 0,
		snake_tournament_wins INT DEFAULT 0
    );
	CREATE TABLE IF NOT EXISTS matches (
		time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		game VARCHAR(16) NOT NULL,
        winner INT NOT NULL,
		loser INT NOT NULL,
		info VARCHAR(32)
    );
	CREATE TABLE IF NOT EXISTS profile_pictures (
		id INT NOT NULL,
		image BYTEA
	);
EOSQL

echo "Database initialization complete."
