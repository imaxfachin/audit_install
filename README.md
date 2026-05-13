
# SSH Audit Logger

Low-level auditing system for Linux servers that monitors and records user sessions and executed commands in real-time. The project focuses on **data integrity** and full terminal **traceability**.

## 🚀 Features

* **Session Monitoring:** Daemon that periodically records logged-in users and source IPs.
* **Command Auditing:** Real-time capture via `PROMPT_COMMAND`, logging directory (PWD), real user vs. sudo, and return code (EXIT) for every command.
* **Compiled Binaries:** Monitoring scripts compiled with `SHC` for enhanced security and performance.
* **Tamper Protection:** Utilizes the `chattr +a` (append-only) attribute, preventing logs from being deleted or modified, even by root.
* **Retention Management:** Native integration with `logrotate` to keep compressed history for up to 365 days.

## 🛠 Requirements

* **Systems:** Debian/Ubuntu, CentOS/RHEL 7, 8+, AlmaLinux, or Rocky Linux.
* **Tools:** Bash, systemd, and root privileges.
* **Dependencies:** The installer automatically configures `gcc`, `make`, `shc`, and `logrotate`.

## 📂 Project Structure

* `/usr/share/.audit/`: Protected directory where logs are stored.
* `/usr/libexec/`: Contains the compiled service binaries (`sessiond` and `commandd`).
* `/etc/profile.d/sshh_logger.sh`: Global hook that intercepts terminal activities.
* `/etc/systemd/system/sshh-daily.service`: Service responsible for persistent session monitoring.

## ⚙️ Installation

1. **Prepare the installation script and set permissions to run as root:**
```bash
 :> /tmp/audit_install.sh && chmod +x /tmp/audit_install.sh && nano /tmp/audit_install.sh
# Paste the script content, save, and exit.
```

## 📌 View Logs

```bash
 tail -f /usr/share/.audit/commands.log
```

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# SSH Audit Logger

Sistema de auditoria de baixo nível para servidores Linux que monitora e registra sessões de usuários e comandos executados em tempo real. O foco do projeto é a **integridade dos dados** e a **rastreabilidade** total do terminal.

## 🚀 Funcionalidades

* **Monitoramento de Sessão:** Daemon que registra usuários logados e IPs de origem periodicamente.
* **Auditoria de Comandos:** Captura em tempo real via `PROMPT_COMMAND`, registrando diretório (PWD), usuário real vs. sudo, e código de retorno (EXIT) de cada comando.
* **Binários Compilados:** Scripts de monitoramento compilados com `SHC` para maior segurança e performance.
* **Proteção Anti-Adulteração:** Utiliza o atributo `chattr +a` (append-only), impedindo que os logs sejam apagados ou modificados, mesmo pelo root.
* **Gestão de Retenção:** Integração com `logrotate` para manter históricos compactados por até 365 dias.

## 🛠 Requisitos

* Sistemas: Debian/Ubuntu, CentOS/RHEL 7, 8+, AlmaLinux ou Rocky Linux.
* Ferramentas: Bash, systemd e privilégios de root.
* Dependências: O instalador configura automaticamente gcc, make, shc e logrotate.

## 📂 Estrutura do Projeto

* `/usr/share/.audit/`: Diretório protegido onde residem os logs.
* `/usr/libexec/`: Contém os binários compilados do serviço (`sessiond` e `commandd`).
* `/etc/profile.d/sshh_logger.sh`: Hook global que intercepta as atividades do terminal.
* `/etc/systemd/system/sshh-daily.service`: Serviço responsável pelo monitoramento persistente das sessões.

## ⚙️ Instalação

1. **Prepare o script de instalação e permissão para executar como root:**
```bash
 :> /tmp/audit_install.sh && chmod +x /tmp/audit_install.sh && nano /tmp/audit_install.sh
# Cole o conteúdo do script, salve e saia.
```

## 📌 Visualizar Logs

```bash
 tail -f /usr/share/.audit/commands.log
```
