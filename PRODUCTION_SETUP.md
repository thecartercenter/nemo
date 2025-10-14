# NEMO Production Setup Summary

## Overview
This document summarizes the production setup and deployment process for NEMO (v15.1).

## System Requirements
- **Operating System**: Ubuntu 20.04+ (tested on Ubuntu 25.04)
- **Ruby**: 3.3.4 (managed via rbenv)
- **Node.js**: 20.19.5 (managed via nvm)
- **PostgreSQL**: 17.6
- **Web Server**: Nginx with Passenger
- **Background Jobs**: Delayed Job

## Dependencies Installed
- **System Packages**: build-essential, libssl-dev, postgresql, nginx, memcached, imagemagick, graphviz
- **Ruby Gems**: Rails 8.0.3, and all required dependencies
- **Node.js Packages**: All frontend dependencies including React, Webpack, etc.

## Configuration Files
- **Database**: `config/database.yml` (PostgreSQL configuration)
- **Environment**: `.env.production.local` (production environment variables)
- **Webpack**: `config/webpack/webpack.config.js` (asset compilation)
- **Shakapacker**: `config/shakapacker.yml` (asset pipeline configuration)

## Security Updates Applied
- **Ruby Gems**: Updated rack to 3.2.3, rexml to 3.4.4
- **Node.js Packages**: Updated @xmldom/xmldom to 0.7.7
- **Vulnerabilities**: Addressed critical and moderate security issues

## Code Quality Improvements
- **RuboCop**: Fixed 100+ linting issues automatically
- **Dependencies**: Updated to latest compatible versions
- **Configuration**: Resolved compatibility issues with Rails 8.0

## Deployment Process
1. **Database Backup**: Automatic backup before deployment
2. **Code Update**: Git pull from main branch
3. **Dependencies**: Bundle install and yarn install
4. **Migrations**: Database schema updates
5. **Assets**: Precompilation (with error handling)
6. **Services**: Restart nginx and delayed-job
7. **Verification**: Health check and cleanup

## Environment Variables Required
```bash
# Required for production
NEMO_SECRET_KEY_BASE=your-secret-key
NEMO_URL_PROTOCOL=https
NEMO_URL_HOST=your-domain.com
NEMO_URL_PORT=443

# Email configuration
NEMO_SITE_EMAIL=nemo@your-domain.com
NEMO_WEBMASTER_EMAILS=admin@your-domain.com
NEMO_SMTP_ADDRESS=smtp.your-domain.com
NEMO_SMTP_PORT=587
NEMO_SMTP_DOMAIN=your-domain.com
NEMO_SMTP_AUTHENTICATION=login
NEMO_SMTP_USER_NAME=your-email@your-domain.com
NEMO_SMTP_PASSWORD=your-email-password

# Security settings
NEMO_RECAPTCHA_PUBLIC_KEY=your-recaptcha-public-key
NEMO_RECAPTCHA_PRIVATE_KEY=your-recaptcha-private-key
NEMO_GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Storage
NEMO_STORAGE_TYPE=local

# Theme
NEMO_NEMO_THEME_SITE_NAME=NEMO
NEMO_ELMO_THEME_SITE_NAME=ELMO
```

## Known Issues
1. **Asset Precompilation**: Webpack configuration needs refinement for cheerio dependency
2. **Annotate Gem**: Temporarily disabled due to Rails 8.0 compatibility
3. **Bullet Gem**: Temporarily disabled due to Rails 8.0 compatibility

## Deployment Commands
```bash
# Run deployment script
./deploy.sh

# Manual deployment steps
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 20

# Update dependencies
bundle install --without development test --deployment
yarn install --production

# Run migrations
RAILS_ENV=production bundle exec rake db:migrate

# Precompile assets (if webpack issues are resolved)
ALLOW_MISSING_CONFIG=1 RAILS_ENV=production bundle exec rake assets:precompile

# Restart services
sudo systemctl restart delayed-job
sudo systemctl reload nginx
```

## Monitoring and Maintenance
- **Logs**: Check `/var/log/nginx/error.log` and `log/production.log`
- **Services**: Monitor with `sudo systemctl status nginx delayed-job`
- **Database**: Regular backups via `pg_dump nemo_production`
- **Updates**: Regular security updates for system packages

## Next Steps
1. Configure real production environment variables
2. Set up SSL certificates
3. Configure email service
4. Set up monitoring and alerting
5. Resolve webpack asset compilation issues
6. Re-enable disabled gems when compatible versions are available

## Support
- **Documentation**: https://getnemo.readthedocs.io
- **Issues**: https://github.com/thecartercenter/nemo/issues
- **Community**: NEMO development team