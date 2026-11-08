# 📖 Seção de Automação — Stack IA

Este documento descreve como automatizar a configuração do OmniRoute, incluindo conexões com provedores de IA, skills, combos e integrações.

## 📋 Visão Geral

O stack inclui:
- **OmniRoute** — Roteador de LLMs (API OpenAI-compatível)
- **Redis** — Banco de dados de cache/redis
- **Qdrant** — Memória vetorial
- **Akita AI Memory** — Memória de contexto + servidor MCP
- **Open Web UI** — Interface de chat
- **OpenHands** — Agente de programação autônomo

## ⚙️ Variáveis de Ambiente (docker compose .env)

### Configuração do OmniRoute
```env
# Senha inicial do dashboard (ALTERAR!)
INITIAL_PASSWORD=sua-senha-forte-aqui

# API key de segurança do WebSocket
OMNIROUTE_WS_BRIDGE_SECRET=$(openssl rand -hex 32)

# Token de segurança geral
AUTH_TOKEN=$(openssl rand -hex 32)

# Chaves de API dos provedores (definidas no dashboard após start)
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-ant-...
# GOOGLE_API_KEY=...
# GROQ_API_KEY=...
# OPENROUTER_API_KEY=...
# DEEPSEEK_API_KEY=...
```

### Configuração dos Serviços
```env
# Portas
REDIS_PORT=6379
PORT=20128          # Dashboard do OmniRoute
DASHBOARD_PORT=20128
API_PORT=20129      # API do OmniRoute
LIVE_WS_PORT=20132
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334
AI_MEMORY_PORT=49374
WEBUI_PORT=3000

# Modelo padrão
LLM_MODEL=gpt-4o-mini
```

### Autenticação
```env
AI_MEMORY_AUTH_TOKEN=seu-token-aqui
```

## 🚀 Comandos de Controle

| Ação | Comando |
|------|---------|
| Subir tudo | `./scripts/start.sh` |
| Parar | `./scripts/stop.sh` |
| Apagar tudo | `./scripts/nuke.sh` |
| Setup automático | `./scripts/setup-auto.sh` |
| Verificar status | `./scripts/health.sh` |

## 🤖 Automação via CLI (dentro do container omniroute)

O OmniRoute tem um CLI completo para configuração via linha de comando:

```bash
# Verificar saúde do OmniRoute
sudo docker exec omniroute omniroute doctor

# Listar provedores disponíveis
sudo docker exec omniroute omniroute providers

# Testar provedores
sudo docker exec omniroute omniroute providers test-batch

# Configurar via CLI não interativa
sudo docker exec omniroute omniroute setup --non-interactive

# Ver logs de uso
sudo docker exec omniroute omniroute logs --follow
```

## 🔌 Configuração de Provedores

Após a primeira subida, acesse o dashboard em **http://localhost:20128** e configure:

1. **Provedores** — Adicione e configure kits de API (OpenAI, Anthropic, Google, Groq, OpenRouter, Deepseek, etc.)
2. **Skills** — Crie skills personalizados para tarefas específicas
3. **Combos** — Crie combos que combinam múltiplos modelos para rotas inteligentes
4. **Connections** — Configure conexões MCP (Akita AI Memory, etc.)

### Provedores Suportados (padrão)
- `openai` — OpenAI GPT-4o, GPT-4o-mini, etc.
- `anthropic` — Claude 3.5 Sonnet, Claude 3 Haiku, etc.
- `google` — Gemini 2.0 Flash, Gemini 1.5 Pro, etc.
- `groq` — Llama 3.3 70B, Gemma 2 9B, etc.
- `openrouter` — 100+ provedores via OpenRouter
- `deepseek` — DeepSeek R1, DeepSeek Chat, etc.

## 🤖 Skills e Combos

### Skills
Skills são capacidades personalizadas que você adiciona ao OmniRoute. Exemplos:
- Resumo de documentos
- Análise de código
- Tradução
- Geração de imagens
- Cálculo financeiro

### Combos
Combos são rotas inteligentes que combinam múltiplos modelos:
- **Auto-Combo** — OmniRoute escolhe o melhor modelo automaticamente
- **Cost-Effective** — Modelos econômicos para uso diário
- **Quality** — Modelos de alto custo para tarefas críticas
- **Vision** — Modelos especializados em imagens
- **Reasoning** — Modelos de raciocínio profundo

## 📊 Monitoramento

### Logs do OmniRoute
```bash
docker compose logs -f omniroute
```

### Estado do Stack
```bash
./scripts/health.sh
```

### API do OmniRoute
```bash
curl http://localhost:20129/v1/models
curl http://localhost:20128/healthz
```

## 🔒 Segurança

⚠️ **IMPORTANTE:** Altere as senhas e tokens por padrão antes de usar em rede!

1. `INITIAL_PASSWORD` — Defina uma senha forte
2. `AUTH_TOKEN` — Gere um token aleatório
3. `OMNIROUTE_WS_BRIDGE_SECRET` — Gere um token aleatório
4. `AI_MEMORY_AUTH_TOKEN` — Gere um token aleatório

Para gerar tokens seguros:
```bash
openssl rand -hex 32
```

## 📁 Estrutura de Pastas

```
apptest/
├── docker-compose.yml          # Configuração do Docker
├── .env                        # Variáveis de ambiente (copiar .env.example)
├── .env.example                # Modelo de variáveis
├── README.md                   # Documentação principal
├── AUTOMATION_SECTION.md       # Esta documentação
├── scripts/
│   ├── start.sh                # Subir o stack
│   ├── stop.sh                 # Parar o stack
│   ├── nuke.sh                 # Apagar tudo
│   ├── health.sh               # Verificar status
│   └── setup-auto.sh           # Configuração automática
└── projetos/                   # Pasta dos projetos do OpenHands
```

## 🚀 Primeiros Passos

1. **Copiar .env.example para .env**
   ```bash
   cp .env.example .env
   ```

2. **Editar .env** com as senhas e tokens seguros

3. **Subir o stack**
   ```bash
   ./scripts/setup-auto.sh
   ```

4. **Acessar o dashboard** em http://localhost:20128
   - Configure as chaves de API dos provedores que você deseja usar
   - Crie skills e combos conforme necessário

5. **Usar o chat** em http://localhost:3000
