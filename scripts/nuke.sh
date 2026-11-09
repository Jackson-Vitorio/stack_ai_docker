#!/usr/bin/env bash
# 🧨 Remove os containers e os volumes do stack.
#
# NUNCA apaga a pasta do projeto, ./projetos, o .env nem o código/scripts.
#
# Uso: ./scripts/nuke.sh [--data] [--images]
#   --data    também apaga ./data/omniroute (configuração e credenciais do OmniRoute)
#   --images  também remove as imagens Docker do stack
set -euo pipefail

STACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STACK_NAME="$(basename "$STACK_DIR")"
cd "$STACK_DIR"

usage() {
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

WIPE_DATA=0
DOWN_ARGS=(down -v --remove-orphans)
for arg in "$@"; do
    case "$arg" in
        --data)   WIPE_DATA=1 ;;
        --images) DOWN_ARGS+=(--rmi all) ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opção desconhecida: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

source ./scripts/_lib.sh
fill_missing_env

echo "⚠️  Isto vai APAGAR:"
echo "   - os containers do stack"
echo "   - os volumes: redis-data, qdrant-data, akita-data e open-webui-data"
echo "     (conversas do Open WebUI, memória vetorial e do Akita, dados do Redis)"
[ "$WIPE_DATA" = 1 ] && echo "   - ./data/omniroute (configuração e credenciais do OmniRoute)"
[[ " ${DOWN_ARGS[*]} " == *" --rmi "* ]] && echo "   - as imagens Docker do stack"
echo ""
echo "✅ Será PRESERVADO: ./projetos, .env, docker-compose.yml, scripts e o resto da pasta."
echo ""
read -r -p "Digite o nome da pasta ($STACK_NAME) para confirmar: " answer
if [ "$answer" != "$STACK_NAME" ]; then
    echo "Cancelado. Nada foi apagado."
    exit 1
fi

echo "==> Removendo containers e volumes..."
docker compose "${DOWN_ARGS[@]}"

if [ "$WIPE_DATA" = 1 ] && [ -d "$STACK_DIR/data/omniroute" ]; then
    echo "==> Apagando data/omniroute..."
    rm -rf -- "$STACK_DIR/data/omniroute"
fi

echo "==> Pronto. Projetos, .env e código foram preservados."
echo "    Para subir de novo: ./scripts/start.sh"
