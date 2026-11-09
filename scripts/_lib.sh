# shellcheck shell=bash
# Funções compartilhadas pelos scripts. Não é executado direto:
#   cd "$(dirname "$0")/.."      # raiz do stack
#   source ./scripts/_lib.sh

# Variáveis que o docker-compose.yml exige no .env.
REQUIRED_VARS=(
    STORAGE_ENCRYPTION_KEY INITIAL_PASSWORD OMNIROUTE_WS_BRIDGE_SECRET
    OMNIROUTE_API_KEY REDIS_PASSWORD AI_MEMORY_AUTH_TOKEN WEBUI_SECRET_KEY
    OPENCODE_SERVER_USERNAME OPENCODE_SERVER_PASSWORD
)

# Valor de uma variável no .env (a última ocorrência vale). Vazio se ausente.
get_env() {
    [ -f .env ] && grep -E "^$1=" .env | tail -n1 | cut -d= -f2- | tr -d '\r' || true
}

# Para parar, listar ou apagar, o compose só precisa que as variáveis existam.
# Preenche com um valor falso o que estiver ausente ou vazio no .env
# (só para este processo; o .env não é alterado e nada é iniciado com isso).
fill_missing_env() {
    local v
    for v in "${REQUIRED_VARS[@]}"; do
        if [ -z "$(get_env "$v")" ]; then
            export "$v=placeholder"
        fi
    done
}
