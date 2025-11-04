# Running the NEMO Application

## Current Status

⚠️ **Ruby is not currently installed in this environment.**

The NEMO application requires Ruby to run. Here's how to set it up and run the application.

## Prerequisites

- **Ruby**: 3.0+ (recommended: 3.3.4)
- **Node.js**: 20.x (already installed ✓)
- **PostgreSQL**: Database server
- **Bundler**: Ruby gem manager

## Quick Start

### 1. Install Ruby

#### Option A: Using rbenv (Recommended)
```bash
# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add to PATH
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Install Ruby 3.3.4
rbenv install 3.3.4
rbenv global 3.3.4

# Verify
ruby --version
```

#### Option B: Using System Package Manager
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ruby-full ruby-dev build-essential

# Verify
ruby --version
```

### 2. Install Bundler
```bash
gem install bundler
```

### 3. Install Dependencies
```bash
# Install Ruby gems
bundle install

# Node.js dependencies (already done)
# yarn install
```

### 4. Set Up Database
```bash
# Create database
bundle exec rake db:create

# Run migrations
bundle exec rake db:migrate

# Create admin user (development)
bundle exec rake db:create_admin

# Create sample data (optional, development)
bundle exec rake db:create_fake_data
```

### 5. Start the Application

#### Development Mode
```bash
# Using the provided script
./bin/server

# Or manually
nvm use
bundle exec rails s -p 8443
```

The application will be available at:
- **URL**: http://localhost:8443
- **Default Login**: 
  - Username: `admin`
  - Password: (generated when you ran `db:create_admin`)

#### Production Mode (with static files)
```bash
RAILS_ENV=production RAILS_SERVE_STATIC_FILES=1 bundle exec rails s -p 8443
```

## Server Script

The application includes a convenience script at `bin/server`:

```bash
#!/bin/bash
nvm use
yarn install
bundle exec rails s -p 8443 "$@"
```

Usage:
```bash
./bin/server
# Or with custom bind address
./bin/server -b 0.0.0.0
```

## Port Configuration

- **Default Port**: 8443 (as configured in `.env`)
- **Alternative**: Port 3000 (Rails default)
- **Change Port**: Set `PORT` environment variable:
  ```bash
  PORT=3000 bundle exec rails s
  ```

## Background Jobs

NEMO uses Delayed Job for background processing. Start it separately:

```bash
bin/delayed_job start
```

Or in development:
```bash
bundle exec rake jobs:work
```

## Environment Configuration

### Development
Uses `.env` file (already present):
- Port: 8443
- Database: nemo_development
- Auto-reload: Enabled

### Production
Uses `.env.production.local`:
- Port: 443 (HTTPS)
- Database: nemo_production
- Static files: Served by Rails or Nginx

## Troubleshooting

### Ruby Not Found
```bash
# Check Ruby installation
which ruby
ruby --version

# If using rbenv, ensure it's initialized
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```

### Bundle Not Found
```bash
gem install bundler
bundle install
```

### Database Connection Error
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check database configuration
cat config/database.yml

# Create database if needed
bundle exec rake db:create
```

### Assets Not Loading
```bash
# Rebuild assets
yarn build

# Or with Rails
bundle exec rake assets:precompile
```

### Port Already in Use
```bash
# Find process using port
lsof -i :8443

# Kill process or use different port
PORT=3000 bundle exec rails s
```

## Current Environment Status

✅ **Ready**:
- Node.js 20.19.5 installed
- Yarn 1.22.22 installed
- Production assets built (11 MB)
- Application code ready

❌ **Missing**:
- Ruby (required)
- Bundler (required)
- PostgreSQL (if not already running)
- Rails dependencies (will install with `bundle install`)

## Next Steps

1. **Install Ruby** (see instructions above)
2. **Install Bundler**: `gem install bundler`
3. **Install dependencies**: `bundle install`
4. **Set up database**: `bundle exec rake db:create db:migrate`
5. **Start server**: `./bin/server`

## Additional Resources

- **Development Setup**: See `docs/development-setup.md`
- **Production Setup**: See `PRODUCTION_README.md`
- **Deployment**: See `docs/DEPLOYMENT.md`

---

**Note**: Once Ruby is installed, you can run the application immediately. All other prerequisites (Node.js, assets) are already prepared.
