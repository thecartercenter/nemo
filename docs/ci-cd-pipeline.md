# CI/CD Pipeline Documentation

## Overview

NEMO uses GitHub Actions for continuous integration and deployment. The CI/CD
pipeline consists of multiple workflows that handle testing, building, and
deploying the application.

## Workflows

### 1. Tests Workflow (`tests.yml`)

**Triggers:**
- On every push to any branch

**Purpose:**
- Run RSpec tests
- Run Jest tests
- Run ESLint linting

**Jobs:**
- Setup PostgreSQL database
- Install Ruby and Node.js dependencies
- Run database migrations
- Execute test suites
- Report results

### 2. Build and Deploy Workflow (`build-deploy.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger via workflow_dispatch

**Jobs:**

#### Build Job
- Installs Ruby and Node.js dependencies
- Exports i18n translations
- Builds production assets using Webpack/Shakapacker
- Archives production artifacts
- Outputs version and image tags for downstream jobs

#### Lint Job
- Runs ESLint on React code
- Runs StyleLint on SCSS files
- Ensures code quality standards

#### Docker Build Job
- Builds Docker image using multi-stage Dockerfile
- Pushes image to GitHub Container Registry (ghcr.io)
- Tags images with:
  - Branch name
  - Semantic version from VERSION file
  - Git SHA
  - `latest` for main branch
- Generates Software Bill of Materials (SBOM)
- Caches layers for faster subsequent builds

#### Security Scan Job
- Runs Trivy vulnerability scanner on Docker image
- Generates security report in SARIF format
- Archives scan results

#### Deploy to Staging Job
**Conditions:**
- Push to `develop` branch, OR
- Manual trigger with staging environment selected

**Steps:**
- Downloads production artifacts
- Deploys to staging environment
- Runs smoke tests

**Environment:**
- Name: staging
- URL: https://staging.nemo.example.com

#### Deploy to Production Job
**Conditions:**
- Push to `main` branch, OR
- Manual trigger with production environment selected

**Steps:**
- Downloads production artifacts
- Creates database backup
- Deploys to production environment
- Verifies deployment
- Sends notifications

**Environment:**
- Name: production
- URL: https://nemo.example.com

#### Notify Failure Job
- Sends notifications if any job fails
- Includes workflow, branch, and commit information

## Configuration

### Environment Variables

The following environment variables are used in the workflow:

- `REGISTRY`: Container registry (ghcr.io)
- `IMAGE_NAME`: Full image name including repository
- `NODE_ENV`: Node.js environment (production)
- `RAILS_ENV`: Rails environment (production)

### Secrets

The following secrets should be configured in GitHub repository settings:

- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
- Additional deployment secrets (SSH keys, API keys, etc.)

### Artifacts

The workflow produces the following artifacts:

1. **production-assets** (30 days retention)
   - `public/packs/` - Webpack compiled assets
   - `public/assets/` - Asset pipeline assets

2. **build-logs** (7 days retention)
   - Build and compilation logs

3. **sbom** (30 days retention)
   - Software Bill of Materials in SPDX format

4. **trivy-results** (30 days retention)
   - Security scan results in SARIF format

## Manual Deployment

You can manually trigger a deployment using workflow_dispatch:

1. Go to Actions tab in GitHub
2. Select "Build and Deploy" workflow
3. Click "Run workflow"
4. Choose branch and environment (staging/production)
5. Click "Run workflow" button

## Deployment Targets

### Staging Environment

- **Branch:** develop
- **URL:** https://staging.nemo.example.com
- **Purpose:** Testing and validation before production
- **Auto-deploy:** Yes (on push to develop)

### Production Environment

- **Branch:** main
- **URL:** https://nemo.example.com
- **Purpose:** Live application
- **Auto-deploy:** Yes (on push to main)
- **Protection:** Environment protection rules recommended

## Environment Protection

It's recommended to configure environment protection rules:

### Staging
- No required reviewers
- Wait timer: 0 minutes
- Allow administrators to bypass

### Production
- Required reviewers: 2+ team members
- Wait timer: 5 minutes
- Restrict to main branch only
- Do not allow administrators to bypass

## Customizing Deployment

To customize the deployment process, modify the deploy steps in
`build-deploy.yml`:

```yaml
- name: Deploy to production
  run: |
    # Add your deployment commands here
    # Examples:
    # - SSH to server: ssh deploy@server "./deploy.sh"
    # - Docker pull: docker pull ghcr.io/org/repo:tag
    # - Kubernetes apply: kubectl apply -f k8s/
    # - Ansible playbook: ansible-playbook deploy.yml
```

## Docker Image Tags

Images are tagged with multiple strategies:

| Tag Format | Example | Use Case |
|------------|---------|----------|
| `branch-sha` | `main-abc1234` | Specific commit |
| `version` | `15.1` | Semantic version |
| `major.minor` | `15.1` | Version family |
| `branch` | `main`, `develop` | Latest on branch |
| `latest` | `latest` | Latest stable (main only) |

## Monitoring and Logs

### Build Logs
- Available in GitHub Actions UI
- Archived as workflow artifacts (7 days)
- Download via Actions tab

### Deployment Logs
- Check Actions workflow run details
- View job output in real-time
- Download logs after completion

### Security Scan Results
- Trivy scan results in Artifacts
- Review vulnerabilities before deployment
- SARIF format for automated analysis

## Troubleshooting

### Build Failures

1. **Asset compilation fails**
   - Check Node.js version (must be 20.x)
   - Verify yarn.lock is up to date
   - Review build logs artifact

2. **Ruby dependency issues**
   - Check Gemfile.lock consistency
   - Verify Ruby version matches .ruby-version
   - Review bundler cache

3. **Docker build fails**
   - Check Dockerfile syntax
   - Verify all COPY paths exist
   - Review Docker build logs

### Deployment Failures

1. **SSH connection issues**
   - Verify SSH keys are configured
   - Check server accessibility
   - Review firewall rules

2. **Database migration failures**
   - Check database connectivity
   - Verify migration files
   - Review production logs

3. **Asset loading issues**
   - Ensure assets were built
   - Verify artifact download
   - Check RAILS_SERVE_STATIC_FILES setting

## Best Practices

1. **Always test on staging first**
   - Merge to develop branch
   - Wait for staging deployment
   - Validate functionality

2. **Use semantic versioning**
   - Update VERSION file before release
   - Follow semver conventions
   - Tag releases in Git

3. **Monitor deployments**
   - Watch workflow progress
   - Check deployment logs
   - Verify application health

4. **Handle failures gracefully**
   - Review failure notifications
   - Check archived logs
   - Roll back if necessary

5. **Keep dependencies updated**
   - Regular security updates
   - Review Dependabot PRs
   - Test thoroughly before merging

## Security Considerations

1. **Secrets Management**
   - Never commit secrets to repository
   - Use GitHub Secrets for sensitive data
   - Rotate credentials regularly

2. **Container Security**
   - Review Trivy scan results
   - Update base images regularly
   - Minimize image layers

3. **Deployment Security**
   - Use SSH key authentication
   - Restrict network access
   - Enable environment protection rules

4. **Audit Logging**
   - Monitor deployment logs
   - Track who triggered deployments
   - Review failed attempts

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)
- [NEMO Production Setup Guide](production-setup.md)
- [NEMO Deployment Guide](DEPLOYMENT.md)

## Support

For issues with the CI/CD pipeline:

1. Check workflow logs in Actions tab
2. Review this documentation
3. Open an issue on GitHub
4. Contact the development team

---

**Last Updated:** 2024-11-05
**Maintained By:** NEMO Development Team
