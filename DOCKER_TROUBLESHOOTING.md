# Docker Troubleshooting Guide

## Issue: Cgroup Permission Error

If you encounter:
```
error mounting "cgroup" to rootfs at "/sys/fs/cgroup": permission denied
```

This typically occurs in:
- Containerized environments (Docker-in-Docker)
- Nested virtualization
- Certain cloud environments
- cgroup v2 configurations

## Solutions

### Solution 1: Check Docker Configuration

```bash
# Check Docker info
sudo docker info

# Check if running in container
cat /proc/self/cgroup

# If you see "docker" or "lxc" in cgroup, you're in a container
```

### Solution 2: Use Docker Rootless Mode

```bash
# Install rootless Docker
dockerd-rootless-setuptool.sh install

# Or start rootless daemon
dockerd-rootless.sh
```

### Solution 3: Configure Docker Daemon

Edit `/etc/docker/daemon.json`:

```json
{
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

Then restart:
```bash
sudo systemctl restart docker
```

### Solution 4: Use Podman (Alternative)

Podman doesn't require root and works in containerized environments:

```bash
# Install Podman
sudo apt-get install -y podman

# Use podman-compose instead
pip install podman-compose

# Run with podman
podman-compose up
```

### Solution 5: Run Without Docker (Direct Installation)

If Docker isn't working, install Ruby directly:

```bash
# Install Ruby 3.3.4
sudo apt-get update
sudo apt-get install -y ruby-full ruby-dev build-essential libpq-dev

# Install bundler
gem install bundler

# Install dependencies
bundle install
yarn install

# Set up database
bundle exec rake db:create db:migrate db:create_admin

# Run application
./bin/server
```

## Current Environment Check

```bash
# Check if we're in a container
if [ -f /.dockerenv ] || grep -qa docker /proc/1/cgroup; then
    echo "Running in Docker container"
else
    echo "Running on host system"
fi

# Check cgroup version
stat -fc %T /sys/fs/cgroup/

# Check Docker version
docker --version
docker info | grep -i cgroup
```

## Alternative: Run Application Without Docker

Since we have all the code and assets ready, you can run the application directly:

1. **Install Ruby**:
   ```bash
   sudo apt-get install -y ruby-full ruby-dev
   ```

2. **Install PostgreSQL**:
   ```bash
   sudo apt-get install -y postgresql postgresql-contrib
   sudo -u postgres createuser -s nemo
   sudo -u postgres createdb nemo_development
   ```

3. **Install dependencies**:
   ```bash
   gem install bundler
   bundle install
   yarn install
   ```

4. **Set up database**:
   ```bash
   bundle exec rake db:migrate
   bundle exec rake db:create_admin
   ```

5. **Run application**:
   ```bash
   ./bin/server
   ```

## Resources

- Docker Rootless: https://docs.docker.com/engine/security/rootless/
- Podman: https://podman.io/
- Docker-in-Docker: https://www.docker.com/blog/docker-can-now-run-inside-docker/
