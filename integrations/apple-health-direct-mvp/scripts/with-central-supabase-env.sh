#!/usr/bin/env bash
set -euo pipefail

exec bash /home/yk/.openclaw/workspace/scripts/load-supabase-env.sh apple-health-direct-mvp -- "$@"
