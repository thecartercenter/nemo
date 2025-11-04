# Docker Setup for NEMO

Complete Docker configuration for running NEMO application with Ruby and all dependencies.

## Quick Start

### Development Mode

```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop services
docker-compose down
```

The application will be available at: **http://localhost:8443**

### First-Time Setup

1. **Create environment file** (if not exists):
   ```bash
   cp .env .env.development.local
   ```

2. **Start services**:
   ```bash
   docker-compose up -d db memcached
   ```

3. **Set up database**:
   ```bash
   docker-compose run --rm web bundle exec rake db:create
   docker-compose run --rm web bundle exec rake db:migrate
   docker-compose run --rm web bundle exec rake db:create_admin
   ```

4. **Start application**:
   ```bash
   docker-compose up web
   ```

## Docker Services

### Web Application (`web`)
- **Image**: Built from `Dockerfile`
- **Ruby**: 3.3.4
- **Node.js**: 20.x
- **Port**: 8443
- **Command**: Rails server

### Database (`db`)
- **Image**: postgres:15-alpine
- **Port**: 5432
- **Database**: nemo_development
- **User**: nemo
- **Password**: nemo_password

### Memcached (`memcached`)
- **Image**: memcached:1.6-alpine
- **Port**: 11211
- **Purpose**: Caching

### Delayed Job (`delayed_job`)
- **Image**: Same as web
- **Command**: Background job processor
- **Purpose**: Async task processing

## Dockerfiles

### Dockerfile (Production)
- Multi-stage build support
- Optimized for production
- Smaller image size
- Assets precompilation ready

### Dockerfile.dev (Development)
- Full development tools
- Hot-reload support
- Includes vim and debugging tools
- Optimized for local development

## Environment Configuration

### Development
Uses `.env` file or `.env.development.local`:
```bash
NEMO_URL_PROTOCOL=http
NEMO_URL_HOST=localhost
NEMO_URL_PORT=8443
DATABASE_URL=postgresql://nemo:nemo_password@db:5432/nemo_development
```

### Production
Uses `.env.production.local`:
```bash
RAILS_ENV=production
NEMO_URL_PROTOCOL=https
NEMO_URL_HOST=your-domain.com
```

## Common Commands

### Build
```bash
# Build all images
docker-compose build

# Build specific service
docker-compose build web

# Build without cache
docker-compose build --no-cache web
```

### Run Commands
```bash
# Run Rails console
docker-compose run --rm web bundle exec rails console

# Run migrations
docker-compose run --rm web bundle exec rake db:migrate

# Run tests
docker-compose run --rm web bundle exec rspec

# Run any rake task
docker-compose run --rm web bundle exec rake db:create_admin
```

### Database Operations
```bash
# Access PostgreSQL console
docker-compose exec db psql -U nemo -d nemo_development

# Create database
docker-compose run --rm web bundle exec rake db:create

# Reset database
docker-compose run --rm web bundle exec rake db:reset

# Seed database
docker-compose run --rm web bundle exec rake db:seed
```

### Logs
```bash
# View all logs
docker-compose logs

# Follow logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f web
docker-compose logs -f db
docker-compose logs -f delayed_job
```

### Cleanup
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (⚠️ deletes database data)
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Clean up everything
docker-compose down -v --rmi all
```

## Production Deployment

### Using Production Compose File

```bash
# Create production environment file
cp .env.production.template .env.production.local
# Edit .env.production.local with your values

# Build and start
docker-compose -f docker-compose.prod.yml up --build -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f web
```

### Environment Variables for Production

Set these in `.env.production.local`:
```bash
RAILS_ENV=production
NEMO_SECRET_KEY_BASE=<generate-random-64-char-hex>
NEMO_URL_PROTOCOL=https
NEMO_URL_HOST=your-domain.com
NEMO_URL_PORT=443
DB_USER=nemo
DB_PASSWORD=<secure-password>
DB_NAME=nemo_production
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs web

# Check if database is ready
docker-compose exec db pg_isready -U nemo

# Restart services
docker-compose restart
```

### Database Connection Errors

```bash
# Check database is running
docker-compose ps db

# Check database logs
docker-compose logs db

# Test connection
docker-compose exec web bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"
```

### Permission Issues

```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Or run as root in container
docker-compose exec -u root web chown -R app:app /app
```

### Rebuild After Gemfile Changes

```bash
# Rebuild with updated gems
docker-compose build --no-cache web
docker-compose up -d web
```

### Clear Cache

```bash
# Clear Rails cache
docker-compose run --rm web bundle exec rails tmp:clear

# Clear memcached
docker-compose exec memcached sh -c 'echo "flush_all" | nc localhost 11211'
```

## Volumes

### Development Volumes
- **`.` → `/app`**: Application code (for hot-reload)
- **`bundle_cache`**: Ruby gems cache
- **`node_modules`**: Node.js packages
- **`postgres_data`**: Database data

### Production Volumes
- **`bundle_cache_prod`**: Ruby gems cache
- **`postgres_data_prod`**: Database data

## Health Checks

All services include health checks:
- **Database**: Checks PostgreSQL readiness
- **Memcached**: Checks service availability
- **Web**: Depends on database and memcached being healthy

## Ports

- **8443**: Web application (HTTP)
- **5432**: PostgreSQL database
- **11211**: Memcached

## Accessing the Application

### Default Login
After running `db:create_admin`, login with:
- **Username**: `admin`
- **Password**: (shown in output or check logs)

### Get Admin Password
```bash
docker-compose logs web | grep "Admin password"
```

## Development Workflow

1. **Start services**:
   ```bash
   docker-compose up -d db memcached
   ```

2. **Set up database** (first time only):
   ```bash
   docker-compose run --rm web bundle exec rake db:create db:migrate db:create_admin
   ```

3. **Start application**:
   ```bash
   docker-compose up web
   ```

4. **Make changes**: Edit files locally, changes are reflected in container

5. **Run migrations**:
   ```bash
   docker-compose run --rm web bundle exec rake db:migrate
   ```

6. **Access console**:
   ```bash
   docker-compose run --rm web bundle exec rails console
   ```

## Ruby Version

The Dockerfile uses **Ruby 3.3.4**, which is compatible with Rails 8.0.

To change Ruby version, edit `Dockerfile`:
```dockerfile
FROM ruby:3.3.4-slim
```

## Node.js Version

The Dockerfile installs **Node.js 20.x**, which is required for enketo-core compatibility.

## Security Notes

- Change default database passwords in production
- Use `.env.production.local` for production secrets (git-ignored)
- Keep Docker images updated
- Use Docker secrets for sensitive data in production

## Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **Rails Docker Guide**: https://guides.rubyonrails.org/configuring.html#configuring-a-database

---

**Last Updated**: 2024-11-04
