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

# Create .env and configure Docker Compose
make setup
# Review the generated .env file and replace its example values

# Build and start the servers (the SSH agent is forwarded automatically)
make run

make status
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
- **Make**
- Access to the private `ropehapi/microvolts-emulator-servers` repository

## Make commands

Run `make help` to list the available commands. The most common ones are:

```bash
make setup    # Prepare .env and the Compose override
make run      # Build and start all services
make logs     # Follow service logs
make status   # Show service status
make restart  # Restart all services
make stop     # Stop all services
```

The commands use `sudo` by default. If your user can access Docker directly,
run them with an empty `SUDO` variable, for example: `make run SUDO=`.

## Support & Community

- **[Full Documentation](docs/)** - Complete guides and references
-  [Discord Server](https://discord.gg/y6yjRKmE6Y) - Bug reports and feature requests
---
