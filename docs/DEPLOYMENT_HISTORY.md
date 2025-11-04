# NEMO Deployment History

This document tracks all deployments and significant changes to the NEMO application in production.

## Format

Each deployment entry includes:
- **Date**: Deployment date (YYYY-MM-DD)
- **Version**: Application version or commit hash
- **Deployed By**: Person/system who deployed
- **Environment**: Production, Staging, etc.
- **Changes**: Summary of changes
- **Notes**: Additional notes, rollbacks, issues, etc.

---

## 2024-11-04 - Version 15.1 - AI Validation Feature & Build Artifacts

**Deployed By**: Automated CI/CD  
**Environment**: Production  
**Commit**: `cce293575`

### Changes
- ✅ Added comprehensive AI validation routes and controller endpoints
- ✅ Implemented OpenAI service integration for AI-powered data validation
- ✅ Created AI provider service architecture (base service + OpenAI implementation)
- ✅ Replaced mock AI validation with real OpenAI API integration
- ✅ Fixed package.json syntax errors
- ✅ Updated webpack configuration to exclude test files from production builds
- ✅ Built production JavaScript artifacts (11MB total)
- ✅ Generated optimized, minified bundles with source maps
- ✅ Created Brotli and Gzip compressed asset versions

### Features Added
- AI Validation Rules management (CRUD operations)
- Support for 8 validation rule types:
  - Data quality checks
  - Anomaly detection
  - Consistency validation
  - Completeness checks
  - Format validation
  - Business logic validation
  - Duplicate detection
  - Outlier detection
- OpenAI GPT model support (3.5-turbo, GPT-4, GPT-4-turbo, GPT-4o)
- Batch validation capabilities
- Validation reporting and analytics
- Rule suggestions based on form analysis

### Technical Details
- **Build Size**: ~11 MB compiled assets
- **Entry Points**: application.js (1.41 MB), enketo.js (1.04 MB), server_rendering.js (1.3 MB)
- **Node Version**: 20.19.5 (required for enketo-core compatibility)
- **Dependencies**: Updated yarn.lock, webpack config enhanced

### Configuration Required
- Set `OPENAI_API_KEY` environment variable for AI validation features
- Or use `NEMO_OPENAI_API_KEY` environment variable
- Falls back to mock mode if API keys not configured

### Documentation Created
- `EXPLORATION_PLAN.md` - Architecture analysis and build opportunities
- `IMPLEMENTATION_SUMMARY.md` - Implementation details and next steps
- `docs/DEPLOYMENT_HISTORY.md` - This file

### Notes
- Build artifacts committed to repository
- Mock mode available for development/testing without API keys
- All changes backward compatible
- No database migrations required for this deployment

### Rollback Plan
If issues occur:
1. Revert commit `cce293575`
2. Rebuild assets: `yarn build`
3. Restart services: `sudo systemctl restart nginx delayed-job`

---

## Previous Deployments

### Template for Future Entries

**Date**: YYYY-MM-DD  
**Version**: X.Y.Z  
**Deployed By**: Name/System  
**Environment**: Production/Staging  
**Commit**: [commit hash]

#### Changes
- Change 1
- Change 2

#### Features Added/Removed
- Feature description

#### Technical Details
- Technical information

#### Configuration Required
- Environment variables
- Settings changes

#### Notes
- Additional notes

#### Rollback Plan
- Steps to rollback if needed

---

## Deployment Statistics

### Total Deployments (This Document)
- **2024**: 1 deployment

### Average Deployment Frequency
- Currently tracking from November 2024

### Common Deployment Times
- Deployments typically occur during maintenance windows
- Most deployments: [TBD as history grows]

---

## Deployment Procedures

### Standard Deployment Process
1. Create database backup
2. Pull latest code from repository
3. Install/update dependencies (Ruby gems + npm packages)
4. Run database migrations
5. Precompile assets
6. Update cron jobs
7. Restart services (nginx, delayed-job)
8. Verify deployment
9. Cleanup old backups

### Emergency Deployment Process
Same as standard, but:
- Skip non-critical migrations if needed
- Deploy to staging first if possible
- Have rollback plan ready

### Rollback Process
1. Identify last known good commit
2. Revert to that commit
3. Rebuild assets if needed
4. Restart services
5. Verify application functionality
6. Update deployment history

---

## Known Issues & Resolutions

### 2024-11-04: Build Process
**Issue**: Node version incompatibility with enketo-core  
**Resolution**: Switched to Node 20.19.5  
**Prevention**: Document Node version requirements in deployment docs

### 2024-11-04: Test Files in Production Build
**Issue**: Test files being included in production webpack build  
**Resolution**: Added ignore-loader for test files in production mode  
**Prevention**: Keep webpack config updated to exclude test files

---

## Environment Variables Reference

### Required for AI Validation
- `OPENAI_API_KEY` - OpenAI API key for AI validation features
- `NEMO_OPENAI_API_KEY` - Alternative env var name (takes precedence if set)

### Standard NEMO Variables
See `.env.example` for complete list of environment variables.

---

## Monitoring & Alerts

### Post-Deployment Checks
- [ ] Application responds to HTTP requests
- [ ] Database connections working
- [ ] Background jobs processing
- [ ] Asset files loading correctly
- [ ] No errors in production logs
- [ ] AI validation endpoints accessible (if API key configured)

### Health Check Endpoints
- `/ping` - Basic uptime check
- Health check URLs defined in application

---

## Contact & Support

For deployment issues:
- Check deployment logs: `/var/log/nemo-deploy.log`
- Application logs: `log/production.log`
- Review this document for similar past issues
- Contact DevOps team or check GitHub issues

---

**Last Updated**: 2024-11-04  
**Maintained By**: NEMO Development Team  
**Document Version**: 1.0
