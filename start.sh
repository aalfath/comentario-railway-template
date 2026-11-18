#!/bin/sh
# Start wrapper for Comentario on Railway.
#
# Comentario makes the FIRST account that signs up with email and password the
# instance superuser. On a fresh public URL anyone could claim it. So, before the
# public port opens, this wrapper starts Comentario on 127.0.0.1 only, signs up
# ADMIN_EMAIL with ADMIN_PASSWORD (the first boot also runs the database
# migrations), stops it, and then starts the real server on PORT.
set -eu

log() { printf '[comentario-railway] %s\n' "$*"; }

BIN=/comentario/comentario
BOOT_PORT="${BOOTSTRAP_PORT:-8099}"

# Public base URL: the template sets BASE_URL; fall back to Railway's domain.
if [ -z "${BASE_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

if [ -z "${COMENTARIO_POSTGRES_HOST:-}" ] && [ -z "${COMENTARIO_SQLITE3_FILE:-}" ]; then
  log "no database configured: set COMENTARIO_POSTGRES_HOST and friends (the template uses \${{Postgres.PGHOST}} etc.)"
  exit 1
fi

admin_email="${ADMIN_EMAIL:-}"
admin_pass="${ADMIN_PASSWORD:-}"
unset ADMIN_EMAIL ADMIN_PASSWORD

bootstrap() {
  case "$admin_email$admin_pass" in
    *'"'*|*'\'*) log "ADMIN_EMAIL and ADMIN_PASSWORD must not contain quotes or backslashes"; exit 1 ;;
  esac

  log "starting a loopback-only instance on 127.0.0.1:${BOOT_PORT} (migrations, first account)"
  HOST=127.0.0.1 PORT="$BOOT_PORT" "$BIN" &
  pid=$!

  # Railway starts services in any order: Comentario retries the database itself
  # (10 attempts, doubling delay). Wait until its API answers.
  i=0
  until wget -q -T 5 -O /dev/null "http://127.0.0.1:${BOOT_PORT}/api/config" 2>/dev/null; do
    if ! kill -0 "$pid" 2>/dev/null; then
      log "Comentario exited during start-up (database unreachable?); see the log above"
      exit 1
    fi
    i=$((i + 1))
    if [ "$i" -ge 600 ]; then
      log "Comentario did not answer within 10 minutes"
      kill "$pid" 2>/dev/null || true
      exit 1
    fi
    sleep 1
  done

  # The request body goes through a private file, so the password never shows
  # up in a process list.
  umask 077
  req=/tmp/comentario-signup.json
  err=/tmp/comentario-signup.err
  printf '{"email":"%s","name":"Admin","password":"%s"}' "$admin_email" "$admin_pass" >"$req"
  if out=$(wget -O - -T 30 --header 'Content-Type: application/json' --post-file "$req" \
      "http://127.0.0.1:${BOOT_PORT}/api/auth/signup" 2>"$err"); then
    case "$out" in
      *'"isSuperuser":true'*) log "created the superuser account $admin_email" ;;
      *) log "WARNING: other accounts already existed, so $admin_email was created as a regular account. Remove ADMIN_EMAIL if your admin uses another email now." ;;
    esac
  else
    case "$(cat "$err")" in
      *" 401 "*) log "account $admin_email already exists; leaving it unchanged" ;;
      *" 403 "*) log "sign-up is switched off in Comentario's settings; not creating $admin_email" ;;
      *" 400 "*) log "Comentario rejected ADMIN_EMAIL '$admin_email' or ADMIN_PASSWORD (valid email, password up to 63 characters)"
                 rm -f "$req"; kill "$pid" 2>/dev/null || true; exit 1 ;;
      *) log "could not create $admin_email: $(tail -n 1 "$err")"
         rm -f "$req"; kill "$pid" 2>/dev/null || true; exit 1 ;;
    esac
  fi
  rm -f "$req" "$err"

  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

if [ -n "$admin_email" ] && [ -n "$admin_pass" ]; then
  bootstrap
else
  log "WARNING: ADMIN_EMAIL or ADMIN_PASSWORD is empty, so no account is created. The first person to sign up on the public URL becomes the superuser."
fi
unset admin_email admin_pass

log "starting Comentario on port ${PORT}"
exec "$BIN" "$@"
