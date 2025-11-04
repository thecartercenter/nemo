# NEMO Production Deployment Checklist

Use this checklist to ensure a complete and secure production deployment.

## Pre-Deployment

### Server Setup
- [ ] Ubuntu 20.04+ server provisioned
- [ ] Domain name DNS configured and pointing to server
- [ ] SSH access configured with key-based authentication
- [ ] Firewall configured (ports 22, 80, 443 open)
- [ ] Server updated: `sudo apt update && sudo apt upgrade -y`

### User & Permissions
- [ ] `deploy` user created: `sudo adduser deploy`
- [ ] `deploy` user added to necessary groups
- [ ] SSH access configured for deploy user
- [ ] Sudo privileges configured (if needed)

### System Dependencies
- [ ] PostgreSQL installed and configured
- [ ] Database `nemo_production` created
- [ ] Database user `deploy` created with proper permissions
- [ ] PostgreSQL extensions installed (uuid-ossp, pgcrypto)
- [ ] Nginx installed and configured
- [ ] Passenger module installed for Nginx
- [ ] Memcached installed and running
- [ ] ImageMagick installed (for image processing)
- [ ] Ruby 3.0+ installed (via rbenv/rvm)
- [ ] Node.js 20.x installed (via nvm, required for enketo-core)

### Security
- [ ] SSL certificate obtained (Let's Encrypt recommended)
- [ ] SSL certificate configured in Nginx
- [ ] Firewall rules configured
- [ ] Fail2ban configured (recommended)
- [ ] SSH password authentication disabled
- [ ] Root login disabled (if applicable)

## Configuration

### Environment Variables
- [ ] `.env.production.local` created from template
- [ ] `NEMO_SECRET_KEY_BASE` set (64+ character random hex)
- [ ] `NEMO_URL_PROTOCOL` set to `https`
- [ ] `NEMO_URL_HOST` set to production domain
- [ ] `NEMO_URL_PORT` set to `443`
- [ ] Email configuration set (SMTP settings)
- [ ] reCAPTCHA keys configured
- [ ] Google Maps API key configured
- [ ] Storage configuration set (local/S3/Azure)
- [ ] All placeholder values replaced with real values

### Database Configuration
- [ ] `config/database.yml` configured for production
- [ ] Database credentials secure and not in version control
- [ ] Database connection tested: `psql -U deploy -d nemo_production`

### Application Configuration
- [ ] Application directory: `/home/deploy/nemo`
- [ ] Proper file permissions set
- [ ] Git repository cloned and configured
- [ ] Correct branch checked out (`main`)

### Nginx Configuration
- [ ] Nginx config file created/updated
- [ ] Passenger configuration correct
- [ ] SSL configuration correct
- [ ] Static file serving configured
- [ ] Client max body size matches upload limit
- [ ] Nginx config tested: `sudo nginx -t`

### Background Jobs
- [ ] Delayed Job systemd service configured
- [ ] Service enabled: `sudo systemctl enable delayed-job`
- [ ] Worker processes configured appropriately

### Cron Jobs
- [ ] Whenever gem configured
- [ ] Cron jobs set up: `bundle exec whenever -i nemo`
- [ ] Cron jobs verified: `crontab -l`

## Deployment

### Backup
- [ ] Backup directory created: `mkdir -p ~/backups`
- [ ] Database backup created before deployment
- [ ] Backup verified (check file size and timestamp)

### Code Deployment
- [ ] Latest code pulled: `git pull origin main`
- [ ] Correct commit/version verified: `git log -1`
- [ ] Working directory clean: `git status`

### Dependencies
- [ ] Ruby gems installed: `bundle install --without development test --deployment`
- [ ] Bundle verified: `bundle check`
- [ ] Node.js version set: `nvm use 20`
- [ ] Node version verified: `node --version` (should be 20.x)
- [ ] npm packages installed: `yarn install --production`
- [ ] Yarn verified: `yarn check`

### Database
- [ ] Migrations run: `RAILS_ENV=production bundle exec rake db:migrate`
- [ ] Migration status checked: `RAILS_ENV=production bundle exec rake db:migrate:status`
- [ ] No pending migrations remaining

### Assets
- [ ] Assets precompiled: `yarn build` or `RAILS_ENV=production bundle exec rake assets:precompile`
- [ ] Manifest file exists: `ls -lh public/packs/manifest.json`
- [ ] Asset files present: `ls -lh public/packs/js/`
- [ ] Asset sizes reasonable (not unexpectedly large)

### Services
- [ ] Delayed Job restarted: `sudo systemctl restart delayed-job`
- [ ] Nginx reloaded: `sudo systemctl reload nginx`
- [ ] Services status checked: `sudo systemctl status nginx delayed-job`

## Post-Deployment Verification

### Health Checks
- [ ] Application responds: `curl -I https://your-domain.com`
- [ ] Ping endpoint works: `curl https://your-domain.com/ping`
- [ ] SSL certificate valid (check in browser)
- [ ] No SSL warnings or errors

### Functionality Tests
- [ ] Homepage loads correctly
- [ ] User login works
- [ ] Forms can be created/edited
- [ ] Responses can be submitted
- [ ] Reports generate correctly
- [ ] Search functionality works
- [ ] API endpoints respond
- [ ] File uploads work
- [ ] Email sending works (test password reset)
- [ ] Background jobs processing

### Performance Checks
- [ ] Page load times acceptable (< 3 seconds)
- [ ] Asset files loading (check browser Network tab)
- [ ] No 404 errors for assets
- [ ] Database queries performing well
- [ ] Memory usage reasonable
- [ ] CPU usage normal
- [ ] Disk space adequate

### Log Checks
- [ ] No errors in `log/production.log`
- [ ] No errors in `/var/log/nginx/error.log`
- [ ] No errors in delayed-job logs: `sudo journalctl -u delayed-job`
- [ ] No critical warnings

### Security Checks
- [ ] HTTPS enforced (no HTTP redirects to HTTPS)
- [ ] Security headers present (check response headers)
- [ ] Sensitive files not accessible (.env, database.yml)
- [ ] Error pages don't expose sensitive information
- [ ] CSRF protection working

## Monitoring Setup

### Logging
- [ ] Log rotation configured
- [ ] Log monitoring set up (optional: Logwatch, Logrotate)
- [ ] Error alerting configured (if using Sentry)

### Monitoring Tools
- [ ] Server monitoring configured (optional: Scout, New Relic)
- [ ] Uptime monitoring configured
- [ ] Disk space monitoring configured
- [ ] Database monitoring configured

### Backup Automation
- [ ] Automated database backups configured
- [ ] Backup retention policy set
- [ ] Backup restoration tested
- [ ] Off-site backup configured (recommended)

## Documentation

### Deployment Records
- [ ] Deployment logged in `docs/DEPLOYMENT_HISTORY.md`
- [ ] Version/commit hash recorded
- [ ] Changes documented
- [ ] Known issues noted

### Configuration Documentation
- [ ] Environment variables documented
- [ ] Custom configurations documented
- [ ] Service configurations documented

## Optional Features

### AI Validation (if using)
- [ ] `OPENAI_API_KEY` configured in environment
- [ ] AI validation endpoints tested
- [ ] Cost monitoring set up (optional)

### Advanced Features
- [ ] S3/Azure storage configured (if using cloud storage)
- [ ] CDN configured (if using)
- [ ] Redis configured (if using for caching)
- [ ] Elasticsearch configured (if using for search)

## Rollback Plan (if needed)

- [ ] Last known good commit identified
- [ ] Database backup available
- [ ] Rollback procedure documented
- [ ] Rollback tested (in staging if possible)

## Sign-Off

- [ ] All critical items checked
- [ ] Application tested and verified
- [ ] Team notified of deployment
- [ ] Monitoring active and alerting configured

---

**Deployment Date**: _______________  
**Deployed By**: _______________  
**Version/Commit**: _______________  
**Sign-Off**: _______________

## Notes

_Use this space to document any issues, custom configurations, or special considerations for this deployment._
