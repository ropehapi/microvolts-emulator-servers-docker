SHELL := /bin/bash

.DEFAULT_GOAL := help

DOCKER ?= docker
SUDO ?= sudo --preserve-env=SSH_AUTH_SOCK
COMPOSE ?= $(SUDO) $(DOCKER) compose
SETUP_ARGS ?= --db-password-env MY_DB_PASSWORD

.PHONY: help check setup run build stop restart status logs check-env check-ssh

help: ## Show the available commands
	@printf '%s\n' \
		'Usage: make <command>' \
		'' \
		'Commands:' \
		'  setup    Create .env (if needed) and configure Docker Compose' \
		'  run      Build and start all services in the background' \
		'  build    Build the service images' \
		'  stop     Stop and remove the service containers' \
		'  restart  Restart all services' \
		'  status   Show the service status' \
		'  logs     Follow logs from all services' \
		'' \
		'If Docker does not require sudo, append SUDO= (for example: make run SUDO=).'

check:
	@command -v $(DOCKER) >/dev/null 2>&1 || { echo 'Docker is not installed or is not in PATH.' >&2; exit 1; }
	@$(DOCKER) compose version >/dev/null 2>&1 || { echo 'Docker Compose v2 is required.' >&2; exit 1; }

setup: check ## Prepare the local environment and Compose configuration
	@if [[ ! -f .env ]]; then \
		cp .env.example .env; \
		echo 'Created .env from .env.example. Review its values before running the servers.'; \
	else \
		echo 'Keeping the existing .env file.'; \
	fi
	@./setup.sh $(SETUP_ARGS)

check-env:
	@test -f .env || { echo 'Missing .env file. Run make setup first.' >&2; exit 1; }

check-ssh:
	@test -n "$$SSH_AUTH_SOCK" && test -S "$$SSH_AUTH_SOCK" || { echo 'No SSH agent found. Start one and add your GitHub key before running make run.' >&2; exit 1; }
	@ssh-add -l >/dev/null 2>&1 || { echo 'The SSH agent has no key loaded. Run ssh-add with your GitHub key.' >&2; exit 1; }

up: check check-env check-ssh ## Build and start all services
	@$(COMPOSE) up --build -d

down: check check-env ## Stop all services
	@$(COMPOSE) down

restart: check check-env ## Restart all services
	@$(COMPOSE) restart

build: check check-env check-ssh ## Build all service images
	@$(COMPOSE) build

status: check check-env ## Show service status
	@$(COMPOSE) ps

logs: check check-env ## Follow service logs
	@$(COMPOSE) logs -f
