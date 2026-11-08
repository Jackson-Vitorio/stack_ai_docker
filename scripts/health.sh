#!/usr/bin/env bash
# ✅ Verificação do status do stack
cd "$(dirname "$0")/.."
echo "📊 Status do Stack IA:"
echo "=========================================="
docker compose ps 2>&1 | grep -E "^[a-z]|UP|healthy" | head -20 || docker compose ps
echo ""
echo "🌐 Acessos:"
echo "   Open Web UI:    http://localhost:3000"
echo "   OmniRoute API:  http://localhost:20129/v1"
echo "   OmniRoute UI:   http://localhost:20128"
echo "=========================================="
