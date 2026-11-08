# Stack IA — Tudo em uma pasta só

Um ambiente completo de IA para programação, isolado em **uma única pasta**.

## O que está incluído

| Serviço | Porta | Para que serve |
|---------|-------|----------------|
| **OmniRoute** | 20128/20129/20132 | Roteador de LLMs (API OpenAI-compatível) |
| **Redis** | 6379 | Obrigatório pelo OmniRoute |
| **Qdrant** | 6333 | Memória vetorial (usada pelo OmniRoute) |
| **Akita AI Memory** | 49374 | Memória de contexto + servidor MCP |
| **Open Web UI** | 3000 | Interface de chat no navegador |
| **OpenHands** | — (sem porta) | Agente autônomo de programação |

**Não há IA local (Ollama) neste stack.** Você precisa configurar as chaves de API dos provedores (OpenAI, Anthropic, Google, etc.) no OmniRoute para usar modelos de linguagem.

## Requisitos

- Docker + Docker Compose v2
- RAM: 4 GB mínimo, 8 GB recomendado
- Disco: SSD com pelo menos 20 GB livres
- Arquitetura: amd64 (x86_64) ou arm64 (o Docker escolhe automaticamente)

## Instalação

```bash
# 1. Entre na pasta do stack
cd meu-ia-stack

# 2. Configure o arquivo de ambiente
cp .env.example .env
# Edite o .env se quiser mudar portas ou modelo padrão

# 3. Suba o stack
./scripts/setup-auto.sh
```

Na primeira vez, o Docker puxará as imagens do GHCR. Isso pode levar alguns minutos.

## Como usar

### Interface de chat (Open Web UI)
Abra no navegador: **http://localhost:3000**

O Open Web UI já está configurado para usar o OmniRoute (`http://localhost:20129/v1`).

### Agente de programação (OpenHands)
O OpenHands roda em um container isolado com acesso **apenas** à pasta:
```
./projetos/
```
Ele pode criar, editar, apagar arquivos, instalar dependências (`npm`, `pip`, etc.) e rodar comandos — tudo dentro dessa pasta.
Ele NÃO pode acessar:
- Seu `/home`, `/etc`, `/var`
- Outros projetos fora de `./projetos/`
- O Docker do seu sistema
- Seu sistema operacional diretamente

Qualquer dependência que ele instalar (node_modules, .venv, cache) fica dentro do Docker, nunca no seu sistema.

### Colocando seus projetos
Crie ou copie seus projetos dentro de:
```
meu-ia-stack/projetos/meu-projeto/
```
O OpenHands enxerga essa pasta como `/workspace` dentro do container.

## 🔧 Automação

Para configurar o stack automaticamente, incluindo provedores, skills e combos, consulte:
- **AUTOMATION_SECTION.md** — Documentação detalhada de automação
- **scripts/setup-auto.sh** — Script de configuração automática
- **scripts/health.sh** — Verificar o status do stack

O OmniRoute tem um CLI completo:
```bash
# Verificar saúde do OmniRoute
docker exec omniroute omniroute doctor

# Listar provedores disponíveis
docker exec omniroute omniroute providers

# Testar provedores
docker exec omniroute omniroute providers test-batch

# Configurar via CLI não interativa
docker exec omniroute omniroute setup --non-interactive
```

## Controlando o stack

| Ação | Comando |
|------|---------|
| Subir tudo | `./scripts/setup-auto.sh` |
| Parar (preserva dados) | `./scripts/stop.sh` |
| Parar e remover containers (preserva volumes) | `docker compose down` |
| Apagar **tudo** (containers, volumes, dados, pasta) | `./scripts/nuke.sh` |

## Automação Avançada

### Configuração de Provedores via CLI
```bash
# Listar provedores disponíveis
docker exec omniroute omniroute providers

# Testar em lote
docker exec omniroute omniroute providers test-batch

# Configurar não interativamente
docker exec omniroute omniroute setup --non-interactive
```

### Skills e Combos
Após configurar as chaves de API no dashboard (http://localhost:20128):
- **Skills**: Crie habilidades personalizadas para tarefas específicas
- **Combos**: Crie combinações de modelos para rotas inteligentes
- **Auto-Combo**: OmniRoute escolhe automaticamente o melhor modelo para cada tarefa

### Monitoramento
```bash
# Ver status do stack
./scripts/health.sh

# Ver logs do OmniRoute
docker compose logs -f omniroute

# Testar API
curl http://localhost:20129/v1/models
```

## Observações importantes

1. **Autenticação:** Altere as senhas e tokens padrão antes de utilizar em rede.
2. **Sem IA local:** Você precisa de chaves de API de provedores (OpenAI, Anthropic, etc.) configuradas no OmniRoute.
3. **OpenHands é autônomo:** Ele pode decidir rodar comandos que você não antecipou. Dentro de `./projetos/` isso é seguro (está trancado no Docker), mas trate essa pasta como uma área de trabalho que pode ser modificada pelo agente.
4. **Build do OmniRoute:** Esta configuração usa a imagem oficial `diegosouzapw/omniroute:3.8.49` do GHCR, sem build local. Para usar uma versão diferente, edite `docker-compose.yml`.
