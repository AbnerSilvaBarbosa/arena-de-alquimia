# Primeiro lote local — Pixelorama 1.2.3

## Entregas

- `characters/edward_idle_128_study.pxo`: pose estática de Edward, 128 × 128, oito camadas de pixels editáveis. Casaco/trança, calças/botas, torso/gola, automail, braço/luva, rosto, cabelo e expressão. É um estudo de silhueta e paleta, ainda sem sequência de animação ou outras direções.
- `environment/amestris_tiles_64_study.pxo`: atlas 256 × 256, quatro colunas/quatro linhas de peças 64 × 64, cinco camadas editáveis.
- `../../assets/local/`: PNGs exportados e 16 peças individuais. Este caminho é relativo à raiz `art/source`; os assets reais ficam em `assets/local` na raiz do projeto.
- `art/local_preview.tscn`, na raiz do projeto: cena editável de estudo com TileMapLayer de chão e arquitetura, Sprite2D estático e TileSet. Não tem colisões, controlador, rede ou combate. A montagem usa células de 64 unidades para verificar a arte a 1:1; o mapa de combate atual permanece no sistema de coordenadas anterior.
- `docs/media/local-art-study.png`: captura da prévia no Godot.

As artes foram desenhadas por comandos de pixels definidos em `tools/draw_local_art.gd`, executados com a API do pacote instalado do Pixelorama. `ExtensionsApi` cria os projetos/camadas; `OpenSave` salva os `.pxo`; `DrawingAlgos` compõe os exports. Os pixels não foram gerados com IA nem ampliados de um sprite anterior. O traço é um primeiro estudo para revisão, não arte final aprovada.

O runtime Godot carrega `Pixelorama.pck` para executar essa automação. A CLI padrão do app também foi usada para reabrir/exportar os arquivos. A janela normal do Pixelorama abriu ambos os projetos, e dimensões/desenhos foram conferidos nela. Editar os `.pxo` diretamente no editor é o fluxo principal daqui em diante.

## Atlas

| Índice | Peça |
| --- | --- |
| 00 | Chão de pedra |
| 01 | Chão rachado |
| 02 | Chão com musgo |
| 03 | Variação do chão |
| 04 | Parede frontal |
| 05 | Parede com canto/pilar |
| 06 | Base de coluna |
| 07 | Escadas |
| 08 | Grade |
| 09 | Dreno |
| 10 | Piso quebrado |
| 11 | Terra |
| 12 | Caixa |
| 13 | Barril |
| 14 | Bandeira |
| 15 | Entulho |

## Continuar editando

Abrir os `.pxo` em **Arquivo → Abrir**. Alternar projetos com **Ctrl + Tab**, centralizar o canvas com **Shift + B**. Os nomes das camadas descrevem cada parte. Exportar PNG ao terminar; salvar `.pxo` preserva as camadas.

Para redesenhar o conjunto, manter uma cópia ou nova versão do projeto. O gerador não recria as fontes existentes por padrão. `ARENA_ART_REBUILD=1` permite recriar o estudo original, substituindo os arquivos; não usar essa opção sobre um projeto que já recebeu edição manual.

## Reproduzir o estudo em outra pasta

Com Godot 4.7.2 e o pacote de Pixelorama 1.2.3 instalado:

```sh
ARENA_ART_ROOT=/tmp/meu-estudo godot --headless --main-pack /caminho/Pixelorama.app/Contents/Resources/Pixelorama.pck --script /caminho/do/jogo/tools/draw_local_art.gd
```

O host de automação em `.gd.txt` é compilado apenas dentro do Pixelorama; o editor do jogo não tenta importá-lo como script próprio. A execução headless dessa versão do editor emite diagnósticos de shader/recursos ao encerrar. A validação considera os arquivos salvos, a reabertura na GUI e a igualdade de pixels após exportação; não tratar os logs do editor como ausência total de erros.

Para refazer a prévia no jogo: `godot --path . --script tools/preview_local_art.gd`. Ou abrir `art/local_preview.tscn` no Godot e executar a cena.

O MVP jogável conserva os sprites e animações existentes enquanto este estudo é revisado. Próxima etapa artística: definir proporções/paleta e desenhar a caminhada nas quatro direções; depois integrar o novo conjunto de animações sem misturar poses incompatíveis.
