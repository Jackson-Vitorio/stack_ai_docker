#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"
STACK_NAME="$(basename "$STACK_DIR")"

echo "==> Removendo containers e volumes..."
cd "$STACK_DIR"
docker compose down -v

echo "==> Removendo pasta do stack..."
cd "$(dirname "$STACK_DIR")"
rm -rf "$STACK_NAME"

echo "==> Tudo apagado com sucesso."