#!/usr/bin/env bash

## ------------------------------------------------------------------------------------------------------------------
# :> /tmp/audit_install.sh && chmod +x /tmp/audit_install.sh && nano /tmp/audit_install.sh
## ------------------------------------------------------------------------------------------------------------------
set -u
## -------------------------------------## Declarando Variáveis de Cores
readonly CYN='\033[1;96m' # Infos secundárias ou debug
readonly RED='\033[1;91m' # Erros e alertas críticos
readonly GRN='\033[1;92m' # Sucesso / OK
readonly YEL='\033[1;33m' # Avisos / atenção
readonly NC='\033[0m'     # Sem cor / reset
## ---------------------------------------------# Variáveis
readonly INSTALL_DIR="/usr/libexec"
readonly LOG_DIR="/usr/share/.audit"
readonly SERVICE_NAME="sshh-daily.service"
## ---------------------------------------------# Funções
info() { echo -e "\n--${CYN} [INFO]:> ${NC} $*"; }
warn() { echo -e "\n--${YEL} [AVISO]:>> ${NC} $*"; }
fatal() { echo -e "\n--${RED} [ERRO FATAL]:${NC} $* \n" >&2 && exit 1; }
success() { echo -e "\n--${GRN} [SUCESSO]:${NC} $* \n"; }
## ---------------------------------------------# Instalação e Preparação
update_check() {
    info "Atualizando o Sistema Operacional..."
    if command -v apt >/dev/null 2>&1; then
        apt update -qq >/dev/null 2>&1 || fatal "Falha ao atualizar repositórios (apt)."
    elif command -v dnf >/dev/null 2>&1; then
        dnf makecache -y >/dev/null 2>&1 || fatal "Falha ao atualizar repositórios (dnf)."
    elif command -v yum >/dev/null 2>&1; then
        yum makecache -y >/dev/null 2>&1 || fatal "Falha ao atualizar repositórios (yum)."
    else
        fatal "Gerenciador de pacotes NAO encontrado. [Encerrando o Script]..."
    fi
}
## ---------------------------------------------# Criando diretórios
install_vSHC() {
    if ! command -v shc >/dev/null 2>&1; then
        update_check
        if command -v apt >/dev/null 2>&1; then
            apt-get install -yq build-essential wget >/dev/null 2>&1 || fatal "Falha ao Instalar o Pacote: [build-essential wget]"
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y gcc make wget >/dev/null 2>&1 || fatal "Falha ao instalar dependências."
        elif command -v yum >/dev/null 2>&1; then
            yum install -y gcc make wget >/dev/null 2>&1 || fatal "Falha ao instalar dependências."
        else
            fatal "Gerenciador de pacotes NAO encontrado. [Encerrando o Script]..."
        fi
        wget -P /tmp https://github.com/neurobin/shc/archive/refs/tags/4.0.3.tar.gz >/dev/null 2>&1 || fatal "Falha ao Baixar o Arquivo: [ 4.0.3.tar.gz ]"
        # Extrai forçando o destino para dentro do /tmp
        tar -xf /tmp/4.0.3.tar.gz -C /tmp || fatal "Falha ao extrair o [ tar.gz ]."
        # pushd entra no diretório salvando de onde você veio
        pushd /tmp/shc-4.0.3 >/dev/null || fatal "Falha ao acessar o diretorio do [shc-4.0.3]."
        ./configure >/dev/null && make >/dev/null && make install >/dev/null
        # popd tira você daí de dentro e te devolve exatamente para onde você estava antes
        popd >/dev/null || fatal "Falha ao retornar ao diretorio Original do instalador."
        rm -rf /tmp/shc-4.0.3 /tmp/4.0.3.tar.gz
    fi
}
mk_dir() {
    chmod 755 "$INSTALL_DIR" >/dev/null 2>&1
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" >/dev/null 2>&1 || fatal "Falha ao Criar o Diretorio: ($LOG_DIR)"
        chmod 777 "$LOG_DIR" >/dev/null 2>&1
    fi
    if command -v chattr >/dev/null 2>&1; then
        chattr -ai "$LOG_DIR"/*.log >/dev/null 2>&1
    fi
    if [[ ! -f "$LOG_DIR/sessions.log" ]] || [[ ! -f "$LOG_DIR/commands.log" ]]; then
        touch "$LOG_DIR/sessions.log" "$LOG_DIR/commands.log" >/dev/null 2>&1 || warn "Falha ao Criar o Arquivos: ($LOG_DIR/*.log)"
        chmod 666 "$LOG_DIR"/*.log >/dev/null 2>&1
    else
        info "Arquivos de log já existem. Mantendo integridade."
    fi
    chattr +a "$LOG_DIR"/*.log 2>/dev/null || warn "chattr +a não suportado."
}
## ---------------------------------------------# Copiando arquivos
gen_arch() {
    cd /tmp || fatal "Falha ao acessar /tmp"
    rm -f "$INSTALL_DIR/sessiond" "$INSTALL_DIR/commandd"
    rm -f "$INSTALL_DIR"/*.sh.x.c "$INSTALL_DIR"/*.sh
    cat <<'EOL' >"$INSTALL_DIR/sessiond.sh"
#!/bin/bash
## ----------------------------------------------------------------------------
readonly LOG_FILE="/usr/share/.audit/sessions.log"
## ----------------------------------------------------------------------------
# Lê a saída do comando 'who' para listar os usuários logados
while true; do
    who | while read -r line; do
        USER=$(echo "$line" | awk '{print $1}')
        TTY=$(echo "$line" | awk '{print $2}')
        # Extrai IP entre parênteses
        IP=$(echo "$line" | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)')
        IP=${IP//[()]/}
        [[ -z "$IP" ]] && IP="Local"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] USER=$USER IP=$IP TTY=$TTY (Ativa)" >>"$LOG_FILE"
    done
    sleep 300
done
EOL
    cat <<'EOL1' >"$INSTALL_DIR/commandd.sh"
#!/bin/bash
## ----------------------------------------------------------------------------
readonly LOG_FILE="/usr/share/.audit/commands.log"
# ---------------- FILTROS ----------------
[[ -n "${COMP_LINE:-}" ]] && exit 0
[[ "$2" == "/usr/libexec/commandd"* ]] && exit 0
[[ "$2" =~ ^_ ]] && exit 0
# ---------------- DADOS ----------------
EXIT_CODE="${1:-0}"
LAST_COMMAND="${2:-N/A}"
## ----------------------------------------------------------------------------
USER_ORIGINAL=$(logname 2>/dev/null || echo "$USER")
USER_CURRENT=$(whoami)
[[ "$USER_ORIGINAL" != "$USER_CURRENT" ]] \
    && USER_DISP="(${USER_ORIGINAL})->(${USER_CURRENT})" \
    || USER_DISP="(${USER_CURRENT})"
## ----------------------------------------------------------------------------
#IP_RAW=$(who am i 2>/dev/null | awk '{print $NF}' | tr -d '()')
#[[ -z "$IP_RAW" || "$IP_RAW" == "localhost" ]] && IP_RAW="Local"
# Tenta pegar IP da sessão
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    IP_RAW=${SSH_CONNECTION%% *}
elif [[ -n "${SSH_CLIENT:-}" ]]; then
    IP_RAW=${SSH_CLIENT%% *}
else
    IP_RAW=$(who -m 2>/dev/null | awk '{print $NF}' | tr -d '()')
fi
[[ -z "$IP_RAW" ]] && IP_RAW="Local"
[[ "$LAST_COMMAND" == "history" ]] && exit 0
[[ "$LAST_COMMAND" == "clear" ]] && exit 0
## ----------------------------------------------------------------------------
#SUDO_USER_REAL="${SUDO_USER:-none}"
TTY=$(tty 2>/dev/null || echo "unknown")
HOST=$(hostname -f 2>/dev/null || hostname)
UID_REAL=$(id -u 2>/dev/null)
PWD_DIR="$PWD"
# ---------------- LOG ----------------
TMSTMP="$(date '+%Y-%m-%d %H:%M:%S')"
printf '[%s] | [IP]: %s | [HOST]: %s | [TTY]: %s | [UID]: %s | [USER]: %s | [PWD]: %s | [EXIT]: %s | [CMD]: %s\n' \
"$TMSTMP" \
"$IP_RAW" \
"$HOST" \
"$TTY" \
"$UID_REAL" \
"$USER_DISP" \
"$PWD_DIR" \
"$EXIT_CODE" \
"$LAST_COMMAND" >>"$LOG_FILE"
EOL1
    chmod +x "$INSTALL_DIR/sessiond.sh" "$INSTALL_DIR/commandd.sh" >/dev/null 2>&1 || fatal "Falha ao definir Permissoes..."
    shc -S -r -f "$INSTALL_DIR/sessiond.sh" -o "$INSTALL_DIR/sessiond" || fatal "Erro ao compilar sessiond"
    shc -S -r -f "$INSTALL_DIR/commandd.sh" -o "$INSTALL_DIR/commandd" || fatal "Erro ao compilar commandd"
    rm -f "$INSTALL_DIR/sessiond.sh" "$INSTALL_DIR/commandd.sh"
    rm -f "$INSTALL_DIR"/*.x.c
    chmod 755 "$INSTALL_DIR/sessiond" "$INSTALL_DIR/commandd"
}
## ---------------------------------------------# Instalando service
systemd_conf() {
    cat <<EOF >/etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=SSH Audit Logger Daemon
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/sessiond
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    info "Habilitando e Iniciando o servico... [systemd]" && sleep 1
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME} --quiet && sleep 1
    systemctl restart ${SERVICE_NAME} || fatal "Falha ao Reiniciar o Servico [ ${SERVICE_NAME} ]"
}
## ---------------------------------------------# Configurando profile global
profile_hook_conf() {
    cat <<'EOF' >/etc/profile.d/sshh_logger.sh
    # Evita duplicação dentro da sessão
__LAST_AUDIT_CMD=""

audit_capture() {
    local status=$?
    # Só executa em shell interativo
    [[ -z "${PS1:-}" ]] && return
    # Pega último comando do histórico
    local cmd
    cmd=$(history 1 2>/dev/null | sed 's/^[ ]*[0-9]\+[ ]*//')

    # Ignora vazio (ENTER)
    [[ -z "$cmd" ]] && return
    # Evita registrar o próprio logger
    [[ "$cmd" == "/usr/libexec/commandd"* ]] && return
    # Evita duplicação consecutiva
    [[ "$cmd" == "$__LAST_AUDIT_CMD" ]] && return
    __LAST_AUDIT_CMD="$cmd"

    # Envia para o logger
    /usr/libexec/commandd "$status" "$cmd"
}
# Não sobrescreve outros hooks
if [[ -n "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="audit_capture; $PROMPT_COMMAND"
else
    PROMPT_COMMAND="audit_capture"
fi
EOF
    chmod 644 /etc/profile.d/sshh_logger.sh || warn "Falha ao definir Permissoes"
}
## ---------------------------------------------# Instalando logrotate
log_conf() {
    if [[ -z "${LOG_DIR:-}" ]]; then
        fatal "A variável LOG_DIR está vazia. Abortando configuracao do [logrotate]."
    fi
    if [[ ! -d "/etc/logrotate.d" ]]; then
        warn "Diretório /etc/logrotate.d não encontrado. Instalando pacote [logrotate]..."
        update_check
        apt-get install -yq logrotate >/dev/null 2>&1 || warn "Falha ao instalar logrotate."
        mkdir -p /etc/logrotate.d || fatal "Falha ao criar o diretório ( /etc/logrotate.d )."
    fi
    cat <<EOF >/etc/logrotate.d/sshh-daily
$LOG_DIR/*.log {
    daily
    rotate 365
    compress
    missingok
    notifempty
    create 0600 root root
    prerotate
        /usr/bin/chattr -ai $LOG_DIR/*.log >/dev/null 2>&1 || true
    endscript
    postrotate
        /usr/bin/chattr +a $LOG_DIR/*.log >/dev/null 2>&1 || true
    endscript
}
EOF
}
unlock_files() {
    local user_home="${HOME:-/root}"
    command -v chattr >/dev/null 2>&1 || warn "Comando[chattr] NAO disponível."
    chattr -ai "$user_home/.bashrc" "$user_home/.bash_history" 2>/dev/null || warn "Erro ao Remover o atributo imutável."
    success "... [Processo Concluído]."
}
exit_code() {
    local SCRIPT_PATH
    unlock_files
    # success "SSH Audit Logger instalado com [ Maestria ] - [ OK ]" && sleep 3
    rm -f /tmp/4.0.3.tar.gz >/dev/null 2>&1
    # Por fim, se o script atual for o arquivo .sh avulso, ele se auto-exclui
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")"
    if [[ -f "$SCRIPT_PATH" && "$SCRIPT_PATH" == *.sh ]]; then
        rm -f "$SCRIPT_PATH" >/dev/null 2>&1
    fi
    exit 0
}
## ---------------------------------------------# Execução Principal (Main)
main() {
    install_vSHC
    mk_dir
    gen_arch
    systemd_conf
    profile_hook_conf
    log_conf
    exit_code
}
# Inicia o script
main
