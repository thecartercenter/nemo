# Installing Docker for NEMO

Docker is required to run the NEMO application using the provided Docker setup.

## Quick Installation

### Ubuntu/Debian

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (optional, to run without sudo)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
```

**Note**: After adding user to docker group, you may need to log out and back in.

### CentOS/RHEL/Fedora

```bash
# Install prerequisites
sudo yum install -y yum-utils

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Verify
docker --version
```

### Using Package Manager (Simpler, but may be older version)

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

#### CentOS/RHEL
```bash
sudo yum install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

## Verify Installation

After installation, verify Docker works:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version
# or
docker-compose --version

# Test Docker (may require sudo or docker group membership)
docker run hello-world
```

## Troubleshooting

### Permission Denied

If you get "permission denied" errors:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Then test
docker run hello-world
```

### Docker Service Not Running

```bash
# Check status
sudo systemctl status docker

# Start service
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker
```

### Cannot Connect to Docker Daemon

```bash
# Ensure Docker is running
sudo systemctl start docker

# Check if you're in docker group
groups | grep docker

# If not, add yourself
sudo usermod -aG docker $USER
newgrp docker
```

## After Installation

Once Docker is installed, you can run NEMO:

```bash
cd /workspace/nemo
./docker-start.sh
```

Or manually:

```bash
docker-compose up --build
```

## Alternative: Docker Desktop

For desktop environments, you can also install Docker Desktop:

- **Linux**: https://docs.docker.com/desktop/install/linux-install/
- **Windows**: https://docs.docker.com/desktop/install/windows-install/
- **macOS**: https://docs.docker.com/desktop/install/mac-install/

## Resources

- **Official Docker Installation**: https://docs.docker.com/engine/install/
- **Docker Compose Installation**: https://docs.docker.com/compose/install/
- **Post-Installation Steps**: https://docs.docker.com/engine/install/linux-postinstall/

---

**Note**: Docker installation requires root/sudo access. If you don't have these permissions, contact your system administrator.
