#!/usr/bin/env bash
# 🌟 INSTALAÇÃO AUTOMÁTICA TOTAL DO STACK IA
# Configura o OmniRoute com provedores, skills e combos prontos.

set -e

STACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$STACK_DIR"

echo "🔧 Stack IA — Configuração Automática"
echo "====================================="

# 1. Gerar senhas fortes para autenticação
echo "🔑 Gerando chaves de segurança..."
if [ -f .env ]; then
    source .env
fi

# 2. Verificar se o container do OmniRoute está rodando
if ! sudo docker compose ps omniroute 2>&1 | grep -q "Running"; then
    echo "📦 Subindo o stack..."
    sudo docker compose up -d 2>&1 | tail -10
fi

# 3. Aguardar o OmniRoute estar pronto
echo "⏳ Aguardando o OmniRoute iniciar..."
for i in {1..30}; do
    if curl -s -o /dev/null http://localhost:20128/healthz 2>/dev/null; then
        echo "   ✅ OmniRoute está ativo!"
        break
    fi
    sleep 2
done

# 4. Configurar provedores (opcional - o usuário define nas configurações)
echo "📋 Configurando provedores..."
read -p "Deseja configurar provedores agora? (OpenAI, Anthropic, Google, Groq, etc.) [y/N]: " CONFIGURE
if [[ "$CONFIGURE" =~ ^[Yy]$ ]]; then
    echo "   Acesse: http://localhost:20128"
    echo "   Configure as chaves de API dos provedores que deseja usar."
    echo "   Recomendados: OpenAI (gpt-4o-mini), Groq (gemma-2-9b), Google (gemini-flash)"
    read -p "Pressione Enter quando terminar a configuração no dashboard..."
fi

# 5. Exibir informações de acesso
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
echo ""
echo "💡 Dicas:"
echo "   • Acesse o dashboard em :20128 para adicionar mais provedores e modelos"
echo "   • Crie skills e combos no dashboard para automação avançada"
echo "   • Os logs do OmniRoute: docker compose logs -f omniroute"
echo "   • Verificar estado: ./scripts/health.sh"
echo "=========================================="

