#!/usr/bin/env bash
# ✅ Verificação do status do stack
# Sai com código 0 se tudo responde e 1 se algum serviço falhou.
set -uo pipefail

cd "$(dirname "$0")/.."
source ./scripts/_lib.sh
fill_missing_env

failed=0
check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "   ✅ $name"
    else
        echo "   ❌ $name"
        failed=1
    fi
}

# Credenciais passadas por stdin (-K -) para não aparecerem na lista de processos.
open_code_health() {
    printf 'user = "%s:%s"\n' "$(get_env OPENCODE_SERVER_USERNAME)" "$(get_env OPENCODE_SERVER_PASSWORD)" \
        | curl -fsS --max-time 5 -K - http://127.0.0.1:3001/global/health
}

redis_ping() {
    docker compose exec -T -e REDISCLI_AUTH="$(get_env REDIS_PASSWORD)" redis redis-cli ping | grep -q PONG
}

echo "📊 Status do Stack IA:"
echo "=========================================="
docker compose ps
echo ""
echo "🔎 Verificações:"
check "OmniRoute API (20129)"       curl -fsS --max-time 5 http://127.0.0.1:20129/v1/models
check "OmniRoute dashboard (20128)" curl -fsS --max-time 5 http://127.0.0.1:20128
check "Open Web UI (3000)"          curl -fsS --max-time 5 http://127.0.0.1:3000
check "Open Code (3001)"            open_code_health
check "Redis"                       redis_ping
check "Qdrant (6333)"               curl -fsS --max-time 5 http://127.0.0.1:6333/healthz
# Akita exige token no /mcp; qualquer resposta HTTP já prova que está no ar.
check "Akita AI Memory (49374)"     curl -sS --max-time 5 -o /dev/null http://127.0.0.1:49374/

echo ""
echo "🌐 Acessos (somente nesta máquina):"
echo "   Open Web UI:    http://localhost:3000"
echo "   Open Code:      http://localhost:3001"
echo "   OmniRoute API:  http://localhost:20129/v1"
echo "   OmniRoute UI:   http://localhost:20128"
echo "=========================================="

exit "$failed"
