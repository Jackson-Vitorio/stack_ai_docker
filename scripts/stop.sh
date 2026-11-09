#!/usr/bin/env bash
# Para os containers sem apagar nada (dados e volumes preservados).
set -euo pipefail

cd "$(dirname "$0")/.."
source ./scripts/_lib.sh
fill_missing_env

docker compose stop
echo "==> Todos os processos parados. Dados preservados."
