# Stack IA — tudo em uma pasta

Ambiente local de IA para programação, em Docker Compose: roteador de LLMs, chat no navegador, agente de programação e memória de contexto. Tudo roda na sua máquina e fica acessível **somente em `localhost`**.

## O que está incluído

| Serviço | Container | Acesso no seu computador | Para que serve |
|---------|-----------|--------------------------|----------------|
| **OmniRoute** | `omniroute` | Dashboard `http://localhost:20128` · API `http://localhost:20129/v1` · WebSocket `20132` | Roteador de LLMs com API compatível com OpenAI |
| **Open WebUI** | `open-webui` | `http://localhost:3000` | Chat no navegador |
| **Open Code** | `open-code` | `http://localhost:3001` | Agente de programação com interface web (interface e API na mesma porta) |
| **Redis** | `redis` | `localhost:6379` (exige senha) | Obrigatório pelo OmniRoute |
| **Qdrant** | `qdrant` | `http://localhost:6333` (HTTP) · `6334` (gRPC) | Memória vetorial |
| **Akita AI Memory** | `akita-ai-memory` | `http://localhost:49374/mcp` (exige token) | Memória de contexto + servidor MCP |

**Não há IA local (Ollama) neste stack.** Para usar modelos de linguagem, cadastre as chaves dos provedores (OpenAI, Anthropic, Google, Groq, OpenRouter etc.) no dashboard do OmniRoute.

> **Entre containers, `localhost` é o próprio container.** Os serviços se falam pelo nome: por exemplo, o Open WebUI e o Open Code chamam o OmniRoute em `http://omniroute:20129/v1`. Os endereços `localhost` da tabela valem só para o seu navegador e o seu terminal.

## Requisitos

- Docker + Docker Compose v2 (`docker compose`, não o antigo `docker-compose`)
- `openssl` e `curl` (usados pelos scripts)
- RAM: 4 GB mínimo, 8 GB recomendado
- Disco: SSD com pelo menos 20 GB livres
- Arquitetura: amd64 (x86_64) ou arm64 (o Docker escolhe sozinho)

## Primeiros passos

```bash
# 1. Entre na pasta do stack
cd apptest

# 2. Torne os scripts executáveis
chmod +x scripts/*.sh

# 3. Configure e suba tudo
./scripts/setup-auto.sh
```

O `setup-auto.sh`:

- confere Docker, Compose, `openssl` e `curl` (não instala nada: se faltar algo, aponta o guia oficial);
- cria `data/omniroute` e `projetos`, ajustando o dono da primeira para o UID 1000 (usa `sudo` só se precisar);
- cria o `.env` a partir do `.env.example` e **gera todos os segredos que estiverem vazios ou com valor de exemplo**, sem alterar os que você já definiu;
- adiciona `.env` e `data/` ao `.gitignore`;
- valida o compose, sobe os containers e roda o `health.sh`.

Ele é seguro de rodar de novo: só completa o que falta. Uma exceção proposital: se a `STORAGE_ENCRYPTION_KEY` estiver vazia e já existirem dados em `data/omniroute`, o script **para** em vez de gerar uma chave nova, porque ela deixaria as credenciais já salvas ilegíveis. Coloque a chave antiga no `.env` e rode de novo.

Se preferir configurar à mão: `cp .env.example .env`, `chmod 600 .env`, preencha os campos vazios com `openssl rand -hex 32` e rode `./scripts/start.sh`.

Depois da primeira subida:

1. Abra o dashboard em **http://localhost:20128** e entre com a `INITIAL_PASSWORD` do `.env`. Cadastre as chaves dos provedores que for usar.
2. Use o chat em **http://localhost:3000**.
3. Use o agente em **http://localhost:3001**. O navegador pede usuário e senha (`OPENCODE_SERVER_USERNAME` e `OPENCODE_SERVER_PASSWORD`).

Para ver as senhas geradas:

```bash
grep -E '^(INITIAL_PASSWORD|OPENCODE_SERVER_USERNAME|OPENCODE_SERVER_PASSWORD)=' .env
```

## Controlando o stack

| Ação | Comando |
|------|---------|
| Primeira vez / completar configuração | `./scripts/setup-auto.sh` |
| Subir | `./scripts/start.sh` (avisa quais variáveis faltam no `.env`) |
| Parar (preserva tudo) | `./scripts/stop.sh` |
| Verificar status | `./scripts/health.sh` (testa cada serviço; sai com erro se algum falhar) |
| Remover containers e volumes | `./scripts/nuke.sh` |
| Remover também a configuração do OmniRoute | `./scripts/nuke.sh --data` |
| Remover também as imagens | `./scripts/nuke.sh --images` |
| Logs de um serviço | `docker compose logs -f omniroute` (ou `open-code`, `open-webui`…) |

**Sobre o `nuke.sh`:** ele lista o que vai apagar e só continua se você digitar o nome da pasta. Ele apaga containers e os volumes `redis-data`, `qdrant-data`, `akita-data` e `open-webui-data` (conversas, memórias e cache). Com `--data`, apaga também `data/omniroute`. Ele **nunca** apaga a pasta do projeto, `./projetos`, o `.env`, o compose ou os scripts.

Parar sem remover os containers: `./scripts/stop.sh`. Remover os containers preservando os volumes: `docker compose down`.

## Open WebUI (chat)

Já vem configurado para usar o OmniRoute (`http://omniroute:20129/v1`) com a `OMNIROUTE_API_KEY` do `.env`. Depois de cadastrar um provedor no dashboard, os modelos aparecem na lista do chat.

## Open Code (agente de programação)

O Open Code roda em um container com acesso **apenas** à sua pasta `./projetos/`, que ele enxerga como `/workspace/projetos`. Ele pode criar, editar e apagar arquivos nessa pasta e rodar comandos dentro do container (`npm`, `pip`, `git`…).

**O que fica protegido**

- O container não enxerga o seu `/home`, o `.env`, o `docker-compose.yml` nem outras pastas do computador.
- O socket do Docker não é montado em nenhum container, então o agente não controla o Docker do host.

**O que você precisa saber**

- `./projetos/` é a área de trabalho do agente e pode ser modificada por ele. Trate-a como tal e mantenha seus projetos sob controle de versão.
- Dependências instaladas dentro de um projeto (como `node_modules` ou `.venv`) ficam **dentro da pasta do projeto, no seu disco**. Já instalações globais e caches ficam no container e se perdem se ele for recriado.
- O isolamento é de arquivos e do Docker, não de rede: o agente consegue acessar a internet e os outros serviços do stack.

### Abrir um projeto

Coloque ou crie o projeto em `./projetos/meu-projeto/`. No diálogo "Abrir projeto" da interface, digite:

```
/workspace/projetos
```

As pastas de `./projetos/` aparecem para você escolher. O diálogo começa no home do container (`~/.cache`, `~/.config`…), por isso a pasta certa não aparece sozinha.

### Conectar ao OmniRoute

O endereço correto, visto de dentro do container, é `http://omniroute:20129/v1`. Em **Settings > Providers** use essa URL e a chave `OMNIROUTE_API_KEY`. Se preferir configurar por arquivo, um `opencode.json` na raiz do projeto aberto (por exemplo `./projetos/meu-projeto/opencode.json`) pode ficar assim:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "omniroute": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OmniRoute",
      "options": {
        "baseURL": "http://omniroute:20129/v1",
        "apiKey": "{env:OMNIROUTE_API_KEY}"
      },
      "models": {
        "auto/coding": { "name": "Auto Coding" },
        "auto/fast": { "name": "Auto Fast" }
      }
    }
  }
}
```

Os ids em `models` precisam existir no OmniRoute. Para listá-los: `curl http://localhost:20129/v1/models`.

## Configuração (`.env`)

O `.env.example` é o modelo, com todos os segredos vazios de propósito: valores de exemplo como `change-me` acabariam sendo usados de verdade. O `docker compose` se recusa a subir se alguma variável obrigatória estiver vazia.

| Variável | Usada por | Para que serve |
|----------|-----------|----------------|
| `STORAGE_ENCRYPTION_KEY` | OmniRoute | Criptografa as credenciais dos provedores em `./data/omniroute`. **Faça backup.** |
| `INITIAL_PASSWORD` | OmniRoute | Senha inicial do dashboard |
| `OMNIROUTE_WS_BRIDGE_SECRET` | OmniRoute | Segredo do bridge WebSocket |
| `OMNIROUTE_API_KEY` | Open WebUI, Open Code | Chave dos clientes para chamar o OmniRoute (`dummy` serve se ele não exigir chave) |
| `REDIS_PASSWORD` | Redis, OmniRoute | Senha do Redis |
| `AI_MEMORY_AUTH_TOKEN` | Akita AI Memory | Token do servidor MCP |
| `WEBUI_SECRET_KEY` | Open WebUI | Chave de assinatura das sessões |
| `OPENCODE_SERVER_USERNAME` | Open Code | Usuário do login (padrão `opencode`) |
| `OPENCODE_SERVER_PASSWORD` | Open Code | Senha do login |

Não existem variáveis para portas, modelo padrão ou chaves de provedores:

- as **portas** são fixas no `docker-compose.yml`;
- o **modelo** é escolhido na interface (Open WebUI ou Open Code), por exemplo `auto/coding`;
- as **chaves dos provedores** ficam no dashboard do OmniRoute, criptografadas com a `STORAGE_ENCRYPTION_KEY`.

Se você vem de uma versão antiga do `.env`, o `setup-auto.sh` avisa quais variáveis o compose atual não usa mais (como `AUTH_TOKEN`, `LLM_MODEL` e as de porta). Pode apagá-las.

## Segurança

- **Nada fica exposto à rede.** Todas as portas são publicadas em `127.0.0.1`. Para liberar uma porta para a rede local, edite `ports:` no `docker-compose.yml`, mas só depois de conferir que as senhas do `.env` são fortes.
- **Segredos só no `.env`.** O compose não contém nenhum valor sensível, e o `.env` fica fora do Git (`.gitignore`) com permissão 600.
- **Sem `docker.sock`.** Nenhum container tem acesso ao Docker do host.
- **Redis com senha** e o Open Code com login (Basic Auth). Troque a senha padrão `opencode` do Open Code por uma forte; se mudar depois, atualize a senha salva no navegador.
- **Trate a `STORAGE_ENCRYPTION_KEY` como insubstituível.** Se vazar, gere outra (os provedores terão de ser cadastrados de novo); se for perdida, as credenciais salvas ficam ilegíveis.
- **Versões:** o OmniRoute está fixado na `3.8.49`, mas as demais imagens usam `latest`, então uma atualização pode mudar o comportamento. Quando o stack estiver estável, vale fixar as versões no compose.

## Automação e CLI do OmniRoute

O OmniRoute tem uma CLI própria, executada dentro do container. Estes comandos vêm da documentação do projeto; confirme os disponíveis na sua versão com `docker exec omniroute omniroute --help`.

```bash
docker exec omniroute omniroute doctor                     # saúde do OmniRoute
docker exec omniroute omniroute providers                  # provedores disponíveis
docker exec omniroute omniroute providers test-batch       # testa os provedores
docker exec omniroute omniroute setup --non-interactive    # configuração não interativa
```

No dashboard (`http://localhost:20128`) você configura:

- **Provedores:** cadastre as chaves de API dos provedores que for usar.
- **Combos:** rotas que combinam vários modelos (por exemplo as `auto/...` que aparecem em `/v1/models`, como `auto/coding`, `auto/fast` e `auto/chat`).
- **Skills:** capacidades personalizadas para tarefas específicas.
- **Conexões MCP:** por exemplo, o Akita AI Memory em `http://akita-ai-memory:49374/mcp` (de dentro da rede do Docker) com o `AI_MEMORY_AUTH_TOKEN`.

## Monitoramento

```bash
./scripts/health.sh                      # status + teste de cada serviço
docker compose ps                        # containers
docker compose logs -f omniroute         # logs
curl http://localhost:20129/v1/models    # a API responde?
```

## Backup e atualização

**Backup:** o essencial é o `.env` (principalmente a `STORAGE_ENCRYPTION_KEY`) e a pasta `data/omniroute`. Os volumes `open-webui-data`, `qdrant-data`, `akita-data` e `redis-data` ficam gerenciados pelo Docker. Seus projetos estão em `./projetos/`.

```bash
./scripts/stop.sh
tar czf backup-$(date +%F).tar.gz .env data/omniroute projetos
```

Guarde o arquivo fora desta pasta e fora do Git, porque ele contém a chave de criptografia.

**Atualizar imagens:**

```bash
docker compose pull
docker compose up -d
```

Para mudar a versão do OmniRoute, edite a tag da imagem no `docker-compose.yml` antes de rodar o comando acima.

## Solução de problemas

**`required variable ... is missing a value`**
Faltam valores no `.env`. Rode `./scripts/setup-auto.sh`: ele completa só o que falta.

**401 no navegador normal, mas funciona em janela privativa**
O navegador guardou um login antigo para `localhost:3001` e o reenvia sozinho. Remova o login salvo (no Firefox: `about:logins`, procure `localhost`), limpe "Logins ativos" em Ctrl+Shift+Del e reinicie o navegador. Depois informe o usuário e a senha do `.env`.

**"Cannot connect to API: ECONNREFUSED" no Open Code, com novas tentativas em loop**
A URL do provedor aponta para um endereço que o container não alcança, tipicamente `localhost`. Use `http://omniroute:20129/v1`. Para testar de dentro do container:

```bash
docker exec open-code wget -qO- http://omniroute:20129/v1/models | head -c 300
```

**O diálogo "Abrir projeto" só mostra `~/.cache`, `~/.config`…**
Digite `/workspace/projetos` na busca (veja a seção do Open Code).

**`permission denied` em `data/omniroute` ou em `projetos`**
O container do OmniRoute roda como UID 1000. Para `data/omniroute`: `sudo chown -R 1000:1000 data/omniroute`. Para `projetos`, compare `docker exec open-code id` com `id -u` e ajuste o dono da pasta.

**O `setup-auto.sh` para reclamando da `STORAGE_ENCRYPTION_KEY`**
Existem dados em `data/omniroute` e o `.env` está sem a chave. Coloque a chave antiga no `.env`. Só apague `data/omniroute` se quiser recomeçar do zero.

**Porta já em uso**
Descubra quem usa: `ss -tlnp | grep 3001`. Pare o outro processo ou mude a porta em `ports:` no `docker-compose.yml`.

**Eu usava um proxy (Caddy) na porta 6658**
Não é mais necessário. Acesse o Open Code direto em `http://localhost:3001`. Se ainda houver um container de proxy rodando, pare-o com `docker stop <nome>`.

## Estrutura de pastas

```
apptest/
├── docker-compose.yml      # Serviços do stack (sem segredos)
├── .env.example            # Modelo das variáveis
├── .env                    # Seus segredos (fora do Git, permissão 600)
├── .gitignore              # Ignora .env e data/
├── README.md               # Esta documentação
├── scripts/
│   ├── setup-auto.sh       # Configuração automática (primeira vez)
│   ├── start.sh            # Subir o stack
│   ├── stop.sh             # Parar o stack
│   ├── health.sh           # Verificar o status
│   ├── nuke.sh             # Apagar containers e volumes (com confirmação)
│   └── _lib.sh             # Funções compartilhadas (não executar)
├── data/
│   └── omniroute/          # Dados do OmniRoute (fora do Git)
└── projetos/               # Área de trabalho do Open Code (/workspace/projetos)
```

Os volumes `redis-data`, `qdrant-data`, `akita-data` e `open-webui-data` são gerenciados pelo Docker e não aparecem nesta árvore.
