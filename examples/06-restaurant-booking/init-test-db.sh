#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE restaurant_booking_test;
EOSQL
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d restaurant_booking_test -f /docker-entrypoint-initdb.d/01-init.sql
