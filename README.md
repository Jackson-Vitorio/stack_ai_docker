# Stack IA — Tudo em uma pasta só

Um ambiente completo de IA para programação, isolado em **uma única pasta**.
Para instalar: copie/clonhe esta pasta. Para apagar: delete a pasta.

## O que está incluído

| Serviço | Porta | Para que serve |
|---------|-------|----------------|
| **OmniRoute** | 20128/20129/20132 | Roteador de LLMs (API OpenAI-compatível) |
| **Redis** | 6379 | Obrigatório pelo OmniRoute |
| **Qdrant** | 6333 | Memória vetorial (usada pelo OmniRoute) |
| **Akita AI Memory** | 49374 | Memória de contexto + servidor MCP |
| **Ollama** | 11434 | Modelos LLMs locais privados |
| **Open Web UI** | 3000 | Interface de chat no navegador |
| **OpenHands** | — (sem porta) | Agente autônomo de programação |

## Requisitos

- Docker + Docker Compose v2
- RAM: 6 GB mínimo, 12 GB recomendado
- Disco: SSD com pelo menos 50 GB livres
- Arquitetura: amd64 ou arm64

## Instalação

```bash
# 1. Entre na pasta do stack
cd meu-ia-stack

# 2. Configure o arquivo de ambiente
cp .env.example .env
# Edite o .env se quiser mudar portas, modelo ou token

# 3. Suba o stack
./scripts/start.sh
```

Na primeira vez, o Docker:
1. Clona o código-fonte do OmniRoute do GitHub durante o build
2. Baixa e inicia Ollama
3. Baixa o modelo `qwen3:4b` (pode demorar alguns minutos)

## Como usar

### Interface de chat (Open Web UI)

Abra no navegador: **http://localhost:3000**

O Open Web UI já está configurado para usar o OmniRoute (`http://localhost:20129/v1`). Selecione o modelo `qwen3:4b` e comece a conversar.

### Agente de programação (OpenHands)

O OpenHands roda em um container isolado com acesso **apenas** à pasta:

```
./projetos/
```

Ele pode criar, editar, apagar arquivos, instalar dependências (`npm`, `pip`, etc.) e rodar comandos — tudo dentro dessa pasta.

**Ele NÃO pode acessar:**
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

## Controlando o stack

| Ação | Comando |
|------|---------|
| Subir tudo | `./scripts/start.sh` |
| Parar (preserva dados) | `./scripts/stop.sh` |
| Parar e remover containers (preserva volumes) | `docker compose down` |
| Apagar **tudo** (containers, volumes, dados, pasta) | `./scripts/nuke.sh` |

## Apagando completamente

```bash
./scripts/nuke.sh
```

Isso remove containers, volumes e deleta a pasta inteira do seu computador. Não resta nenhum processo nem dado relacionado no sistema.

## Observações importantes

1. **Modelo Qwen:** O Ollama usa `qwen3:4b` por padrão. Se esse modelo não estiver disponível no Ollama, altere `LLM_MODEL` no `.env` para outro que exista (ex: `qwen2.5:7b`, `llama3.1:8b`).

2. **OpenHands é autônomo:** ele pode decidir rodar comandos que você não antecipou. Dentro de `./projetos/` isso é seguro (está trancado no Docker), mas trate essa pasta como uma área de trabalho que pode ser modificada pelo agente. Use git dentro dela para conseguir desfazer mudanças.

3. **Build do OmniRoute:** Na primeira vez, o Docker precisa clonar o repositório e compilar. Pode levar alguns minutos.

4. **Open Web UI roda no navegador:** não instala nada no seu sistema além do navegador que você já usa.