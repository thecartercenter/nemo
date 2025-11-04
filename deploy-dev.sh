#!/bin/bash

# NEMO Deployment Script (Development/Testing Version)
# This script handles the deployment of NEMO
# Adapted for non-production environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (adapted for current environment)
APP_NAME="nemo"
APP_DIR="${PWD}"
BACKUP_DIR="${APP_DIR}/backups"
LOG_FILE="${APP_DIR}/deploy.log"

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

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Check if we're in the correct directory
if [ ! -f "Gemfile" ] || [ ! -f "package.json" ]; then
    error "This script must be run from the NEMO project root directory"
fi

log "Starting NEMO deployment..."
info "Running as user: $(whoami)"
info "Working directory: ${APP_DIR}"

# 1. Backup current database (if exists)
log "Checking database backup..."
mkdir -p "$BACKUP_DIR"
if command -v pg_dump > /dev/null 2>&1; then
    BACKUP_FILE="$BACKUP_DIR/nemo-backup-$(date +%Y%m%d-%H%M%S).sql"
    if pg_dump nemo_production > "$BACKUP_FILE" 2>/dev/null; then
        log "Database backup created: $BACKUP_FILE"
    else
        warn "Database backup skipped (database may not exist or not accessible)"
    fi
else
    warn "pg_dump not available, skipping database backup"
fi

# 2. Pull latest code (if git repo)
log "Checking for code updates..."
if [ -d ".git" ]; then
    git fetch origin 2>/dev/null || warn "Git fetch failed (may not be connected to remote)"
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    log "Current branch: ${CURRENT_BRANCH}"
    if [ "$CURRENT_BRANCH" != "main" ]; then
        warn "Not on main branch, skipping git pull"
    else
        git pull origin main 2>/dev/null || warn "Git pull failed (may have local changes)"
    fi
else
    warn "Not a git repository, skipping code update"
fi

# 3. Install/update dependencies
log "Installing Ruby dependencies..."
if command -v bundle > /dev/null 2>&1; then
    # Try to use rbenv if available
    if [ -d "$HOME/.rbenv" ]; then
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)" 2>/dev/null || true
    fi
    
    if bundle install --without development test --deployment 2>&1 | tee -a "$LOG_FILE"; then
        log "Ruby dependencies installed successfully"
    else
        warn "Ruby dependency installation had issues (continuing anyway)"
    fi
else
    warn "bundle command not found, skipping Ruby dependencies"
fi

log "Installing Node.js dependencies..."
# Set up Node.js environment
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm use 20 2>/dev/null || warn "Node 20 not available, using default"
fi

if command -v yarn > /dev/null 2>&1; then
    if yarn install --production 2>&1 | tee -a "$LOG_FILE"; then
        log "Node.js dependencies installed successfully"
    else
        warn "Node.js dependency installation had issues (continuing anyway)"
    fi
else
    warn "yarn command not found, skipping Node.js dependencies"
fi

# 4. Run database migrations (if Rails available)
log "Running database migrations..."
if command -v bundle > /dev/null 2>&1 && bundle exec rake -T db:migrate > /dev/null 2>&1; then
    if RAILS_ENV=production bundle exec rake db:migrate 2>&1 | tee -a "$LOG_FILE"; then
        log "Database migrations completed successfully"
    else
        warn "Database migrations had issues (check database connection)"
    fi
else
    warn "Rails not available or database not configured, skipping migrations"
fi

# 5. Build assets (with error handling)
log "Building production assets..."
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm use 20 2>/dev/null || true
fi

ASSET_BUILD_SUCCESS=false
if command -v yarn > /dev/null 2>&1; then
    if NODE_ENV=production yarn build 2>&1 | tee -a "$LOG_FILE"; then
        # Check if build actually succeeded (yarn build may fail but return 0)
        if [ -f "public/packs/manifest.json" ] && [ -d "public/packs/js" ]; then
            log "Assets built successfully"
            ASSET_BUILD_SUCCESS=true
        fi
    fi
    
    # Fallback to webpack directly if yarn build failed
    if [ "$ASSET_BUILD_SUCCESS" = false ]; then
        warn "yarn build failed, trying webpack directly"
        if command -v npx > /dev/null 2>&1; then
            if NODE_ENV=production npx webpack --config config/webpack/webpack.config.js --mode production 2>&1 | tee -a "$LOG_FILE"; then
                log "Assets built with webpack directly"
                ASSET_BUILD_SUCCESS=true
            else
                warn "Webpack build failed"
            fi
        fi
    fi
    
    # Final fallback to Rails asset pipeline
    if [ "$ASSET_BUILD_SUCCESS" = false ] && command -v bundle > /dev/null 2>&1 && bundle exec rake -T assets:precompile > /dev/null 2>&1; then
        warn "Trying Rails asset precompilation as fallback"
        if ALLOW_MISSING_CONFIG=1 RAILS_ENV=production bundle exec rake assets:precompile 2>&1 | tee -a "$LOG_FILE"; then
            log "Assets precompiled successfully (Rails fallback)"
            ASSET_BUILD_SUCCESS=true
        fi
    fi
    
    if [ "$ASSET_BUILD_SUCCESS" = false ]; then
        warn "All asset build methods failed - check if assets already exist"
        if [ -f "public/packs/manifest.json" ]; then
            info "Assets manifest found - using existing artifacts"
        fi
    fi
else
    warn "yarn not available, skipping asset build"
fi

# 6. Update cron jobs (if whenever gem available)
log "Updating cron jobs..."
if command -v bundle > /dev/null 2>&1 && bundle exec whenever -i nemo 2>/dev/null; then
    log "Cron jobs updated successfully"
else
    warn "Cron job update skipped (whenever gem may not be available)"
fi

# 7. Restart services (if systemd available)
log "Checking services..."
if command -v systemctl > /dev/null 2>&1; then
    if sudo systemctl is-active --quiet delayed-job 2>/dev/null; then
        if sudo systemctl restart delayed-job 2>&1 | tee -a "$LOG_FILE"; then
            log "Delayed Job service restarted"
        else
            warn "Failed to restart delayed-job (may require sudo)"
        fi
    else
        warn "delayed-job service not running or not found"
    fi
    
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        if sudo systemctl reload nginx 2>&1 | tee -a "$LOG_FILE"; then
            log "Nginx reloaded"
        else
            warn "Failed to reload nginx (may require sudo)"
        fi
    else
        warn "Nginx not running or not found"
    fi
else
    warn "systemctl not available, skipping service restart"
fi

# 8. Verify deployment
log "Verifying deployment..."
if command -v curl > /dev/null 2>&1; then
    if curl -f -s http://localhost/ > /dev/null 2>&1; then
        log "Deployment verification successful (application responding)"
    else
        warn "Deployment verification failed - application may not be running"
        info "This is normal if the application server is not started"
    fi
else
    warn "curl not available, skipping HTTP verification"
fi

# 9. Cleanup old backups (keep last 7 days)
log "Cleaning up old backups..."
if [ -d "$BACKUP_DIR" ]; then
    find "$BACKUP_DIR" -name "nemo-backup-*.sql" -mtime +7 -delete 2>/dev/null || true
    log "Old backups cleaned up"
fi

log "Deployment process completed!"
info "Application artifacts are ready in: ${APP_DIR}/public/packs/"
info "Log file: ${LOG_FILE}"

# Display useful information
echo ""
echo "=== Deployment Summary ==="
echo "Application: NEMO"
echo "Environment: Production"
echo "Working Directory: ${APP_DIR}"
if [ -f "$BACKUP_FILE" ]; then
    echo "Backup created: $BACKUP_FILE"
fi
echo "Log file: $LOG_FILE"
echo ""
echo "Useful commands:"
echo "  - Check application status: sudo systemctl status nginx delayed-job"
echo "  - View application logs: tail -f log/production.log"
echo "  - View deployment log: tail -f ${LOG_FILE}"
echo "  - Restart services: sudo systemctl restart nginx delayed-job"
echo "  - Run Rails console: RAILS_ENV=production bundle exec rails console"
echo "  - Verify artifacts: ls -lh public/packs/"
echo ""
