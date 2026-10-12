# Arte local e escala — decisão de 12/10/2026

Objetivo confirmado: personagens maiores na tela agora e arte futura em **128 × 128 pixels**, desenhada localmente. O mapa também receberá um tileset próprio. A primeira versão continua usando os PNGs já exportados; nenhum serviço é necessário para editá-los ou reproduzi-los.

## Ferramenta recomendada: Pixelorama

[Pixelorama](https://github.com/Orama-Interactive/Pixelorama) é gratuito, aberto, com licença MIT e versão desktop para macOS/Windows/Linux. Tem timeline, camadas, onion skin, paletas e recursos para pixel art. Para este projeto, a combinação de personagens animados e tilesets favorece usar um único editor local.

O [manual de tilesets](https://pixelorama.org/user_manual/tilemaps/) descreve tilemap layers, autotiling e exportação de TileSet do Godot em `.tres`. Os [projetos editáveis são `.pxo`](https://pixelorama.org/user_manual/save_and_export/); PNG/spritesheets são as entregas para o jogo. Há também [exportação por linha de comando](https://pixelorama.org/user_manual/cli/), útil para automatizar o trabalho depois que os arquivos editáveis existirem.

Download oficial: [GitHub Releases](https://github.com/Orama-Interactive/Pixelorama/releases). Selecionar a distribuição Mac da versão estável e seguir o guia oficial de instalação. Esta etapa de pesquisa não instalou o aplicativo.

### Alternativas pesquisadas

| Ferramenta | Papel neste projeto | Fonte oficial |
| --- | --- | --- |
| Pixelorama | Escolha inicial gratuita para sprites, animações e tilesets | [Recursos e plataformas](https://github.com/Orama-Interactive/Pixelorama) |
| Aseprite | Alternativa especializada, com Lua e exportação automatizada; app pronto pago, preço consultado US$ 19,99 antes de impostos/câmbio | [FAQ](https://www.aseprite.org/faq), [CLI](https://www.aseprite.org/docs/cli/), [Tilemap](https://www.aseprite.org/docs/tilemap/) |
| Krita | Gratuito; útil para estudos, pintura, retratos e animação. Minha preferência para editar tiles pixel a pixel continua sendo Pixelorama | [Recursos](https://krita.org/en/features/), [Download Mac](https://krita.org/en/download/) |

São editores de desenho, não geradores automáticos equivalentes ao PixelLab. Produzir personagens consistentes exige desenho, revisão das poses e trabalho quadro a quadro. Podemos automatizar exportação e organização; a ferramenta sozinha não acrescenta qualidade artística.

## Tamanhos e escala

| Elemento | Atual | Próxima arte local |
| --- | --- | --- |
| Frame do personagem | 64 × 64 | 128 × 128, com mais detalhe desenhado |
| Retrato | 64 × 64 | 128 × 128 |
| Tile do cenário | PNG 32 × 32 | PNG 64 × 64 para mais detalhe; manter célula de mundo 32 × 32 inicialmente |
| Escala da arena | 100% na primeira versão | 150% padrão, ajustável entre 100% e 200% |
| Viewport lógico | 960 × 540 | Mantido nesta alteração |
| Janela inicial | 1280 × 720 | Mantida; pode redimensionar ou usar tela cheia |
| Dimensão do mapa | 2048 × 1536 unidades | Mantida; expandir depois com layout e tempo de travessia definidos |

No zoom padrão, o frame atual de 64 × 64 ocupa nominalmente 96 × 96 unidades da tela lógica, ou 128 × 128 pixels na janela inicial. Isso é ampliação por nearest, sem inventar pixels de detalhe. Ao redesenhar um frame em 128 × 128, ajustar sua escala e âncora para preservar o tamanho de combate: arte mais detalhada e tamanho visual são controles independentes. Não esticar a imagem com suavização.

A câmera se aproxima e busca um enquadramento entre o jogador e o rival próximo. HUD e menus mantêm a escala. A mira aplica a transformação inversa do zoom; simulação, colisões, velocidades, alcance e servidor não mudam. Um rival distante continua tendo indicação de direção.

## Fluxo para desenhar localmente

1. Salvar os projetos de trabalho em `art/source/`, em `.pxo`, com pastas `characters/`, `environment/` e `ui/`. Manter os originais PixelLab como referência; não editar a única cópia de um export.
2. Criar um personagem em canvas 128 × 128, âncora nos pés, fundo transparente e paleta consistente com o pátio. Desenhar uma pose primeiro e comparar no jogo antes de produzir todas as direções. Edward não deve ser espelhado para trocar o automail de lado.
3. Separar camadas de guia, silhueta, cor, luz e sombra. Usar onion skin para caminhada/ataque e tags por ação. Começar com quatro direções; aumentar o conjunto depois que a leitura estiver boa.
4. Exportar PNGs ou spritesheets para `assets/local/`, registrar frame size, grid, duração, âncora e escala no manifesto consumido pelo loader. O loader aceita caminhos locais; revisar o registro quando cada conjunto substituir o original. Arquivos `.pxo` são fonte editável, não assets de runtime.
5. Criar o primeiro tileset do pátio: chão limpo, variações, rachaduras, bordas, parede, coluna, portão, bandeira, vegetação e objetos. Separar solo, decoração baixa, obstáculos e elementos altos.
6. Montar o cenário usando [TileSet e TileMapLayer no Godot](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html). O renderer atual é desenhado por código; essa montagem em TileMapLayer é uma próxima implementação, ainda não feita. Espelhar os obstáculos no servidor autoritativo para evitar diferença entre cenário e colisão.
7. Conferir a 100% no editor e no jogo: silhueta, paleta, alinhamento dos pés, repetição das bordas, animação, legibilidade dos ataques e arte em diferentes zooms. Mais pixels não substituem boa direção de arte.

Primeiro pacote de trabalho proposto: um tileset do pátio e a caminhada/idle de Edward em 128 × 128. Só depois aprovar o padrão e expandir o restante das animações e o Alphonse.
