#!/usr/bin/env bash
set -euo pipefail

ENV_FILE_DEFAULT="/home/yk/.openclaw/workspace/.secrets/supabase_pdzzmmytzpovemgmubqj.env"
ENV_FILE="${SUPABASE_ENV_FILE:-$ENV_FILE_DEFAULT}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[error] env file not found: $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"
SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-${SUPABASE_SERVICE_KEY:-}}"

if [[ -z "${SUPABASE_URL:-}" || -z "$SUPABASE_SERVICE_KEY" ]]; then
  echo "[error] SUPABASE_URL and SUPABASE_SERVICE_KEY(or SUPABASE_SERVICE_ROLE_KEY) are required" >&2
  exit 1
fi

cmd="${1:-}"
shift || true

case "$cmd" in
  query)
    sql="${*:-}"
    if [[ -z "$sql" ]]; then
      echo "usage: $0 query \"select now();\"" >&2
      exit 1
    fi
    payload=$(jq -n --arg q "$sql" '{q:$q}')
    code=$(curl -sS -o /tmp/supabase_query_out.json -w "%{http_code}" \
      -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
      -H "apikey: $SUPABASE_SERVICE_KEY" \
      -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -d "$payload")
    if [[ "$code" != "200" && "$code" != "201" ]]; then
      echo "[error] rpc/exec_sql failed (HTTP $code)." >&2
      cat /tmp/supabase_query_out.json >&2
      echo >&2
      echo "hint: create function from supabase/exec_sql.sql in SQL Editor first." >&2
      exit 1
    fi
    cat /tmp/supabase_query_out.json
    ;;
  health)
    code=$(curl -sS -o /tmp/supabase_health_out.json -w "%{http_code}" \
      "$SUPABASE_URL/rest/v1/" \
      -H "apikey: $SUPABASE_SERVICE_KEY" \
      -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")
    echo "status=$code"
    ;;
  *)
    echo "usage: $0 {health|query \"<sql>\"}" >&2
    exit 1
    ;;
esac
