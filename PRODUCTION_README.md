# NEMO Production Deployment Guide

Complete guide for deploying NEMO to production environments.

## Quick Start

### First-Time Setup

1. **Clone Repository**
   ```bash
   git clone https://github.com/Wbaker7702/nemo.git
   cd nemo
   ```

2. **Run Preparation Script**
   ```bash
   ./scripts/prepare-production.sh
   ```

3. **Configure Environment**
   ```bash
   # Copy template and edit
   cp .env.production.template .env.production.local
   nano .env.production.local  # Fill in all values
   ```

4. **Initial Deployment**
   ```bash
   ./deploy.sh
   ```

5. **Verify Deployment**
   ```bash
   ./scripts/production-verify.sh
   ```

## Production Files Overview

### Configuration Files

- **`.env.production.template`** - Environment variables template
- **`.env.production.local`** - Your production environment variables (create from template)
- **`config/database.yml`** - Database configuration
- **`PRODUCTION_CHECKLIST.md`** - Deployment checklist

### Scripts

- **`deploy.sh`** - Main deployment script (automated deployment)
- **`scripts/prepare-production.sh`** - First-time setup script
- **`scripts/production-verify.sh`** - Post-deployment verification

### Documentation

- **`PRODUCTION_README.md`** - This file (quick reference)
- **`docs/DEPLOYMENT.md`** - Complete deployment guide
- **`docs/DEPLOYMENT_HISTORY.md`** - Historical deployment records
- **`PRODUCTION_CHECKLIST.md`** - Pre/post deployment checklist

## Required Configuration

### 1. Environment Variables

Copy `.env.production.template` to `.env.production.local` and configure:

**Critical Variables:**
```bash
NEMO_SECRET_KEY_BASE=<generate-random-64-char-hex>
NEMO_URL_PROTOCOL=https
NEMO_URL_HOST=your-domain.com
NEMO_URL_PORT=443
```

**Email Configuration:**
```bash
NEMO_SITE_EMAIL=nemo@your-domain.com
NEMO_WEBMASTER_EMAILS=admin@your-domain.com
NEMO_SMTP_ADDRESS=smtp.your-domain.com
NEMO_SMTP_PORT=587
NEMO_SMTP_USER_NAME=your-email@your-domain.com
NEMO_SMTP_PASSWORD=your-password
```

**Security:**
```bash
NEMO_RECAPTCHA_PUBLIC_KEY=your-key
NEMO_RECAPTCHA_PRIVATE_KEY=your-key
NEMO_GOOGLE_MAPS_API_KEY=your-key
```

### 2. Database Configuration

Edit `config/database.yml` for production:

```yaml
production:
  adapter: postgresql
  encoding: utf8
  pool: 5
  database: nemo_production
  username: deploy
  password: your-secure-password
  host: localhost
```

### 3. Server Requirements

- **OS**: Ubuntu 20.04+
- **Ruby**: 3.0+ (via rbenv)
- **Node.js**: 20.x (via nvm, required for enketo-core)
- **PostgreSQL**: 12+
- **Nginx**: With Passenger module
- **Memcached**: For caching

## Deployment Process

### Automated Deployment

```bash
cd /home/deploy/nemo
./deploy.sh
```

This script:
1. Creates database backup
2. Pulls latest code
3. Installs dependencies
4. Runs migrations
5. Builds assets
6. Restarts services
7. Verifies deployment

### Manual Deployment

See `docs/DEPLOYMENT.md` for detailed manual steps.

## Post-Deployment

### Verification

```bash
./scripts/production-verify.sh
```

Or manually check:
- Application responds: `curl -I https://your-domain.com`
- Services running: `sudo systemctl status nginx delayed-job`
- Logs clean: `tail -f log/production.log`

### Monitoring

- **Application Logs**: `tail -f log/production.log`
- **Nginx Logs**: `sudo tail -f /var/log/nginx/error.log`
- **Delayed Job**: `sudo journalctl -u delayed-job -f`
- **System Resources**: `htop` or `df -h`

## Troubleshooting

### Common Issues

**Assets Not Loading**
```bash
# Rebuild assets
NODE_ENV=production yarn build
sudo systemctl reload nginx
```

**Database Connection Errors**
```bash
# Test connection
psql -U deploy -d nemo_production -c "SELECT 1"
# Check config
cat config/database.yml
```

**Service Won't Start**
```bash
# Check logs
sudo journalctl -u delayed-job -n 50
tail -n 100 log/production.log
```

**Build Failures**
```bash
# Check Node version (must be 20.x)
node --version
# Reinstall dependencies
rm -rf node_modules
yarn install
```

### Getting Help

1. Check `docs/DEPLOYMENT.md` for detailed procedures
2. Review `docs/DEPLOYMENT_HISTORY.md` for similar issues
3. Check application logs
4. Review GitHub issues

## Security Checklist

- [ ] SSL certificate installed and configured
- [ ] HTTPS enforced (no HTTP redirects)
- [ ] Secret keys are strong and random
- [ ] Database passwords are secure
- [ ] `.env.production.local` not in version control
- [ ] File permissions set correctly
- [ ] Firewall configured
- [ ] SSH key-based authentication only
- [ ] Regular security updates applied

## Maintenance

### Regular Tasks

- **Daily**: Monitor logs and system resources
- **Weekly**: Review error logs, check disk space
- **Monthly**: Update dependencies, review security
- **Quarterly**: Full system backup test

### Updates

```bash
# Update code
git pull origin main
./deploy.sh

# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Ruby gems
bundle update

# Update Node packages
yarn upgrade
```

## Backup & Recovery

### Database Backups

```bash
# Manual backup
pg_dump nemo_production > ~/backups/nemo-$(date +%Y%m%d).sql

# Restore
psql nemo_production < ~/backups/nemo-YYYYMMDD.sql
```

### Automated Backups

Configure cron for regular backups:
```bash
0 2 * * * pg_dump nemo_production > ~/backups/nemo-$(date +\%Y\%m\%d).sql
```

## Optional Features

### AI Validation

To enable AI-powered data validation:

1. Get OpenAI API key from https://platform.openai.com/api-keys
2. Add to `.env.production.local`:
   ```bash
   OPENAI_API_KEY=sk-your-key-here
   ```
3. Feature automatically enabled when API key is present

### Cloud Storage

Configure S3 or Azure storage in `.env.production.local`:
```bash
NEMO_STORAGE_TYPE=cloud  # or 'azure'
NEMO_AWS_ACCESS_KEY_ID=your-key
NEMO_AWS_SECRET_ACCESS_KEY=your-secret
NEMO_AWS_BUCKET=your-bucket
```

## Support & Resources

- **Documentation**: See `docs/` directory
- **Deployment History**: `docs/DEPLOYMENT_HISTORY.md`
- **Production Setup**: `docs/production-setup.md`
- **Architecture**: `docs/architecture.md`

## Version Information

- **Current Version**: 15.1
- **Rails Version**: 8.0
- **Ruby Version**: 3.0+
- **Node Version**: 20.x

---

**Last Updated**: 2024-11-04  
**Maintained By**: NEMO Development Team
