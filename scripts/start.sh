#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

echo "==> Iniciando stack de IA..."
docker compose up -d

echo "==> Aguardando Ollama ficar pronto..."
for i in $(seq 1 30); do
  if docker exec ollama ollama list >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "==> Baixando modelo Qwen (pode demorar na primeira vez)..."
docker exec ollama ollama pull qwen3:4b || true

echo ""
echo "==> Stack pronto!"
echo "   Open Web UI (chat):    http://localhost:3000"
echo "   OmniRoute API:         http://localhost:20129/v1"
echo "   OmniRoute Dashboard:   http://localhost:20128"
echo "   Akita AI Memory (MCP): http://localhost:49374/mcp"
echo "   Ollama:                http://localhost:11434"
echo ""
echo "   Seus projetos ficam em: ./projetos/"
echo "   O agente OpenHands só tem acesso à pasta ./projetos/"
echo ""
echo "   Para parar:  ./scripts/stop.sh"
echo "   Para apagar tudo: ./scripts/nuke.sh"