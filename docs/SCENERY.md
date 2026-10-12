# Cenários locais — 0.3.0-dev

## Jogar

Abra o projeto no Godot e entre em **Treino**. Escolha **Jardins de Amestris** ou **Bosque das Ruínas**, depois Edward ou Alphonse. O cenário escolhido permanece nos rounds do treino. No modo online, rounds ímpares usam jardim e pares usam bosque.

As duas composições ocupam 2048×1536 e compartilham a mesma geometria de combate: 20 troncos, dois cercados, dois lagos com ilhas decorativas inacessíveis, dois guardas nas entradas e quatro ruínas já existentes. A arte muda entre os cenários, sem alterar vantagem de spawn. As copas são ordenadas pela profundidade e ficam semitransparentes quando escondem um lutador. Guardas e quimeras são habitantes animados do cenário, sem participação no combate; não são novos personagens selecionáveis.

O chão combina o piso PixelLab existente com o atlas Woods. Há flores, cogumelos, pedras, tufos de grama, trilhas, sombras, folhas levadas pelo vento e pequenos reflexos na água. Detalhes menores são decorativos; troncos, cercados e lagos são obstáculos reais. A variação visual é determinística; o movimento das folhas não muda colisões.

## Instalar os packs no checkout

No Mac atual, os quatro PNGs já estão em `assets/third_party/`. Para outro checkout, obtenha os packs dos autores e execute:

```sh
python3 tools/import_scenery.py --games-dir "/caminho/para/pasta/Games"
```

O importador copia somente os quatro PNGs originais, confere dimensões e não altera pixels. Abra o projeto no Godot para importar as texturas. Os nomes das pastas esperados são os que constam em `tools/import_scenery.py`.

Os packs estão ignorados pelo Git e excluídos do pacote de código-fonte. Sem eles, o jogo continua carregando com piso e obstáculos PixelLab como fallback, mas não exibe a arte dos novos cenários. `tests/scenery_test.gd` exige os packs locais para validar a integração completa.

## Créditos e distribuição

- [Woods v2 — zedpxl](https://zedpxl.itch.io/pixelart-forest-asset-pack): ambiente. Sua licença contém restrição ampla a usos relacionados a IA; a autorização para uma release deste projeto híbrido continua pendente de esclarecimento com o autor.
- [HD Knight — SmallScaleInt](https://smallscaleint.itch.io/hd-8-directional-top-down-character-pack-1): animação Idle dos guardas/observadores.
- [Tiny RPG Pack 02 — Zerie](https://zerie.itch.io/tiny-rpg-character-asset-pack-02): Demon_A e Blood Monster_A, animações Idle das quimeras nos cercados.

Não houve upload dos arquivos a ferramentas de geração de IA, modificação dos PNGs ou publicação de uma release contendo os packs. As capturas ficam em `.local/`, para revisão neste Mac. Histórico da avaliação em `docs/ASSET_PACK_REVIEW.md`.

## Rede

Protocolo 3, pois novos obstáculos precisam existir igualmente em cliente e servidor. Não conectar esta versão ao servidor 0.2.0/protocolo 2. A VPS não foi atualizada.
