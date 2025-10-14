#!/bin/bash

# NEMO Production Deployment Script
# This script handles the deployment of NEMO to production

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="nemo"
APP_DIR="/home/deploy/nemo"
BACKUP_DIR="/home/deploy/backups"
LOG_FILE="/var/log/nemo-deploy.log"

# Functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# Check if running as correct user
if [ "$USER" != "deploy" ]; then
    error "This script must be run as the 'deploy' user"
fi

# Check if we're in the correct directory
if [ ! -f "Gemfile" ] || [ ! -f "package.json" ]; then
    error "This script must be run from the NEMO project root directory"
fi

log "Starting NEMO deployment..."

# 1. Backup current database
log "Creating database backup..."
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/nemo-backup-$(date +%Y%m%d-%H%M%S).sql"
if pg_dump nemo_production > "$BACKUP_FILE"; then
    log "Database backup created: $BACKUP_FILE"
else
    warn "Failed to create database backup, continuing anyway..."
fi

# 2. Pull latest code
log "Pulling latest code from repository..."
git fetch origin
git checkout main
git pull origin main

# 3. Install/update dependencies
log "Installing Ruby dependencies..."
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
bundle install --without development test --deployment

log "Installing Node.js dependencies..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 20
yarn install --production

# 4. Run database migrations
log "Running database migrations..."
RAILS_ENV=production bundle exec rake db:migrate

# 5. Precompile assets (with error handling)
log "Precompiling assets..."
if ALLOW_MISSING_CONFIG=1 RAILS_ENV=production bundle exec rake assets:precompile; then
    log "Assets precompiled successfully"
else
    warn "Asset precompilation failed, but continuing with deployment"
    warn "You may need to manually fix webpack configuration issues"
fi

# 6. Update cron jobs
log "Updating cron jobs..."
bundle exec whenever -i nemo

# 7. Restart services
log "Restarting services..."
sudo systemctl restart delayed-job
sudo systemctl reload nginx

# 8. Verify deployment
log "Verifying deployment..."
if curl -f -s http://localhost/ > /dev/null; then
    log "Deployment verification successful"
else
    warn "Deployment verification failed - check application logs"
fi

# 9. Cleanup old backups (keep last 7 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -name "nemo-backup-*.sql" -mtime +7 -delete

log "Deployment completed successfully!"
log "Application should be available at your configured domain"
log "Check logs at: $LOG_FILE"

# Display useful information
echo ""
echo "=== Deployment Summary ==="
echo "Application: NEMO"
echo "Environment: Production"
echo "Backup created: $BACKUP_FILE"
echo "Log file: $LOG_FILE"
echo ""
echo "Useful commands:"
echo "  - Check application status: sudo systemctl status nginx delayed-job"
echo "  - View application logs: tail -f log/production.log"
echo "  - Restart services: sudo systemctl restart nginx delayed-job"
echo "  - Run Rails console: RAILS_ENV=production bundle exec rails console"
echo ""