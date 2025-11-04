#!/bin/bash

# NEMO Production Verification Script
# Run this after deployment to verify everything is working correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${NEMO_DOMAIN:-localhost}"
PROTOCOL="${NEMO_PROTOCOL:-https}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NEMO Production Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print results
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 1. Check services
echo -e "${BLUE}1. Checking Services...${NC}"
if systemctl is-active --quiet nginx; then
    pass "Nginx is running"
else
    fail "Nginx is not running"
fi

if systemctl is-active --quiet delayed-job; then
    pass "Delayed Job is running"
else
    fail "Delayed Job is not running"
fi

if systemctl is-active --quiet postgresql; then
    pass "PostgreSQL is running"
else
    fail "PostgreSQL is not running"
fi

if systemctl is-active --quiet memcached; then
    pass "Memcached is running"
else
    warn "Memcached is not running (optional)"
fi

echo ""

# 2. Check application files
echo -e "${BLUE}2. Checking Application Files...${NC}"
if [ -f "Gemfile" ]; then
    pass "Gemfile exists"
else
    fail "Gemfile not found"
fi

if [ -f "package.json" ]; then
    pass "package.json exists"
else
    fail "package.json not found"
fi

if [ -f "public/packs/manifest.json" ]; then
    pass "Asset manifest exists"
else
    fail "Asset manifest not found - assets may not be compiled"
fi

if [ -d "public/packs/js" ] && [ "$(ls -A public/packs/js/*.js 2>/dev/null)" ]; then
    pass "JavaScript assets exist"
else
    fail "JavaScript assets not found"
fi

echo ""

# 3. Check environment
echo -e "${BLUE}3. Checking Environment...${NC}"
if [ -f ".env.production.local" ]; then
    pass ".env.production.local exists"
    
    # Check critical variables
    if grep -q "NEMO_SECRET_KEY_BASE=" .env.production.local && ! grep -q "XXXXXXXXXXXXXXXX" .env.production.local; then
        pass "NEMO_SECRET_KEY_BASE is set"
    else
        fail "NEMO_SECRET_KEY_BASE not properly configured"
    fi
    
    if grep -q "NEMO_URL_PROTOCOL=https" .env.production.local; then
        pass "HTTPS protocol configured"
    else
        warn "HTTPS protocol not configured"
    fi
else
    warn ".env.production.local not found (using default .env)"
fi

echo ""

# 4. Check database
echo -e "${BLUE}4. Checking Database...${NC}"
if RAILS_ENV=production bundle exec rake db:migrate:status > /dev/null 2>&1; then
    pass "Database connection works"
    
    PENDING=$(RAILS_ENV=production bundle exec rake db:migrate:status 2>/dev/null | grep "down" | wc -l)
    if [ "$PENDING" -eq 0 ]; then
        pass "No pending migrations"
    else
        warn "$PENDING pending migration(s)"
    fi
else
    fail "Database connection failed"
fi

echo ""

# 5. Check HTTP response
echo -e "${BLUE}5. Checking HTTP Response...${NC}"
URL="${PROTOCOL}://${DOMAIN}"

if command -v curl > /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        pass "Application responds (HTTP $HTTP_CODE)"
    else
        fail "Application not responding correctly (HTTP $HTTP_CODE)"
    fi
    
    # Check ping endpoint
    PING_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${URL}/ping" || echo "000")
    if [ "$PING_CODE" = "200" ]; then
        pass "Ping endpoint works"
    else
        warn "Ping endpoint not responding (HTTP $PING_CODE)"
    fi
else
    warn "curl not available, skipping HTTP checks"
fi

echo ""

# 6. Check logs for errors
echo -e "${BLUE}6. Checking Recent Errors...${NC}"
if [ -f "log/production.log" ]; then
    ERROR_COUNT=$(tail -n 1000 log/production.log | grep -i "error\|fatal\|exception" | grep -v "DEPRECATION" | wc -l)
    if [ "$ERROR_COUNT" -eq 0 ]; then
        pass "No recent errors in production.log"
    else
        warn "$ERROR_COUNT recent error(s) in production.log (check logs)"
    fi
else
    warn "production.log not found"
fi

if [ -f "/var/log/nginx/error.log" ]; then
    NGINX_ERRORS=$(sudo tail -n 100 /var/log/nginx/error.log | grep -i "error" | wc -l)
    if [ "$NGINX_ERRORS" -eq 0 ]; then
        pass "No recent Nginx errors"
    else
        warn "$NGINX_ERRORS recent error(s) in Nginx log"
    fi
else
    warn "Nginx error log not found"
fi

echo ""

# 7. Check disk space
echo -e "${BLUE}7. Checking Disk Space...${NC}"
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    pass "Disk usage: ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -lt 90 ]; then
    warn "Disk usage: ${DISK_USAGE}% (getting high)"
else
    fail "Disk usage: ${DISK_USAGE}% (critical)"
fi

echo ""

# 8. Check memory
echo -e "${BLUE}8. Checking Memory...${NC}"
if command -v free > /dev/null; then
    MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$MEM_USAGE" -lt 90 ]; then
        pass "Memory usage: ${MEM_USAGE}%"
    else
        warn "Memory usage: ${MEM_USAGE}% (high)"
    fi
else
    warn "free command not available"
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verification Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "For detailed logs, check:"
echo "  - Application: tail -f log/production.log"
echo "  - Nginx: sudo tail -f /var/log/nginx/error.log"
echo "  - Delayed Job: sudo journalctl -u delayed-job -f"
echo ""
