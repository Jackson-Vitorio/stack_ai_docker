#!/usr/bin/env bash
# Inicia o stack. Rode ./scripts/setup-auto.sh antes, na primeira vez.
set -euo pipefail

# Garante que o daemon Docker está rodando
if ! docker info >/dev/null 2>&1; then
    echo "🐳 Iniciando daemon Docker..."
    sudo dockerd &
    # Espera o socket ficar disponível
    for i in $(seq 1 30); do
        if docker info >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Falha ao iniciar o daemon Docker." >&2
        exit 1
    fi
fi

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
    echo "❌ Arquivo .env não encontrado." >&2
    echo "   Rode ./scripts/setup-auto.sh para criá-lo e gerar os segredos." >&2
    exit 1
fi

source ./scripts/_lib.sh
missing=()
for v in "${REQUIRED_VARS[@]}"; do
    [ -n "$(get_env "$v")" ] || missing+=("$v")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "❌ Faltam valores no .env: ${missing[*]}" >&2
    echo "   Rode ./scripts/setup-auto.sh para gerá-los (ele não altera os que já existem)." >&2
    exit 1
fi

mkdir -p projetos data/omniroute

echo "==> Iniciando stack de IA..."
docker compose up -d

echo ""
echo "==> Stack pronto! (acessos somente nesta máquina)"
echo "   Open Web UI (chat):    http://localhost:3000"
echo "   Open Code (agente):    http://localhost:3001"
echo "   OmniRoute Dashboard:   http://localhost:20128"
echo "   OmniRoute API:         http://localhost:20129/v1"
echo ""
echo "   Logins: usuário e senha do Open Code e a senha inicial do OmniRoute"
echo "   estão no .env (OPENCODE_SERVER_* e INITIAL_PASSWORD)."
echo ""
echo "   Seus projetos ficam em: ./projetos/"
echo "   O agente Open Code só tem acesso a essa pasta (/workspace/projetos)."
echo ""
echo "   IMPORTANTE: como não há IA local (Ollama), configure as chaves de"
echo "   API dos provedores (OpenAI, Anthropic, Google, etc.) no OmniRoute"
echo "   pelo dashboard em http://localhost:20128 antes de usar o chat."
echo ""
echo "   Para checar:  ./scripts/health.sh"
echo "   Para parar:   ./scripts/stop.sh"
echo "   Para apagar:  ./scripts/nuke.sh --help"
