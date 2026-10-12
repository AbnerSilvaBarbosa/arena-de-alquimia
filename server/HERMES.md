# Instalar o servidor de Arena de Alquimia

Contexto: VPS Hostinger KVM 2, Ubuntu 24.04, 2 vCPU, 8 GB de RAM, Campinas. Já roda Hermes, Obsidian e alguns fronts. Instalar este jogo como serviço separado, preservando tudo o que já existe.

Receber e extrair `Arena-Server-Linux-0.1.1.zip`. O pacote contém `arena-server`, `arena.service` e estas instruções. O executável já inclui os dados do jogo; não é necessário instalar Godot, compilar o código ou acessar GitHub.

## Checagens antes de instalar

```sh
uname -m
free -h
uptime
ss -lunp
systemctl is-active arena
```

Confirmar arquitetura x86_64 e que 7000/UDP está livre. Se já existir um serviço/pasta `arena`, inspecionar antes de substituir. Se não houver recursos disponíveis, reportar a situação ao usuário antes de iniciar o jogo.

## Instalação nova

A partir da pasta extraída, com privilégios administrativos:

```sh
id arena || sudo useradd --system --user-group --home-dir /var/lib/arena --shell /usr/sbin/nologin arena
sudo install -d -m 755 /opt/arena/current
sudo install -m 755 arena-server /opt/arena/current/arena-server
sudo install -m 644 arena.service /etc/systemd/system/arena.service
sudo systemctl daemon-reload
sudo systemctl enable --now arena
sudo systemctl status arena --no-pager
sudo journalctl -u arena -n 60 --no-pager
sudo ss -lunp
```

O systemd cria `/var/lib/arena`; o servidor pode escrever seus dados apenas ali. Limites iniciais: 512 MB de memória e CPUQuota 100% (até um núcleo lógico). Não alterar os limites ou serviços existentes do Hermes/Obsidian.

## Liberar acesso

Verificar o firewall existente. Se UFW estiver ativo, adicionar apenas a porta do jogo:

```sh
sudo ufw status
sudo ufw allow 7000/udp
```

Não habilitar, resetar ou desativar UFW como parte desta instalação; se estiver inativo, manter a configuração atual e verificar o firewall em uso. No painel Hostinger, a regra de entrada deve aceitar **UDP / porta 7000**. Manter SSH e todas as regras existentes.

O jogo não usa HTTP para as partidas. Não encaminhar essa porta pelo proxy web dos fronts. Usar o IP público direto; domínio opcional com registro DNS apontando à VPS, sem proxy HTTP.

## Entrega ao usuário

Informar IP/endereço público, porta 7000 e status do serviço. Solicitar que dois jogadores abram a mesma versão do cliente, criem/entrem por código, deem Ready e terminem uma partida e uma revanche. Confirmar logs sem erros. Nenhuma conta é necessária.

Monitorar CPU/RAM durante a partida e conferir que os serviços existentes seguem normais. Quatro salas é o limite inicial do software, não uma garantia de capacidade.

## Operação

```sh
sudo systemctl restart arena
sudo systemctl stop arena
sudo journalctl -u arena -f
```

Atualizações reiniciam o servidor e encerram salas em memória. Guardar a build anterior antes de substituir o executável; atualizar quando não houver jogadores. Se necessário, restaurar o executável anterior e reiniciar somente `arena`.

## GitHub

GitHub é opcional para histórico do código e futuras automações. O servidor do MVP funciona diretamente com este pacote. O código-fonte está em `Arena-Source-0.1.1.zip`, junto de testes e presets de exportação; não precisa copiá-lo para a VPS para executar a build pronta.
