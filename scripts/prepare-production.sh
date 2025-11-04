#!/bin/bash

# NEMO Production Preparation Script
# Run this script to prepare the codebase for production deployment
# This should be run on the production server before first deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NEMO Production Preparation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as deploy user
if [ "$USER" != "deploy" ]; then
    echo -e "${YELLOW}Warning: Not running as 'deploy' user${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 1. Create necessary directories
echo -e "${BLUE}1. Creating directories...${NC}"
mkdir -p ~/backups
mkdir -p tmp/pids
mkdir -p tmp/cache
mkdir -p log
mkdir -p public/packs
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# 2. Set up environment file
echo -e "${BLUE}2. Setting up environment file...${NC}"
if [ ! -f ".env.production.local" ]; then
    if [ -f ".env.production.template" ]; then
        cp .env.production.template .env.production.local
        echo -e "${GREEN}✓ Created .env.production.local from template${NC}"
        echo -e "${YELLOW}⚠ IMPORTANT: Edit .env.production.local with your production values${NC}"
    else
        echo -e "${YELLOW}⚠ .env.production.template not found, creating basic .env.production.local${NC}"
        cat > .env.production.local << 'EOF'
# Production Environment Variables
# Fill in all values before deploying

NEMO_SECRET_KEY_BASE=CHANGE_ME
NEMO_URL_PROTOCOL=https
NEMO_URL_HOST=your-domain.com
NEMO_URL_PORT=443
EOF
    fi
else
    echo -e "${GREEN}✓ .env.production.local already exists${NC}"
fi
echo ""

# 3. Set up Ruby environment
echo -e "${BLUE}3. Setting up Ruby environment...${NC}"
if command -v rbenv > /dev/null; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    RUBY_VERSION=$(rbenv version-name)
    echo -e "${GREEN}✓ Ruby version: $RUBY_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ rbenv not found, using system Ruby${NC}"
fi

if [ -f "Gemfile" ]; then
    echo "Installing Ruby dependencies..."
    bundle install --without development test --deployment
    echo -e "${GREEN}✓ Ruby dependencies installed${NC}"
else
    echo -e "${RED}✗ Gemfile not found${NC}"
fi
echo ""

# 4. Set up Node.js environment
echo -e "${BLUE}4. Setting up Node.js environment...${NC}"
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    
    # Check if Node 20 is installed
    if nvm list 20 > /dev/null 2>&1; then
        nvm use 20
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✓ Node.js version: $NODE_VERSION${NC}"
    else
        echo "Installing Node.js 20..."
        nvm install 20
        nvm use 20
        echo -e "${GREEN}✓ Node.js 20 installed${NC}"
    fi
    
    # Install Yarn if not present
    if ! command -v yarn > /dev/null; then
        echo "Installing Yarn..."
        npm install -g yarn@1.22.22
        echo -e "${GREEN}✓ Yarn installed${NC}"
    fi
    
    if [ -f "package.json" ]; then
        echo "Installing Node.js dependencies..."
        yarn install --production
        echo -e "${GREEN}✓ Node.js dependencies installed${NC}"
    else
        echo -e "${RED}✗ package.json not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ nvm not found. Please install Node.js 20 manually${NC}"
fi
echo ""

# 5. Verify database connection
echo -e "${BLUE}5. Verifying database connection...${NC}"
if RAILS_ENV=production bundle exec rake db:migrate:status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${YELLOW}⚠ Database connection failed. Check config/database.yml and .env.production.local${NC}"
fi
echo ""

# 6. Set permissions
echo -e "${BLUE}6. Setting file permissions...${NC}"
chmod +x bin/* 2>/dev/null || true
chmod +x deploy.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Preparation Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Edit .env.production.local with your production values"
echo "2. Configure database.yml if needed"
echo "3. Run database migrations: RAILS_ENV=production bundle exec rake db:migrate"
echo "4. Build assets: yarn build"
echo "5. Run deployment: ./deploy.sh"
echo "6. Verify deployment: ./scripts/production-verify.sh"
echo ""
