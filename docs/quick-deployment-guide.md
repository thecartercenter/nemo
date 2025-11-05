# Quick Deployment Guide

This guide provides quick commands and instructions for deploying NEMO.

## Automated Deployment (Recommended)

### Via GitHub Actions (CI/CD)

The easiest way to deploy is through the automated CI/CD pipeline:

1. **Deploy to Staging:**
   ```bash
   git checkout develop
   git pull origin develop
   git push origin develop
   ```
   The workflow automatically deploys to staging.

2. **Deploy to Production:**
   ```bash
   git checkout main
   git pull origin main
   git merge develop
   git push origin main
   ```
   The workflow automatically deploys to production.

3. **Manual Trigger:**
   - Go to GitHub Actions tab
   - Select "Build and Deploy" workflow
   - Click "Run workflow"
   - Choose environment (staging/production)
   - Click "Run workflow" button

## Manual Deployment

If you need to deploy manually (not recommended for production):

### Prerequisites
```bash
# Ensure you have the correct versions
ruby --version    # Should be 3.3.4+
node --version    # Should be 20.x
yarn --version    # Should be 1.22.22
```

### Deployment Steps

1. **Navigate to project directory:**
   ```bash
   cd /path/to/nemo
   ```

2. **Pull latest code:**
   ```bash
   git fetch origin
   git checkout main
   git pull origin main
   ```

3. **Run deployment script:**
   ```bash
   ./deploy.sh
   ```

The `deploy.sh` script handles:
- Database backup
- Dependency installation
- Database migrations
- Asset compilation
- Service restart
- Verification

### Using Docker

1. **Build and deploy with Docker Compose:**
   ```bash
   # Production
   docker-compose -f docker-compose.prod.yml up -d --build

   # Development
   docker-compose up -d --build
   ```

2. **View logs:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs -f
   ```

3. **Stop services:**
   ```bash
   docker-compose -f docker-compose.prod.yml down
   ```

## Verification

After deployment, verify the application:

```bash
# Check application is responding
curl -I https://your-domain.com

# Check services are running
sudo systemctl status nginx delayed-job

# Check logs for errors
tail -f log/production.log

# Verify database connectivity
RAILS_ENV=production bundle exec rails runner "puts User.count"
```

## Rollback

If deployment fails, rollback to previous version:

```bash
# Stop services
sudo systemctl stop delayed-job

# Restore database from backup
psql nemo_production < ~/backups/nemo-YYYYMMDD.sql

# Checkout previous commit
git log --oneline -10  # Find previous stable commit
git checkout <commit-sha>

# Re-deploy
./deploy.sh

# Or revert the merge commit
git revert -m 1 <merge-commit-sha>
git push origin main
```

## Environment-Specific Commands

### Staging
```bash
# SSH to staging server
ssh deploy@staging.nemo.example.com

# Deploy
cd /home/deploy/nemo
git pull origin develop
./deploy.sh

# Check status
sudo systemctl status nginx delayed-job
```

### Production
```bash
# SSH to production server
ssh deploy@nemo.example.com

# Deploy
cd /home/deploy/nemo
git pull origin main
./deploy.sh

# Check status
sudo systemctl status nginx delayed-job
```

## Common Tasks

### Update Dependencies
```bash
# Ruby gems
bundle update
bundle install

# Node packages
yarn upgrade
yarn install
```

### Rebuild Assets
```bash
# Using yarn (preferred)
NODE_ENV=production yarn build

# Using Rails
RAILS_ENV=production bundle exec rake assets:precompile

# Clean old assets
bundle exec rake assets:clobber
```

### Database Operations
```bash
# Run migrations
RAILS_ENV=production bundle exec rake db:migrate

# Rollback last migration
RAILS_ENV=production bundle exec rake db:rollback

# Reset database (DANGER: deletes all data)
RAILS_ENV=production bundle exec rake db:reset
```

### Restart Services
```bash
# Restart all services
sudo systemctl restart nginx delayed-job

# Restart individual services
sudo systemctl restart nginx
sudo systemctl restart delayed-job

# Reload nginx (no downtime)
sudo systemctl reload nginx
```

## Troubleshooting

### Build Failures
```bash
# Check Node version
node --version  # Must be 20.x

# Reinstall dependencies
rm -rf node_modules
yarn install

# Clear cache
rm -rf tmp/cache
```

### Service Issues
```bash
# Check logs
sudo journalctl -u delayed-job -n 50
tail -n 100 log/production.log

# Check process status
ps aux | grep rails
ps aux | grep delayed_job

# Check port availability
sudo netstat -tlnp | grep :8443
```

### Database Issues
```bash
# Test connection
psql -U deploy -d nemo_production -c "SELECT 1"

# Check migrations
RAILS_ENV=production bundle exec rake db:migrate:status

# Reset connection pool
sudo systemctl restart delayed-job
```

## Emergency Procedures

### Application Down
1. Check service status
2. Review error logs
3. Restart services
4. If persists, rollback to previous version

### Database Issues
1. Check database connectivity
2. Review migration status
3. Restore from backup if needed
4. Re-run migrations

### Asset Loading Issues
1. Rebuild assets
2. Clear browser cache
3. Restart web server
4. Check file permissions

## Monitoring

### Real-time Monitoring
```bash
# Application logs
tail -f log/production.log

# Web server logs
sudo tail -f /var/log/nginx/error.log

# System resources
htop

# Disk usage
df -h
```

### Health Checks
```bash
# Application health
curl https://your-domain.com/health

# Database health
RAILS_ENV=production bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"

# Service health
sudo systemctl is-active nginx delayed-job
```

## Getting Help

- **Documentation:** See `docs/` directory
- **CI/CD Guide:** [docs/ci-cd-pipeline.md](ci-cd-pipeline.md)
- **Production Setup:** [docs/production-setup.md](production-setup.md)
- **Issues:** [GitHub Issues](https://github.com/thecartercenter/nemo/issues)

---

**Quick Links:**
- [Full CI/CD Documentation](ci-cd-pipeline.md)
- [Production README](../PRODUCTION_README.md)
- [Deployment History](DEPLOYMENT_HISTORY.md)
- [Production Setup](production-setup.md)
- [Architecture Guide](architecture.md)
