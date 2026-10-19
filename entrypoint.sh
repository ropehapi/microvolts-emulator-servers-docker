#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/app/Setup/config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: $CONFIG_FILE not found in container image." >&2
  exit 1
fi

# Defaults that work for docker-compose networking.
: "${MV_DB_HOST:=db}"
: "${MV_DB_PORT:=3306}"
: "${MV_DB_NAME:=microvolts-db}"
: "${MV_DB_USER:=microvolts}"
: "${MV_DB_PASSWORD_ENV:=MV_DB_PW}"

resolve_ipv4() {
  getent ahostsv4 "$1" | awk 'NR == 1 { print $1; exit }'
}

set_ini_value() {
  local section="$1"
  local key="$2"
  local value="$3"
  local temporary
  temporary="$(mktemp)"

  awk -v section="$section" -v key="$key" -v value="$value" '
    $0 == "[" section "]" { active = 1; print; next }
    /^[[:space:]]*\[/ { active = 0 }
    active && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      print key " = " value
      next
    }
    { print }
  ' "$CONFIG_FILE" > "$temporary"

  cat "$temporary" > "$CONFIG_FILE"
  rm -f "$temporary"
}

# The emulator requires numeric addresses and assumes Main/Cast in a pair have
# the same LocalIp. Each container therefore gets its own generated config,
# while Ip points to the actual Docker address of the corresponding service.
AUTH_IP="$(resolve_ipv4 auth-server)"
MAIN_IP="$(resolve_ipv4 main-server)"
CAST_IP="$(resolve_ipv4 cast-server)"
DB_IP="$(resolve_ipv4 "$MV_DB_HOST")"

case "${1:-}" in
  */AuthServer.elf) LOCAL_IP="$AUTH_IP" ;;
  */MainServer.elf) LOCAL_IP="$MAIN_IP" ;;
  */CastServer.elf) LOCAL_IP="$CAST_IP" ;;
  *) LOCAL_IP="$(hostname -I | awk '{ print $1 }')" ;;
esac

set_ini_value AuthServer LocalIp "$LOCAL_IP"
set_ini_value AuthServer Ip "$AUTH_IP"
set_ini_value MainServer_1 LocalIp "$LOCAL_IP"
set_ini_value MainServer_1 Ip "$MAIN_IP"
set_ini_value CastServer_1 LocalIp "$LOCAL_IP"
set_ini_value CastServer_1 Ip "$CAST_IP"
set_ini_value Database LocalIp "$DB_IP"
set_ini_value Database Ip "$DB_IP"
set_ini_value Database Port "$MV_DB_PORT"
set_ini_value Database DatabaseName "$MV_DB_NAME"
set_ini_value Database Username "$MV_DB_USER"
set_ini_value Database PasswordEnvironmentName "$MV_DB_PASSWORD_ENV"

set_ini_value General SmtpServer "$MV_SMTP_SERVER"
set_ini_value General EmailSender "$MV_EMAIL_SENDER"
set_ini_value General EmailUsername "$MV_EMAIL_USERNAME"

# If the password env var is not present, warn (DB may still start with defaults).
if [[ -z "${!MV_DB_PASSWORD_ENV:-}" ]]; then
  echo "Warning: environment variable '$MV_DB_PASSWORD_ENV' is not set." >&2
fi

# The emulator resolves config and game data relative to Output/ (for example,
# ../Setup/config.ini), so it must not be started from /app.
cd /app/Output

exec "$@"
