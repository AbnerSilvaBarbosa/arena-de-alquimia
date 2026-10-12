# Mídia do README

Capturas atuais: `gameplay.png`, `menu.png`, `lobby.png` e `objects.png`, produzidas pelo renderer do Godot a partir do MVP 0.1.

`combat.mp4` / `combat.gif`: 13 segundos de demonstração automatizada, com três situações preparadas na simulação real. Sem jogadores humanos, sem conexão à VPS. O roteiro usa movimento, habilidades, golpes, defesa, agarrão e objetos. Os cortes reiniciam a situação e não representam uma partida contínua.

`assets.mp4` / `assets.gif`: galeria dos exports locais do PixelLab. As ações são desaceleradas para inspeção. As poses de transporte mostram o corpo do personagem; a caixa é desenhada separadamente no jogo. `pixel-art.png` é um frame dessa galeria. Nenhum sprite foi redesenhado para esta documentação.

Os vídeos foram gravados a 30 FPS, 1280 × 720. Os GIFs têm 768 × 432 e 12 FPS para reduzir o tamanho do README. Essas taxas são da mídia, não uma medição de desempenho do jogo. O vídeo de combate inclui o áudio sintetizado provisório.

`concept-courtyard.png` e `concept-worlds.png` são cópias sem alterações das imagens geradas na conversa em 10/10/2026. Origem e prompts completos em `concepts.json`. São referências de direção futura; cenário detalhado, personagens adicionais, lança e crossover não estão implementados no MVP.

## Reproduzir os vídeos

Com Godot 4.7.2 e FFmpeg instalados, a partir da raiz do projeto:

```sh
godot --path . --fixed-fps 30 --disable-vsync --write-movie /tmp/combat.avi --script tools/capture_media.gd
godot --path . --fixed-fps 30 --disable-vsync --write-movie /tmp/assets.avi --script tools/capture_media.gd -- --assets
ffmpeg -i /tmp/combat.avi -c:v libx264 -crf 21 -pix_fmt yuv420p -movflags +faststart -c:a aac docs/media/combat.mp4
ffmpeg -i /tmp/assets.avi -c:v libx264 -crf 21 -pix_fmt yuv420p -movflags +faststart -c:a aac docs/media/assets.mp4
```

PNG, GIF e MP4 da documentação ficam fora dos executáveis do jogo. O pacote de código-fonte inclui esta galeria, e o pacote Windows inclui as mídias referenciadas pelo README.
