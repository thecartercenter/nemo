#!/bin/bash

# Quick start script for NEMO Docker setup

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NEMO Docker Quick Start${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed.${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}Docker Compose is not installed.${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Determine compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo -e "${GREEN}Starting NEMO services...${NC}"
echo ""

# Start database and memcached first
echo "Starting database and cache..."
$COMPOSE_CMD up -d db memcached

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 5

# Check if database needs setup
if ! $COMPOSE_CMD exec -T db psql -U nemo -d nemo_development -c "SELECT 1" &> /dev/null; then
    echo -e "${YELLOW}Database doesn't exist, creating...${NC}"
    $COMPOSE_CMD run --rm web bundle exec rake db:create || true
fi

# Run migrations
echo "Running database migrations..."
$COMPOSE_CMD run --rm web bundle exec rake db:migrate || true

# Create admin user if it doesn't exist
echo "Setting up admin user..."
$COMPOSE_CMD run --rm web bundle exec rake db:create_admin || true

# Start web application
echo -e "${GREEN}Starting web application...${NC}"
$COMPOSE_CMD up web

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}NEMO is running!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Application URL: http://localhost:8443"
echo ""
echo "Useful commands:"
echo "  - View logs: $COMPOSE_CMD logs -f"
echo "  - Stop: $COMPOSE_CMD down"
echo "  - Rails console: $COMPOSE_CMD run --rm web bundle exec rails console"
echo ""
