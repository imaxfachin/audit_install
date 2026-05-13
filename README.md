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
