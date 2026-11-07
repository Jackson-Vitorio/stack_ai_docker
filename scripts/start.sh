#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

echo "==> Iniciando stack de IA..."
docker compose up -d

echo ""
echo "==> Stack pronto!"
echo "   Open Web UI (chat):    http://localhost:3000"
echo "   OmniRoute API:         http://localhost:20129/v1"
echo "   OmniRoute Dashboard:   http://localhost:20128"
echo "   Akita AI Memory (MCP): http://localhost:49374/mcp"
echo ""
echo "   Seus projetos ficam em: ./projetos/"
echo "   O agente OpenHands só tem acesso à pasta ./projetos/"
echo ""
echo "   IMPORTANTE: Como não há IA local (Ollama), configure as chaves de"
echo "   API dos provedores (OpenAI, Anthropic, Google, etc.) no OmniRoute"
echo "   pelo dashboard em http://localhost:20128 antes de usar o chat."
echo ""
echo "   Para parar:  ./scripts/stop.sh"
echo "   Para apagar tudo: ./scripts/nuke.sh"