# Repository guide

## Scope and architecture

- This repository contains Docker orchestration, not the emulator source. Both `Dockerfile` and `Dockerfile.db` shallow-clone the private `ropehapi/microvolts-emulator-servers` `main` branch during builds; application changes belong there.
- Treat `Makefile`, `docker-compose*.yml`, and the shell scripts as authoritative. Much of `README_Docker.md` and `docs/` describes an older checkout-in-place layout and uses legacy `docker-compose` commands.
- All three game services use the same runtime image with different `.elf` commands. `entrypoint.sh` rewrites the image's `/app/Setup/config.ini` per container, resolves service names to numeric IPv4 addresses, and must launch binaries from `/app/Output` because their data paths are relative.

## Setup and commands

- Builds require an active SSH agent containing a GitHub-authorized key; BuildKit forwards it to clone the private repository. `make run` and `make build` enforce this.
- `make setup` creates ignored `.env` only when absent, but always regenerates the tracked `docker-compose.override.yml`. Do not run it over a customized override without reviewing `SETUP_ARGS` first. The Makefile default selects `MY_DB_PASSWORD`, while direct `./setup.sh` defaults to `MV_DB_PW`.
- Use `make run`, `make build`, `make status`, `make logs`, `make restart`, and `make stop`. They use `sudo --preserve-env=SSH_AUTH_SOCK` by default; append `SUDO=` when Docker is available without sudo.
- For one service, use Compose v2 directly, e.g. `docker compose build auth-server`, `docker compose up -d auth-server`, or `docker compose logs -f auth-server`; preserve the SSH agent when a build is involved.

## Verification and operational traps

- There is no repository test or lint suite. Use `make check`, `docker compose config --quiet`, and `bash -n setup.sh entrypoint.sh edit_config.sh restart_servers.sh` for focused validation; a full image build is expensive because it clones/builds vcpkg and all C++ targets.
- `setup.sh --db-port` controls the host-published DB port only. Containers always connect to MariaDB on port `3306`.
- MariaDB initialization scripts run only when `db_data` is empty. Changes to `Dockerfile.db` or `database-normalize.sql` do not affect an existing volume. Never use `docker compose down -v` as routine verification because it destroys database data.
- Keep `database-normalize.sql` after the upstream dump: Linux MariaDB table names are case-sensitive, while the emulator queries the PascalCase names established there.
- Never commit `.env` or print its values; it is intentionally ignored and contains database/JWT/email secrets.
