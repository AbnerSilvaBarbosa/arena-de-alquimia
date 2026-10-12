# Verificação do protótipo

Data: 11/10/2026. Godot 4.7.2, desenvolvimento em macOS / Apple M5.

## Resultados funcionais

- 32 verificações de simulação aprovadas: colisões, combate, defesa, agarrão, esquiva, habilidades, paredes, caixas, rounds, empates, revanche e desconexão.
- Servidor e dois clientes em processos separados: criação/entrada em sala, seleção, Ready, carregamento e sincronização de movimento aprovados. O teste ampliado completou dois rounds, resultado 2–0 e confirmação de revanche, verificando reset de vida e placar nos dois clientes.
- Rejeições verificadas: terceiro jogador na sala, código inexistente e protocolo incompatível.
- Rede com aproximadamente 100 ms de ida e volta, jitter e 1% de perda simulada: testes de protocolo aprovados.
- O pacote Linux final embarcado foi carregado pelo Godot no Mac e completou dois rounds e revanche com dois clientes reais, 369/372 snapshots, 100 ms RTT e 1% de perda. Rejeições de sala cheia/código inexistente/protocolo incompatível também aprovadas. Isso valida os recursos exportados, mas não a execução nativa do binário Linux.
- Capturas das telas inicial, conexão, lobby, opções, arena e resultado verificadas. Também verificados nomes de 20 caracteres no tamanho mínimo de janela.

- Assets finais PixelLab: 1.083 verificações, 294 texturas, nenhuma falha. Dois personagens com 13 estados, sete efeitos, cenário e imagens da UI.

## Limites da evidência

Medição final de 18 segundos com todos os assets, bot e habilidades: 1.681 amostras, mínimo e média de 120 FPS; monitor TIME_PROCESS médio de 14,669 ms no Apple M5. A janela ficou no teto de atualização observado. Esse número não estima desempenho em Windows ou capacidade da VPS. O teste de combate com bot ainda não substitui uma partida humana pela internet.

Ainda faltam execução nativa em Windows e Linux, instalação pelo Hermes, teste entre duas pessoas pela VPS e ajustes de sensação do combate com latência real.

Comandos reproduzíveis estão no README. A revisão visual final dos assets PixelLab teve disposição `ship` para as três correções apontadas: nomes sobrepostos, títulos e registro da direção. Os três itens foram resolvidos nas recapturas. Esse veredito não comprova fluidez de animação ou execução nativa em Windows.

O cliente Windows final, carregado pelo Godot do Mac como main-pack, passou nas mesmas 1.083 verificações de assets e renderizou o menu com fonte e imagens embarcadas. Não é execução nativa do arquivo EXE.

O teste ampliado de partida/revanche pode ser reproduzido com `python3 tests/run_network.py --godot /caminho/do/godot --rtt-ms 100 --loss 0.01 --duel`. As capturas são feitas pelo renderer do Godot. Não foi concluída uma sessão manual por mouse/teclado pela ferramenta de controle do desktop; não contabilizar esse fluxo como teste humano.

## Pacotes e credenciais

Exports Windows e Linux concluídos sem erros. Varredura do projeto e dos arquivos descompactados dos três ZIPs não encontrou a credencial do PixelLab; o arquivo temporário usado para autenticação foi removido. O código-fonte inclui os assets locais e a licença da fonte, sem cache do Godot ou templates binários.

## Escala 0.1.1 — 12/10/2026

29 verificações de câmera aprovadas: projeção/inversão da mira, transformação de desenho, enquadramento de abertura em 100%/150%/200% e preview de menus sem zoom. As 32 verificações de simulação seguem aprovadas. Capturas de arena, objetos, habilidades e Opções conferidas em 1280 × 720 e 960 × 540, incluindo nomes longos. A medição anterior de FPS permanece referente à versão 0.1; não foi refeita neste ajuste visual. O mundo continua 2048 × 1536.

O cliente 0.1.1 exportado, carregado como main-pack pelo Godot no Mac, passou nas 29 verificações de câmera e nas 1.083 verificações de assets. Exportação Windows/Linux concluída sem erros. Execução nativa em Windows/Linux continua pendente.

Servidor 0.1.1 empacotado: partida 2–0 e revanche aprovadas nos dois clientes, com 361/363 snapshots recebidos, 100 ms RTT e 1% de perda. Rejeições de sala cheia, código inexistente e protocolo incompatível também aprovadas.
