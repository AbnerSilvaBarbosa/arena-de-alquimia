# Assets PixelLab — primeiro conjunto do MVP

O jogo reproduz exports locais do PixelLab. Nenhuma chave, conta, conexão com
a API ou geração em tempo real é necessária para jogar ou hospedar o servidor.

## Personagens

Edward e Alphonse têm uma base de 64 × 64 pixels, transparência e âncora nos
pés. Alphonse recebe escala 1,08 no jogo. Animações com rotação ou queda têm
canvas maior para não cortar a silhueta.

Frames verticais dos templates têm âncora individual calculada pela base
visível dos pés, para corrigir deslocamentos dentro do canvas. Isso muda a
composição no Godot, não os pixels exportados pelo PixelLab.

| Estado | Frames por direção | Direções | Origem |
| --- | --- | --- | --- |
| Idle | 4 | 8 | Rotações V3 + respiração no workbench |
| Caminhar | 4 | 4 | Template de caminhada |
| Ataque | 6 | 4 | Template de soco |
| Conjurar Q/E | 6 | 4 | Template de preparação/conjuração |
| Arremessar | 7 | 4 | Template de arremesso |
| Defesa | 4, com poses repetidas | 4 | Pose de combate + ajuste no workbench |
| Agarrão | 4 | 4 | Pose de alcance + avanço/recuo no workbench |
| Pegar caixa | 4 | 4 | Pose de arremesso + abaixar/erguer no workbench |
| Carregar | 4, pose mantida | 4 | Pose de arremesso no workbench |
| Caminhar carregando | 4 | 4 | Pose de transporte + articulação de pernas no workbench |
| Esquiva / investida | 4 | 4 | Inclinação e deslocamento no workbench |
| Receber dano | 4 | 4 | Reação curta no workbench |
| KO | 4 | 4 | Queda com rotação no workbench |

O personagem se move em oito direções e mira livremente. Ações diagonais usam
a orientação cardinal mais próxima; Edward não é espelhado para trocar o
automail de lado. Q/E compartilham a pose corporal e têm efeitos próprios.
Investida reutiliza o corpo da esquiva. As derivações são uma primeira versão,
não animações totalmente redesenhadas para cada habilidade.

O loader adapta a sequência inteira ao tempo da ação, por exemplo os seis
frames do golpe dentro de 0,28 s. Idle, caminhada, defesa e transporte fazem
loop. O KO segura o último frame. A simulação permanece a 60 Hz; a quantidade
de desenhos do sprite é independente da taxa de renderização.

IDs de origem:

- Edward: `f89aa2d4-646a-4313-935e-41801f432a7d`.
- Alphonse: `e1ae5b6a-632c-4dd1-a9f9-341fb822f684`.

`metadata.json` guarda a exportação original; `crafted.json` registra os
spritesheets e suas âncoras. Receitas dos estados estão em `crafted/*/recipe.json`.
O elmo do Alphonse foi corrigido no próprio PixelLab para retirar pele/cabelo
inventados. Um marcador laranja destacado no template de conjuração foi
retirado pelo workbench; a receita fica junto dos exports do personagem.

## Habilidades e feedback

Sete efeitos animados em `effects/`: alquimia, impacto em área, arco do golpe,
poeira/rastro da esquiva, espinhos de pedra, impacto recebido e defesa. Cada
pacote contém spritesheets, partes separadas e manifesto de frames, offsets,
profundidade e âncora. O chão/círculo fica atrás do personagem; faíscas e
detritos ficam à frente. Avisos de alcance e área continuam desenhados pelo
Godot para corresponder à simulação e manter a leitura de acertos.

Os efeitos também foram salvos em “My effects” na conta PixelLab usada.

## UI e cenário

`ui/atlas.png`: moldura de painel, botões normal/hover, emblema alquímico e
seis ícones de ação. Molduras usam nine-slice no Godot. Retratos estão em PNGs
separados. Textos, campos, botões e barras continuam sendo controles nativos.

`environment/`: piso de pedra repetível, caixa de madeira e atlas de blocos
para cobertura e paredes transmutadas. O mapa, as sombras e o círculo gravado
do pátio são compostos pelo Godot a partir desses assets e geometria 2D.

## Ferramentas e reprodução

- `tools/pixellab_mcp.py`: cliente MCP HTTP; lê `PIXELLAB_AUTH_HEADER` do ambiente.
- `tools/download_pixellab_character.py`: importa ZIP de personagem já gerado.
- `tools/import_crafted.py`: importa spritesheets do workbench.
- `tools/import_pixellab.py`: reconstrói `manifest.json`.
- `tools/craft_pixel_states.py`, `craft_pose_states.py`: preparam receitas de animação.
- `tools/prepare_cast_cleanup.py`: identifica o marcador destacado sem alterar pixels localmente.
- `tests/assets_test.gd`: verifica estados, direções, recursos, grades, âncoras e reprodução completa das ações.

Essas ferramentas fazem parte do código-fonte; não entram no executável do
jogo. Gerações novas dependem do saldo da conta. Refinamentos existentes foram
feitos pelo workbench do PixelLab; os PNGs não foram redesenhados por scripts
locais.

As ferramentas de análise/importação de imagens usam Python com Pillow;
`python3 -m pip install Pillow` quando necessário. O jogo não depende de Python.
