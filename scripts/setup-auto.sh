#!/usr/bin/env bash
# 🌟 Configuração automática do Stack IA
#  - verifica Docker e Docker Compose v2 (não instala nada por conta própria)
#  - cria as pastas, ajusta permissões e gera os segredos do .env
#  - sobe o stack e mostra o status
# Uso (a partir da pasta do projeto):  ./scripts/setup-auto.sh
set -euo pipefail

STACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$STACK_DIR"
source ./scripts/_lib.sh

echo "🔧 Stack IA — Configuração Automática"
echo "===================================="

# 1. Pré-requisitos ---------------------------------------------------
echo "🐳 Verificando Docker..."
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker não encontrado. Instale pelo guia oficial:"
    echo "   https://docs.docker.com/engine/install/"
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    echo "❌ O Docker não respondeu. Verifique se o serviço está ativo"
    echo "   (sudo systemctl start docker) e se seu usuário está no grupo docker"
    echo "   (sudo usermod -aG docker \$USER; depois saia e entre na sessão)."
    exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
    echo "❌ Plugin 'docker compose' (v2) não encontrado."
    echo "   Instale o docker-compose-plugin pelo guia oficial acima."
    exit 1
fi
for cmd in openssl curl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "❌ '$cmd' não encontrado. Instale-o e rode de novo."; exit 1; }
done
for f in docker-compose.yml .env.example; do
    [ -f "$f" ] || { echo "❌ Arquivo $f não encontrado em $STACK_DIR"; exit 1; }
done
echo "✅ $(docker --version)"
echo "✅ $(docker compose version)"

# 2. Pastas e permissões ----------------------------------------------
echo "📁 Preparando pastas..."
mkdir -p data/omniroute projetos
# O container do OmniRoute roda como UID 1000 (usuário node).
if [ "$(stat -c '%u' data/omniroute)" != "1000" ]; then
    echo "🔧 Ajustando dono de data/omniroute para UID 1000 (pede sudo)..."
    sudo chown -R 1000:1000 data/omniroute
fi
echo "✅ Pastas prontas (data/omniroute, projetos)"

# 3. Arquivo .env e segredos ------------------------------------------
echo "🔑 Preparando o .env..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📋 .env criado a partir do .env.example"
fi
chmod 600 .env

set_env() {
    if grep -qE "^$1=" .env; then
        sed -i "s|^$1=.*|$1=$2|" .env
    else
        [ -z "$(tail -c1 .env)" ] || echo >> .env
        printf '%s=%s\n' "$1" "$2" >> .env
    fi
}

# Define um valor padrão se a variável estiver ausente ou vazia (ex.: .env antigo).
default_env() {
    if [ -z "$(get_env "$1")" ]; then
        set_env "$1" "$2"
        echo "📝 $1 definido como padrão ($2)"
    fi
}

gen_secret() {
    if [ -z "$(get_env "$1")" ]; then
        set_env "$1" "$(openssl rand -hex 32)"
        echo "🔐 $1 gerado"
    fi
}

# Não gera chave nova se já há dados criptografados com outra.
if [ -z "$(get_env STORAGE_ENCRYPTION_KEY)" ] && [ -n "$(ls -A data/omniroute 2>/dev/null)" ]; then
    echo "❌ STORAGE_ENCRYPTION_KEY está vazia, mas já existem dados em data/omniroute."
    echo "   Uma chave nova deixaria as credenciais salvas ilegíveis."
    echo "   Coloque a chave antiga no .env e rode de novo."
    echo "   (Para recomeçar do zero, apague data/omniroute antes.)"
    exit 1
fi

default_env OMNIROUTE_API_KEY dummy
default_env OPENCODE_SERVER_USERNAME opencode

gen_secret STORAGE_ENCRYPTION_KEY
gen_secret REDIS_PASSWORD
gen_secret INITIAL_PASSWORD
gen_secret OMNIROUTE_WS_BRIDGE_SECRET
gen_secret WEBUI_SECRET_KEY
gen_secret OPENCODE_SERVER_PASSWORD

if [ "$(get_env OPENCODE_SERVER_PASSWORD)" = "opencode" ]; then
    echo "⚠️  OPENCODE_SERVER_PASSWORD ainda é 'opencode'. Troque por uma senha forte no .env."
fi

# 4. .gitignore -------------------------------------------------------
touch .gitignore
for entry in ".env" "data/"; do
    grep -qxF "$entry" .gitignore || echo "$entry" >> .gitignore
done

# 5. Validar o compose ------------------------------------------------
echo "🧪 Validando docker-compose.yml..."
docker compose config -q
echo "✅ Configuração válida"

# 6. Subir o stack ----------------------------------------------------
echo "🚀 Subindo o stack Docker..."
docker compose up -d

echo "⏳ Aguardando o OmniRoute responder..."
ready=0
for _ in $(seq 1 30); do
    if curl -fsS --max-time 3 -o /dev/null http://127.0.0.1:20129/v1/models 2>/dev/null; then
        ready=1
        break
    fi
    sleep 2
done
if [ "$ready" = 1 ]; then
    echo "✅ OmniRoute respondendo"
else
    echo "⚠️  OmniRoute ainda não respondeu. Veja: docker compose logs -f omniroute"
fi

echo ""
bash "$STACK_DIR/scripts/health.sh" || true

echo ""
echo "=========================================="
echo "✅ Stack IA configurado!"
echo "=========================================="
echo ""
echo "🌐 Acessos (somente nesta máquina):"
echo "   Open Web UI (chat):    http://localhost:3000"
echo "   Open Code (agente):    http://localhost:3001"
echo "   OmniRoute Dashboard:   http://localhost:20128"
echo "   OmniRoute API:         http://localhost:20129/v1"
echo ""
echo "🔑 Logins ficam no .env (não os compartilhe):"
echo "   grep -E '^(INITIAL_PASSWORD|OPENCODE_SERVER_USERNAME|OPENCODE_SERVER_PASSWORD)=' .env"
echo ""
echo "📁 Seus projetos ficam em ./projetos/ (no Open Code: /workspace/projetos)"
echo ""
echo "🔧 Comandos úteis:"
echo "   Iniciar: ./scripts/start.sh"
echo "   Parar:   ./scripts/stop.sh"
echo "   Health:  ./scripts/health.sh"
echo "   Apagar:  ./scripts/nuke.sh --help"
echo "   Logs:    docker compose logs -f omniroute"
echo "=========================================="
