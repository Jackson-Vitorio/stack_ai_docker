#!/usr/bin/env bash
cd "$(dirname "$0")/.."
docker compose stop
echo "==> Todos os processos parados. Dados preservados."