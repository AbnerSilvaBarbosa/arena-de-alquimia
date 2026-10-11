# Servidor Ubuntu 24.04

O pacote Linux é um executável com os dados do jogo incorporados. Não precisa de editor, tela, nginx ou banco de dados. Quatro salas é o limite inicial de software, não uma capacidade garantida da VPS.

## Instalação inicial

Verificar antes: `uname -m` deve indicar `x86_64`; conferir `free -h`, `uptime`, serviços existentes e porta com `ss -lunp`. Não reinstalar o sistema nem alterar os serviços Hermes/Obsidian.

Enviar `builds/linux/arena-server` e `server/arena.service` via SSH/SCP. Criar um usuário de sistema `arena` sem login e a pasta `/opt/arena/current`, instalar o executável nela e dar permissão de execução. Instalar o arquivo de serviço em `/etc/systemd/system/arena.service`, executar `systemctl daemon-reload`, depois `systemctl enable --now arena`.

O serviço limita o jogo a 512 MB e até uma CPU. Medir o uso real e ajustar depois. O `StateDirectory` cria `/var/lib/arena` para os arquivos locais do processo; o diretório do executável fica separado.

Abrir **7000/UDP** no firewall Hostinger. Se o UFW estiver ativo, adicionar apenas `ufw allow 7000/udp`; manter as regras de SSH e serviços existentes. Não executar reset de firewall. Para conectar, usar o IP público da VPS e porta 7000 no cliente. Domínio é opcional.

Verificação: `systemctl status arena`, `journalctl -u arena -n 80 --no-pager`, `ss -lunp`. Depois criar uma sala e jogar com duas máquinas em redes diferentes. Porta aberta sozinha não confirma que uma partida funciona.

Para atualização: guardar a build anterior, substituir apenas o executável e `systemctl restart arena`. Reiniciar encerra as salas em memória; fazer quando não houver jogadores. Logs não guardam senhas nem contas, pois o protótipo não tem autenticação de usuário.

## Estado atual

Build preparada localmente. Nenhuma mudança foi executada na VPS. O usuário delegou a instalação ao Hermes; entregar o pacote Linux e seguir HERMES.md. Depois validar uma partida entre duas pessoas em redes diferentes.
