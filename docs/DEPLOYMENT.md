# NEMO Deployment Guide

Complete guide for deploying NEMO to production environments.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Deployment Steps](#detailed-deployment-steps)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Rollback Procedures](#rollback-procedures)
6. [Historical Deployments](#historical-deployments)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Server Requirements
- Ubuntu 20.04+ (recommended)
- Minimum 4GB RAM
- 20GB+ disk space
- PostgreSQL 12+
- Node.js 20.x (required for enketo-core compatibility)
- Ruby 3.0+ (managed via rbenv or rvm)

### Access Requirements
- SSH access to production server
- Sudo privileges
- Database access credentials
- GitHub repository access

### Environment Setup
- Domain name pointing to server IP
- SSL certificate (Let's Encrypt recommended)
- Email configuration for notifications
- Required environment variables (see `.env.example`)

## Quick Start

### Automated Deployment

```bash
# On production server as 'deploy' user
cd /home/deploy/nemo
./deploy.sh
```

The deployment script handles:
- Database backup
- Code updates
- Dependency installation
- Asset compilation
- Service restarts
- Verification

### Manual Deployment

```bash
# 1. Backup database
pg_dump nemo_production > backup-$(date +%Y%m%d).sql

# 2. Pull latest code
git pull origin main

# 3. Install dependencies
bundle install --without development test --deployment
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh"
nvm use 20
yarn install --production

# 4. Run migrations
RAILS_ENV=production bundle exec rake db:migrate

# 5. Build assets
RAILS_ENV=production bundle exec rake assets:precompile
# OR use yarn build if using shakapacker directly
NODE_ENV=production yarn build

# 6. Restart services
sudo systemctl restart nginx delayed-job
```

## Detailed Deployment Steps

### 1. Pre-Deployment Checklist

- [ ] Review recent commits and changes
- [ ] Check for breaking changes in CHANGELOG
- [ ] Verify database migrations are tested
- [ ] Confirm environment variables are set
- [ ] Check server disk space
- [ ] Verify backup system is working
- [ ] Schedule maintenance window if needed

### 2. Database Backup

**Critical**: Always backup before deployment!

```bash
# Create backup directory
mkdir -p ~/backups

# Full database backup
pg_dump nemo_production > ~/backups/nemo-backup-$(date +%Y%m%d-%H%M%S).sql

# Verify backup
ls -lh ~/backups/nemo-backup-*.sql
```

### 3. Code Deployment

```bash
# Navigate to application directory
cd /home/deploy/nemo

# Fetch latest changes
git fetch origin

# Review changes (optional)
git log HEAD..origin/main

# Pull latest code
git checkout main
git pull origin main

# Verify current commit
git log -1
```

### 4. Dependency Installation

#### Ruby Dependencies

```bash
# Load rbenv/rvm
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Install gems
bundle install --without development test --deployment

# Verify installation
bundle check
```

#### Node.js Dependencies

```bash
# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Use correct Node version (required for enketo-core)
nvm use 20

# Verify Node version
node --version  # Should be 20.x.x

# Install dependencies
yarn install --production

# Verify installation
yarn check
```

### 5. Database Migrations

```bash
# Run migrations
RAILS_ENV=production bundle exec rake db:migrate

# Verify migration status
RAILS_ENV=production bundle exec rake db:migrate:status

# Check for pending migrations
RAILS_ENV=production bundle exec rake db:migrate:status | grep "down"
```

**Note**: Always test migrations in staging first!

### 6. Asset Compilation

#### Option A: Using Rails Asset Pipeline (Traditional)

```bash
RAILS_ENV=production bundle exec rake assets:precompile
```

#### Option B: Using Shakapacker/Webpack (Current)

```bash
# Set Node environment
export NODE_ENV=production

# Build assets
yarn build

# OR use Rails task
RAILS_ENV=production bundle exec rake shakapacker:compile
```

**Verify Assets**:
```bash
# Check manifest exists
ls -lh public/packs/manifest.json

# Verify asset files
ls -lh public/packs/js/
```

### 7. Environment Configuration

```bash
# Review environment variables
cat .env | grep -v "^#" | grep -v "^$"

# Verify critical variables
echo $NEMO_SECRET_KEY_BASE | wc -c  # Should be 128+ characters
echo $DATABASE_URL  # Should be set
```

### 8. Cron Jobs Update

```bash
# Update whenever cron jobs
bundle exec whenever -i nemo

# Verify cron jobs
crontab -l | grep nemo
```

### 9. Service Restart

```bash
# Restart delayed job workers
sudo systemctl restart delayed-job

# Reload nginx (zero-downtime)
sudo systemctl reload nginx

# OR restart nginx if needed
sudo systemctl restart nginx

# Check service status
sudo systemctl status nginx delayed-job
```

### 10. Cache Clearing

```bash
# Clear Rails cache
RAILS_ENV=production bundle exec rake tmp:clear
RAILS_ENV=production bundle exec rake cache:clear

# Restart memcached if needed
sudo systemctl restart memcached
```

## Post-Deployment Verification

### Health Checks

```bash
# Basic connectivity
curl -I https://your-domain.com

# Ping endpoint
curl https://your-domain.com/ping

# Check response time
time curl -s https://your-domain.com > /dev/null
```

### Application Checks

```bash
# Check Rails logs for errors
tail -f log/production.log | grep -i error

# Check nginx logs
sudo tail -f /var/log/nginx/error.log

# Check delayed job logs
sudo journalctl -u delayed-job -f
```

### Functional Verification

- [ ] Homepage loads correctly
- [ ] User login works
- [ ] Forms can be created/edited
- [ ] Responses can be submitted
- [ ] Reports generate correctly
- [ ] Search functionality works
- [ ] API endpoints respond
- [ ] Background jobs process

### Performance Checks

```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check CPU usage
top -bn1 | head -20
```

## Rollback Procedures

### Quick Rollback (Recent Deployment)

```bash
# 1. Identify last good commit
git log --oneline -10

# 2. Revert to that commit
git checkout <commit-hash>

# 3. Rebuild assets if needed
yarn build

# 4. Restart services
sudo systemctl restart nginx delayed-job

# 5. Verify
curl -I https://your-domain.com
```

### Full Rollback (With Database)

```bash
# 1. Stop services
sudo systemctl stop nginx delayed-job

# 2. Revert code
git checkout <last-good-commit>

# 3. Restore database backup
psql nemo_production < ~/backups/nemo-backup-YYYYMMDD-HHMMSS.sql

# 4. Rebuild assets
yarn build

# 5. Restart services
sudo systemctl start delayed-job
sudo systemctl start nginx

# 6. Verify
curl -I https://your-domain.com
```

### Database-Only Rollback

```bash
# If only database needs rollback
# Restore specific backup
psql nemo_production < ~/backups/nemo-backup-YYYYMMDD-HHMMSS.sql

# OR rollback specific migration
RAILS_ENV=production bundle exec rake db:rollback STEP=1
```

## Historical Deployments

See [DEPLOYMENT_HISTORY.md](./DEPLOYMENT_HISTORY.md) for complete deployment history, including:
- All deployments with dates and versions
- Changes included in each deployment
- Known issues and resolutions
- Rollback procedures used

## Troubleshooting

### Common Issues

#### Assets Not Loading

```bash
# Check manifest file
cat public/packs/manifest.json

# Verify asset files exist
ls -lh public/packs/js/

# Check nginx configuration
sudo nginx -t

# Clear browser cache or test in incognito
```

#### Database Connection Errors

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
psql -U deploy -d nemo_production -c "SELECT 1"

# Check database.yml configuration
cat config/database.yml
```

#### Service Won't Start

```bash
# Check service logs
sudo journalctl -u delayed-job -n 50
sudo journalctl -u nginx -n 50

# Check Rails logs
tail -n 100 log/production.log

# Verify permissions
ls -la /home/deploy/nemo
```

#### Build Failures

```bash
# Check Node version
node --version  # Must be 20.x

# Clear node modules and reinstall
rm -rf node_modules
yarn install

# Check webpack config
cat config/webpack/webpack.config.js
```

### Getting Help

1. Check deployment logs: `/var/log/nemo-deploy.log`
2. Review application logs: `log/production.log`
3. Check [DEPLOYMENT_HISTORY.md](./DEPLOYMENT_HISTORY.md) for similar issues
4. Review GitHub issues
5. Contact DevOps team

## Deployment Best Practices

1. **Always backup first** - Database and code
2. **Test in staging** - Deploy to staging before production
3. **Deploy during low-traffic** - Schedule maintenance windows
4. **Monitor after deployment** - Watch logs for 15-30 minutes
5. **Have rollback plan** - Know how to revert quickly
6. **Document changes** - Update DEPLOYMENT_HISTORY.md
7. **Communicate** - Notify team of deployments
8. **Verify** - Always verify deployment success

## Related Documentation

- [Production Setup Guide](./production-setup.md) - Initial server setup
- [Development Setup Guide](./development-setup.md) - Local development
- [Architecture Documentation](./architecture.md) - System architecture
- [Deployment History](./DEPLOYMENT_HISTORY.md) - Historical deployments

---

**Last Updated**: 2024-11-04  
**Maintained By**: NEMO Development Team
