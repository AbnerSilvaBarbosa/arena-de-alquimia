# MVP — Arena de alquimia

Plano inicial • 10 de outubro de 2026 • Nome de trabalho

Plataforma definida: desenvolver no MacBook, com Windows como plataforma principal de distribuição e testes finais. Exportar cliente macOS para desenvolvimento e servidor Linux para hospedagem. A VPS Hostinger já existente é a primeira candidata para o servidor; verificar sistema, arquitetura, CPU/RAM disponíveis, região e acesso UDP antes de confirmar sua capacidade.

## Objetivo

Dois jogadores reais, em computadores diferentes, entram numa sala privada pela internet, escolhem Edward ou Alphonse, confirmam Ready e disputam uma partida melhor de três em uma arena 2D de pixel art. Vence quem conquistar dois rounds; portanto, uma partida pode terminar em dois ou três rounds.

O diferencial é usar o cenário na luta: criar uma parede, quebrar cobertura e pegar ou arremessar uma caixa. A câmera é de cima, com sprites que mostram um pouco da frente do personagem, como na referência enviada. Os conceitos gerados são referências visuais, não medidas finais do mapa.

As medidas, tempos e quantidades abaixo são valores iniciais para testar, não compromissos de balanceamento. Godot instalado e utilizado: 4.7.2 estável, GDScript e renderer Compatibility.

## Fluxo completo

1. Tela inicial: Iniciar, Opções e Sair; volume e indicação de conexão.
2. Iniciar: Criar sala ou Entrar com código. Apelido temporário, sem conta.
3. O servidor cria uma sala privada para dois participantes e fornece um código copiável. Convite é compartilhar esse código fora do jogo.
4. Lobby: mostrar os dois jogadores, personagem selecionado, conexão e Ready. Permitir os dois escolherem o mesmo personagem.
5. Alterar personagem cancela o próprio Ready. Sala cheia e código inválido têm mensagens claras. Sala em partida não aceita novos participantes.
6. Com ambos prontos, carregar a arena; o servidor espera confirmação dos dois e inicia contagem de três segundos.
7. Combate: HUD com vida, resistência, recargas, tempo e placar de rounds.
8. Fim do round: anunciar vencedor e reiniciar jogadores, objetos, paredes, recursos e recargas.
9. Fim da partida: placar, revanche por confirmação dos dois ou voltar ao lobby. Sair de um participante encerra a sessão de revanche.

Desconexão no lobby libera a vaga e cancela Ready. Durante a partida, interromper a disputa, avisar o outro jogador e permitir voltar ao menu; sem retomada de partida no MVP. Falha do servidor também deve levar a uma tela recuperável.

## Regras da partida

- Melhor de três; dois rounds ganhos encerram a partida.
- Round de 90 segundos; derrota quando a vida chega a zero.
- No tempo limite, maior percentual de vida vence.
- Empate de vida ou nocaute simultâneo: round empatado, sem ponto; repetir o round. Isso pode gerar rodadas extras de desempate.
- Mesma arena durante toda a partida; posições de nascimento alternadas entre rounds.
- Sem progressão de atributos, itens equipáveis ou vantagens persistentes.

## Arena e câmera

Uma arena de pátio militar de Amestris, maior que uma única tela, com zonas conectadas e rotas alternativas. Não será um mundo aberto.

| Elemento | Proposta inicial |
| --- | --- |
| Tile | 32 × 32 pixels |
| Área jogável | 64 × 48 tiles, aproximadamente 2048 × 1536 pixels |
| Resolução lógica | 960 × 540, janela inicial 1280 × 720 e filtragem nearest |
| Sprite base | Quadro de 64 × 64; efeitos podem ultrapassar esse quadro |
| Câmera | Segue o jogador local, limitada às bordas; pequeno deslocamento na direção da mira |
| Layout | Pátio central, dois corredores laterais, cobertura e caixas em locais fixos |

O tamanho será validado pelo tempo de encontro: meta inicial de alcançar a área central em 3–5 segundos desde o nascimento. Um mapa grande demais vira perseguição e tempo morto. Queremos espaço para flanquear sem perder o confronto.

Mostrar indicador de direção quando o rival estiver fora da tela. Evitar paredes que ocultem sprites e corredores bloqueáveis sem saída: paredes criadas devem ser temporárias e destrutíveis. A colisão é 2D; não haverá altura real, salto sobre obstáculos ou rampas nesta versão.

## Combate incluído

Base comum: movimento em oito direções, mira livre, ataque básico, defesa frontal, esquiva, agarrão curto e interação com caixas. Resistência limita defesa e esquiva; habilidades têm recarga. Valores numéricos serão ajustados no protótipo.

| Personagem | Papel | Kit inicial |
| --- | --- | --- |
| Edward | Mobilidade e controle de terreno | Golpe de automail; parede temporária e destrutível; espinhos em linha com aviso no chão |
| Alphonse | Pressão próxima e deslocamento | Soco; investida curta que empurra; golpe no chão em área com preparação visível |

Ambos podem agarrar e arremessar caixas; Alphonse pode ter mais alcance ou força, a validar. Agarrão pega um oponente próximo que esteja defendendo; falhar deixa uma breve recuperação. No MVP, usa uma animação curta e empurrão, sem luta prolongada de agarrões.

Caixas são objetos fixos de cenário até serem carregadas. O jogador carrega uma por vez, move mais devagar e não usa habilidades enquanto carrega. Arremesso segue a mira e termina no primeiro impacto válido. A caixa quebra após impacto; não há coleta recursiva de destroços. Usar trajetória e colisão controladas pelo servidor, evitando depender de física livre para o combate online.

Defesa reduz dano frontal e consome resistência; agarrão supera defesa. Esquiva tem janela curta de invulnerabilidade e gasto de resistência. Golpes exibem preparação, contato e recuperação; não usar atordoamentos longos ou combos infinitos.

Especial com medidor, armas fabricáveis e interações complexas entre elementos ficam para a próxima versão. Duas habilidades por personagem já permitem testar identidade e confronto sem inflar a produção.

### Controles iniciais (remapeamento na interface fica para depois)

| Ação | Tecla |
| --- | --- |
| Mover | WASD |
| Mirar | Mouse |
| Ataque básico | Clique esquerdo |
| Defesa frontal | Segurar clique direito |
| Esquiva | Espaço |
| Habilidade 1 / 2 | Q / E |
| Agarrar oponente | R |
| Pegar caixa / arremessar caixa | F |
| Menu e opções | Esc |

Abrir o menu não pausa a partida online. Controles de gamepad ficam para depois da primeira versão, mantendo as ações separadas das teclas no Input Map.

## Fluidez, pixel art e animação

Meta de renderização: 60 FPS estáveis na máquina de referência, a definir. Simulação de combate: 60 passos por segundo. Isso não exige 60 desenhos diferentes por segundo em cada sprite.

Animações de pixel art podem usar 8–15 quadros por segundo, com tempos variáveis: preparação legível, contato rápido e recuperação clara. Movimento, câmera e efeitos podem atualizar a 60 FPS. Não produzir 30–60 desenhos por ação antes de validar o resultado.

Começar com quatro direções desenhadas e movimento em oito direções; expandir para oito conjuntos visuais se a leitura exigir. Não espelhar Edward indiscriminadamente, pois isso troca o lado do automail.

| Estado por personagem e direção | Quadros únicos iniciais |
| --- | --- |
| Parado | 4 |
| Movimento | 6–8 |
| Ataque básico | 6–8 |
| Defesa | 2–3 |
| Esquiva | 4–6 |
| Agarrão | 5–6 |
| Pegar, carregar e jogar | 8–12 somados |
| Cada habilidade | 6–10 |
| Receber golpe | 2–3 |
| Derrota | 6–8 |

Essas quantidades multiplicadas por direções e personagens são uma produção relevante. Primeiro validar com sprites provisórios; depois produzir um conjunto final de Edward e repetir o padrão para Alphonse. Efeitos, retratos e interface são assets separados.

Resposta visual: mira clara, indicadores de alcance, avisos de área, animações interrompidas apenas em estados permitidos, partículas moderadas e tremor discreto de câmera. Uma breve pausa visual de impacto pode afetar os efeitos locais, sem interromper o relógio autoritativo do servidor. Limitar suavização da câmera para preservar nitidez da pixel art.

## Multiplayer e distribuição

Decisão proposta: aplicativo para baixar em macOS e Windows, conectado a um servidor dedicado Linux via ENet/UDP. Godot oferece multiplayer de alto nível e exportação de servidor sem interface gráfica. [Multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html), [servidor dedicado](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html).

O jogador baixa o jogo exportado, não instala o editor Godot. A build macOS requer considerar assinatura e notarização para distribuição sem barreiras do sistema; definir isso antes do teste externo. [Exportação macOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html).

Separar duas entregas:

- **Distribuição do cliente:** arquivos das builds e instruções de instalação em uma página de downloads. Atualização manual no MVP.
- **Hospedagem do servidor:** processo Godot headless numa máquina Linux com endereço público, porta UDP acessível e região próxima dos jogadores. Hospedar arquivos ou uma página web não executa automaticamente o servidor de partidas.

Inicialmente um único processo pode cuidar de salas e partidas, mantendo cada sala isolada. Código de sala, Ready e revanche são lógica que desenvolveremos; não aparecem automaticamente ao exportar o Godot. Limitar a quantidade simultânea de salas após medir consumo. Sem banco de dados ou conta no MVP: salas existem em memória e desaparecem ao reiniciar o servidor.

Primeiro testar servidor e dois clientes no mesmo computador, depois em dois computadores na rede local, e por fim em redes distintas pela internet. Esse teste externo faz parte da entrega, não é um extra.

Escolher provedor somente após conferir suporte a UDP, região, recursos e custo atual. Um servidor dedicado tem custo recorrente, ainda não estimado. Este plano não contrata nem publica infraestrutura.

### Alternativas

| Opção | Uso e consequência |
| --- | --- |
| Um jogador hospeda | Útil em testes locais; acesso pela internet pode exigir configuração de roteador e enfrentar limitações da conexão residencial |
| Servidor dedicado + download | Recomendação para salas online: os dois clientes se conectam ao mesmo endereço público |
| Jogo no navegador | Facilita acesso, mas o navegador não permite ENet/UDP direto; requer arquitetura com WebRTC ou WebSocket e avaliação própria de latência |

As restrições de rede do navegador estão na [documentação de multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html). Não assumir que exportar para web preserva a solução ENet.

### Sincronização e resposta ao comando

Servidor decide vida, dano, resistência, recargas, colisões, objetos, rounds e placar. Clientes enviam comandos; servidor valida jogador, sala, frequência e se a ação é permitida. Cada sala tem limite de dois jogadores e verifica compatibilidade de versão antes de iniciar.

Prever movimento local imediatamente e reconciliar com o servidor; interpolar movimento remoto. Começar com snapshots de estado a 20–30 Hz e ajustar medindo rede. Eventos como seleção, Ready, criação/destruição de objetos e resultado precisam de entrega confiável; posições podem usar snapshots sequenciados sem aguardar retransmissão.

Previsão não elimina latência nem garante golpes perfeitos. Testar acertos, esquivas e agarrões com atraso artificial desde cedo. Rollback completo e compensação histórica de acertos ficam fora da primeira versão; se o combate ficar ruim no ping-alvo, rever a sincronização antes de investir em arte final.

## Áudio

- Uma música de menu e uma de batalha, com loop.
- Sons de interface, Ready, contagem, início/fim de round e vitória.
- Passos, golpes, defesa, esquiva, agarrão, caixa, pedra e alquimia.
- Volumes separados para geral, música e efeitos; limitar efeitos repetidos simultâneos.
- Usar áudio original ou assets com licença compatível, mantendo registro da origem. Sem dublagem nesta etapa.

## Estrutura de implementação

Separar cenas de menu, lobby, arena, jogador, objetos e HUD. Estados de jogador controlam ações e transições; estados de partida controlam lobby, carregamento, round, intervalo e resultado.

Dados de personagem e habilidade ficam em Resources: custo, recarga, alcance, preparação, recuperação, animação e efeitos. Comportamentos específicos continuam em código. Essa separação permite adicionar Roy, Isaac e depois personagens de outros universos sem refazer salas e regras de partida.

Mapa fixo com TileMapLayer; paredes temporárias são entidades separadas. Limitar quantidade de paredes e objetos ativos, com duração e vida, para manter rotas abertas e consumo previsível. O mundo de cada sala deve ser isolado na simulação e na replicação.

## Ordem de execução e critérios de passagem

1. **Fundação:** conferir Godot, criar projeto, Input Map, arena provisória e câmera. Validar escala e tempo de encontro.
2. **Rede mínima:** servidor + dois clientes, criar/entrar em sala, seleção, Ready e carregamento sincronizado. Testar pela internet cedo.
3. **Combate básico online:** movimento previsto, ataque, vida, defesa e esquiva. Validar resposta e acertos antes de ampliar o kit.
4. **Identidade e cenário:** habilidades dos dois personagens, agarrão, caixa e parede destrutível. Conferir igualdade de estado nos clientes.
5. **Partida completa:** rounds, desempate, placar, resultado, revanche e desconexão. Jogar partidas consecutivas.
6. **Apresentação:** pixel art final, animações, áudio, HUD, opções e feedback de impacto.
7. **Entrega externa:** builds macOS/Windows e servidor Linux, instruções de instalação, teste com duas pessoas em redes distintas.

Não fixar prazo antes dos testes de rede e do primeiro conjunto de animações. Multiplayer e produção de sprites são as maiores incertezas.

## Aceite do MVP

- Duas pessoas em redes diferentes completam menu → código de sala → seleção → Ready → partida → resultado → revanche.
- Edward e Alphonse funcionam; seleção espelhada também funciona.
- Vida, objetos, paredes, relógio e placar permanecem coerentes nos dois clientes.
- Uma partida termina corretamente em 2–0 ou 2–1; empate e desconexão têm comportamento definido.
- Testar ambos os jogadores disparando ações ao mesmo tempo e reset de cenário após cada round.
- Meta de 60 FPS em máquinas de referência identificadas, medida com efeitos e objetos ativos.
- Avaliar combate em RTT de 50, 100 e 150 ms, jitter de até 20 ms e perda de 1–2%. Meta inicial de boa resposta até 100 ms; registrar problemas em condições piores, sem prometer fluidez independente da conexão.
- Sala cheia, código inválido, build incompatível, carregamento que excede o limite e servidor indisponível exibem erros recuperáveis.
- Builds abrem fora do editor e têm instruções de instalação verificadas.

## Depois do MVP

Roy e Isaac; outros mapas; oito direções de animação; especiais; treino e bots; suporte a controles; matchmaking, contas e ranking; torneio com chave; espectadores; crossover com Hunter × Hunter; criação de habilidades; exportação web; atualização automática.

O modo entregue é um duelo privado melhor de três. A chave de torneio é expansão. A fundação e o teste local com dois clientes já foram implementados. A próxima validação externa é uma partida humana pela VPS.


## Implementação inicial — protótipo 0.1

Projeto Godot criado nesta pasta. Menu, treino, salas privadas por código, seleção Edward/Alphonse, Ready, carregamento, arena 2048 × 1536, combate, caixas, paredes, rounds e revanche implementados. Sprites, animações, VFX, retratos e imagens da UI são exports locais do PixelLab. O áudio é sintetizado e provisório. O conjunto cobre os estados do MVP, com idle em oito direções e ações em quatro; algumas animações são derivações de poses, não sequências inteiramente desenhadas do zero. Cliente Windows e servidor Linux exportados; presets estão no projeto.

As verificações locais ficam descritas em README.md e TEST_RESULTS.md. O aceite completo permanece pendente: instalação na VPS, partida humana em redes diferentes, execução nativa no Windows e refinamento final da arte e das animações. O protótipo tem previsão simples de movimento, sem rollback, e ainda não inclui gamepad ou remapeamento na interface.
