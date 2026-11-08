#!/usr/bin/env bash
# 🌟 INSTALAÇÃO AUTOMÁTICA TOTAL DO STACK IA
# Configura o OmniRoute com provedores, skills e combos prontos.
# Automação de Docker, TLS client, correções de permissão e typo.
set -e

STACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="/home/jack/Documentos/GitHub/apptest"
cd "$STACK_DIR"

echo "🔧 Stack IA — Configuração Automática"
echo "===================================="

# 1. Verificar e instalar Docker se necessário
echo "🐳 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "🔧 Docker não encontrado, instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
fi
echo "✅ Docker disponível: $(docker --version)"

# 2. Verificar e instalar Docker Compose se necessário
echo "📦 Verificando Docker Compose..."
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
    echo "🔧 Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi
echo "✅ Docker Compose disponível: $(docker compose version 2>/dev/null || docker-compose version)"

# 3. Corrigir permissão do diretório TLS client (Erro EACCES: permission denied)
echo "🔧 Corrigindo permissão do diretório TLS client..."
sudo chown -R 1000:1000 "$PROJECT_DIR/data/omniroute"
echo "✅ Permissão corrigida para UID 1000 (usuário node do container OmniRoute)"

# 4. Corrigir typo no docker-compose.yml (opendands -> openhands)
echo "🔧 Corrigindo typo no docker-compose.yml..."
if grep -q "/home/opendands/.local" "$PROJECT_DIR/docker-compose.yml"; then
    sed -i 's|/home/opendands/.local|/home/openhands/.local|g' "$PROJECT_DIR/docker-compose.yml"
    echo "✅ Typo corrigido: opendands → openhands"
else
    echo "ℹ️  Typo já corrigido ou não encontrado"
fi

# 5. Adicionar bind mount do binário Docker para o container OpenHands
echo "🔧 Configurando Docker CLI dentro do container OpenHands..."
if ! grep -q "/usr/bin/docker:/usr/bin/docker:ro" "$PROJECT_DIR/docker-compose.yml"; then
    sed -i '/- \.\/openhands-data:\/\/.openhands/a\      - /usr/bin/docker:/usr/bin/docker:ro' "$PROJECT_DIR/docker-compose.yml"
    echo "✅ Bind mount do docker binary adicionado para OpenHands"
else
    echo "ℹ️  Bind mount do docker já configurado"
fi

# 6. Verificar estrutura de diretórios
echo "📁 Verificando estrutura de diretórios..."
mkdir -p "$PROJECT_DIR/data/omniroute"
mkdir -p "$PROJECT_DIR/data/redis"
mkdir -p "$PROJECT_DIR/data/qdrant"
mkdir -p "$PROJECT_DIR/projetos"
mkdir -p "$PROJECT_DIR/openhands-data"

# 7. Gerar senhas fortes se .env não existir
echo "🔑 Gerando chaves de segurança..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📋 Arquivo .env criado a partir do .env.example"
fi
if [ -f .env ]; then
    source .env
fi

# 8. Definir senhas padrão se não definidas
if [ -z "${INITIAL_PASSWORD}" ]; then
    INITIAL_PASSWORD=$(openssl rand -hex 32)
    sed -i "s|^INITIAL_PASSWORD=.*|INITIAL_PASSWORD=${INITIAL_PASSWORD}|" .env
    echo "🔐 Senha inicial do dashboard gerada"
fi
if [ -z "${AUTH_TOKEN}" ]; then
    AUTH_TOKEN=$(openssl rand -hex 32)
    sed -i "s|^AUTH_TOKEN=.*|AUTH_TOKEN=${AUTH_TOKEN}|" .env
    echo "🔐 Token de segurança gerado"
fi
if [ -z "${OMNIROUTE_WS_BRIDGE_SECRET}" ]; then
    OMNIROUTE_WS_BRIDGE_SECRET=$(openssl rand -hex 32)
    sed -i "s|^OMNIROUTE_WS_BRIDGE_SECRET=.*|OMNIROUTE_WS_BRIDGE_SECRET=${OMNIROUTE_WS_BRIDGE_SECRET}|" .env
    echo "🔐 WebSocket bridge secret gerado"
fi

# 9. Pull da imagem do OpenHands
echo "📦 Pull da imagem OpenHands..."
docker pull ghcr.io/all-hands-ai/openhands:latest

# 10. Subir o stack
echo "🚀 Subindo o stack Docker..."
sudo docker compose up -d

# 11. Aguardar e verificar status
echo "⏳ Aguardando serviços inicializarem..."
sleep 20

echo ""
echo "📊 Status dos serviços:"
docker compose ps

echo ""
echo "=========================================="
echo "✅ Stack IA configurado com sucesso!"
echo "=========================================="
echo ""
echo "🌐 Acessos:"
echo "   Open Web UI (chat):    http://localhost:3000"
echo "   OmniRoute Dashboard:   http://localhost:20128"
echo "   OmniRoute API:         http://localhost:20129/v1"
echo "   Akita AI Memory MCP:   http://localhost:49374/mcp"
echo ""
echo "📁 Seus projetos ficam em: ./projetos/"
echo ""
echo "🔧 Comandos úteis:"
echo "   Parar:   ./scripts/stop.sh"
echo "   Apagar:  ./scripts/nuke.sh"
echo "   Health:  ./scripts/health.sh"
echo ""
echo "💡 Dicas:"
echo "   • Acesse o dashboard em :20128 para adicionar mais provedores e modelos"
echo "   • Crie skills e combos no dashboard para automação avançada"
echo "   • Os logs do OmniRoute: docker compose logs -f omniroute"
echo "   • Verificar estado: ./scripts/health.sh"
echo "=========================================="
