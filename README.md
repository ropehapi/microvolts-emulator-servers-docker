# Microvolts Emulator - Docker Setup

A complete Docker-based setup for running the Microvolts Emulator servers on Linux. This setup includes authentication, main game, and gameplay servers with automatic database initialization.

## Quick Start

Get the Microvolts Emulator running in minutes:

```bash
# Start an SSH agent and load a GitHub-authorized key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com

# Clone the Docker setup
git clone git@github.com:ropehapi/microvolts-emulator-servers-docker.git
cd microvolts-emulator-servers-docker

# Create the local environment file and define the variables
cp .env.example .env

./setup.sh --db-password-env MY_DB_PASSWORD

# Preserve the SSH agent because the build clones the private server repository
sudo --preserve-env=SSH_AUTH_SOCK docker compose up --build -d

sudo docker compose ps
```

That's it! Your Microvolts Emulator is now running with:
- ✅ MariaDB database (port 3305)
- ✅ Authentication server (port 13000)
- ✅ Main game server (ports 13005, 14005)
- ✅ Gameplay server (ports 13006, 14006)

## Requirements

- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Linux** environment (Ubuntu/Debian recommended)
- **4GB+ RAM** available
- **Git** for repository access
- **OpenSSH client** and an SSH key authorized on GitHub
- Access to the private `ropehapi/microvolts-emulator-servers` repository

## Support & Community

- **[Full Documentation](docs/)** - Complete guides and references
-  [Discord Server](https://discord.gg/y6yjRKmE6Y) - Bug reports and feature requests
---
