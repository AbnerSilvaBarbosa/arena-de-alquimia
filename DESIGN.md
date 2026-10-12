---
name: Arena de Alquimia
description: Interface desktop provisória de um duelo de alquimia em pátio militar.
colors:
  parchment-text: "#f0e4ce"
  muted-text: "#c0b79f"
  alchemy-cyan: "#6ee6e1"
  button-disabled: "#25292b"
  disabled-border: "#4d514f"
  disabled-text: "#77796e"
  field-background: "#171f24"
  field-border: "#82775f"
  error-text: "#f0a48b"
  bar-background: "#30373a"
  health-red: "#c65353"
  warning-amber: "#e9b56d"
typography:
  display:
    fontFamily: "Silkscreen Regular"
    fontSize: "32px"
  title:
    fontFamily: "Silkscreen Regular"
    fontSize: "24px"
  body:
    fontFamily: "Godot ThemeDB fallback font"
    fontSize: "18px"
  label:
    fontFamily: "Godot ThemeDB fallback font"
    fontSize: "14px"
  caption:
    fontFamily: "Godot ThemeDB fallback font"
    fontSize: "12px"
rounded:
  square: "0px"
spacing:
  compact: "4px"
  default: "10px"
  action-gap: "12px"
  field-gap: "16px"
components:
  button:
    textColor: "{colors.parchment-text}"
    typography: "{typography.body}"
    rounded: "{rounded.square}"
    padding: "10px 18px"
    height: "44px"
    textColor: "{colors.alchemy-cyan}"
    textColor: "{colors.parchment-text}"
  button-disabled:
    backgroundColor: "{colors.button-disabled}"
    textColor: "{colors.disabled-text}"
  field:
    backgroundColor: "{colors.field-background}"
    textColor: "{colors.parchment-text}"
    rounded: "{rounded.square}"
    height: "40px"
  panel:
    textColor: "{colors.parchment-text}"
    rounded: "{rounded.square}"
    padding: "22px 24px"
---

# Design System: Arena de Alquimia

## Overview

**Creative North Star: "Pátio militar de alquimia"**

Pátio militar de pedra, interface azul-marinho com cobre, texto creme e alquimia ciano. O casaco vermelho de Edward e a armadura fria de Alphonse distinguem os combatentes. A arena e a leitura dos ataques têm prioridade.

A implementação nativa usa exports locais do PixelLab para personagens, efeitos, UI e cenário. Este é o primeiro conjunto do MVP: poses compartilhadas e derivações continuam sujeitas a refinamento; áudio sintetizado permanece provisório. O rodapé ainda identifica arte e áudio provisórios. Windows é a plataforma principal, macOS a de desenvolvimento; esta documentação não confirma teste nativo no Windows.

A direção deriva dos conceitos e da referência aceitos. Não houve sorteio de concept seed nem rodada formal de comps, conforme PRODUCT.md. A disposição recente de ship se limita aos três itens revisados — nomes no mundo, fonte e proveniência — e não constitui aprovação completa de animação ou plataforma.

**Key Characteristics:**
- Molduras pixeladas opacas, azul-marinho e cobre.
- Títulos Silkscreen e leitura com fonte nativa do Godot.
- Retratos, ícones e emblema integrados aos controles nativos.
- Alquimia ciano e avisos de alcance ligados à simulação.

Fonte de verdade: `scripts/main.gd`, `pixel_ui.gd`, `arena.gd`, `pixel_assets.gd`, `pixel_fx.gd`, `pixel_environment.gd`, `project.godot`, `assets/pixellab/README.md` e capturas atuais em `.impeccable/review/`. Capturas estáticas documentam composição, não qualidade temporal de animação.

## Colors

Os tokens no frontmatter descrevem cores de controles e texto definidas no código. O atlas PixelLab é normativo para preenchimento e moldura dos painéis e botões; não substituir seus pixels por antigas cores planas de fallback.

### Primary
- **Ciano de alquimia:** subtítulo, hover de texto, foco, cursor, prontidão, stamina, placar, jogador local e efeitos.

### Secondary
- **Cobre:** molduras pixeladas e detalhes do emblema; campos mantêm borda plana própria.
- **Vermelho de vida:** HP. Casaco vermelho pertence ao personagem, sem virar variante de botão.
- **Âmbar de aviso:** marcador RIVAL e antecipação de impacto.
- **Pêssego de erro:** validação e falhas na conexão.

### Neutral
- **Creme:** títulos, ações e instruções; tom atenuado para ajuda e estado Escolhendo.
- **Azul-marinho:** superfícies opacas do atlas; campos mais escuros e barras com fundo próprio.
- **Pedra e aço:** ambiente e armadura do Alphonse, com texturas de origem PixelLab.

**The Legibility Rule.** Instruções inferiores e nomes no mundo precisam de fundos escuros próprios; não colocar texto claro diretamente sobre as variações do chão.

## Typography

**Display / Title Font:** Silkscreen Regular local, em `assets/fonts/Silkscreen-Regular.ttf`, com SIL Open Font License 1.1 em `assets/fonts/OFL.txt`.

**Body Font:** fallback nativo do Godot, também usado nos nomes no mundo. Não há fonte web ou dependência de download durante o jogo.

### Hierarchy
- **Display:** menu em duas linhas, 32 pixels lógicos; emblema de 64 ao lado.
- **Title:** todos os labels solicitados com tamanho ≥28 são remapeados para Silkscreen 24 (conexão, treino, sala, opções, overlay, banner).
- **Body:** padrão e botões 18; explicação do treino/erro no overlay 17.
- **Labels:** nomes do lobby 21, estado 15, nomes do HUD/ajuda 16, campos/habilidades 14.
- **Caption:** rodapé, instruções, nomes no mundo e personagem/rounds no HUD 12; RIVAL 10.
- **Score / timer:** placar 24 e relógio/ROUND 22, ambos com fonte nativa.

Silkscreen usa peso Regular; não há overrides de entrelinha. Títulos de overlay e banners permitem quebra. Nomes do lobby/HUD têm reticências; no mundo o texto é reduzido com reticências até caber em 96 pixels. O fundo mede largura do texto +8 por 17. Quando dois nomes se aproximam, o rival sobe 22 pixels em relação ao nome local (limiares horizontais 108 e verticais 20).

## Layout

Canvas lógico **960 × 540**, janela mínima igual e abertura padrão **1280 × 720**, com stretch `canvas_items`. Composição fixa, sem breakpoints web ou rearranjo mobile. Arena 2048 × 1536, tiles 32, câmera seguindo o jogador; menus têm câmera de fundo em deslocamento lento. Outros formatos de janela exigem verificação própria.

Painéis têm margens laterais 24 e verticais 22; botões, laterais 18 e verticais 10. Espaçamentos variam pela tela; não existe grade universal.

| Tela | Painel: posição, tamanho lógico | Composição |
| --- | --- | --- |
| Menu | (54,62), 430 × 422 | Emblema + título, ações empilhadas, Opções/Sair em dupla; rodapé (54,514). |
| Conexão | (130,36), 700 × 468 | Apelido/código, endereço/porta, criar/entrar em pares; estado e navegação abaixo. |
| Treino | (230,102), 500 × 336 | Resumo, escolhas em dupla, Voltar. |
| Lobby | (120,20), 720 × 500 | Código copiável, duas colunas com retratos, personagem e Ready. |
| Opções | (230,28), 500 × 484 | Quatro sliders (áudio e escala da arena), Tela cheia e Voltar. |
| Overlay | (260,126), 440 × 288 | Título, informação e ações empilhadas. |

HUD: painéis 262 × 76 em (18,14) e (680,14), retratos de 42; relógio 230 × 76 em (365,14). Instruções 620 × 28 em (175,434); habilidades **748 × 56 em (90,470)** com ícones; Menu em (866,488). Banner 760 × 110 em (100,150).

## Elevation & Depth

Molduras e bordas do atlas conferem relevo pixelado, sem sombras de cartões. Painéis PixelLab são opacos: o parâmetro alpha do helper só afeta o fallback plano quando o atlas está ausente. Véus escurecem a arena: menu 0,42, conexão/treino/opções 0,65, lobby 0,60; overlay 0,75. Banner tem sombra de texto escura com deslocamento (2,2).

Sombras do mundo continuam compostas por Godot. Efeitos PixelLab se dividem em partes atrás e à frente dos personagens; círculos, alcance e avisos de impacto continuam geométricos para corresponder à simulação.

## Shapes

Atlas UI local **256 × 128**. Painel recorta (0,0,64,64) com nine-slice de 12; botão normal recorta (68,0,92,32), destacado (68,32,92,32), com nine-slice de 8. Canto reto e contorno pixelado; preenchimento opaco. Emblema recorta (184,0,64,64), seis ícones usam células de 32 em y=96. Retratos são PNGs separados. Filtragem nearest preserva pixels e atlas usa filter_clip.

## Components

### Buttons

Controles nativos com StyleBoxTexture nine-slice. Normal usa região normal; hover e pressed compartilham região destacada. Texto hover ciano, restante claro. Foco continua StyleBoxFlat transparente com borda ciano de 2; disabled continua fallback plano atenuado. Altura mínima usual 44, com Menu compacto como exceção. Não há transição de estado animada definida. Som de clique sintetizado.

### Inputs / Fields

LineEdit plano, fundo escuro, borda cobre de 1; foco e cursor ciano. Margens esquerda 12 e topo/base 10; mínimo 40. Rótulos acima. Limites: apelido 20, código 6, endereço 128 e porta 5. Estado da conexão permite quebra; erro pêssego. Tentativas simultâneas são bloqueadas logicamente, sem visual dedicado de loading.

### Containers and portraits

Painéis usam moldura opaca PixelLab com margens adaptadas no HUD. Retratos têm preservação de proporção e não interceptam mouse; lobby usa tamanho padrão 56, HUD 42. Personagem e rounds ficam em linha própria abaixo do nome no HUD. Não existem chips ou abas.

### Lobby and readiness

Nome truncado, retrato, personagem e estado por membro. PRONTO ciano; Escolhendo atenuado. Vaga usa “Aguardando seu amigo…”. Ready alterna Cancelar Ready. Escolha não tem variante visual persistente própria; estado textual informa o personagem. Código e Copiar código na primeira linha.

### Combat HUD and overlays

HP vermelho de altura 10, stamina ciano de altura 4, sem porcentagens. Q/E usam ícones e nomes por personagem, cooldown em segundos com modulação atenuada; F alterna Caixa/Jogar. Relógio MM:SS e ROUND; loading, contagem e intervalo usam banner. Nome local ciano e rival creme; mira/círculo local e RIVAL complementam orientação.

Menu afirma que o duelo continua; não pausa a simulação. Resultado mostra placar local × rival dedicado em ciano. Revanche alterna para aguardando confirmação; Voltar ao lobby no online, Sair em ambos. Falha em jogo/lobby mostra Conexão interrompida, explicação e retorno.

### Options

HSlider padrão do Godot para geral/música/efeitos, 0–1 com passo 0,05 e mínimo de altura 26. CheckButton nativo para Tela cheia. Não inventar tokens customizados de slider/toggle.

### PixelLab characters, effects and environment

Exports locais, sem API, chave ou geração em tempo real para jogar/hospedar. Dois personagens com base 64 × 64 e âncora nos pés; Alphonse escala 1,08. Frames verticais têm âncoras individuais registradas no manifesto; rotação/queda podem usar canvas maior.

Treze estados visuais: idle, caminhada, ataque, conjuração, arremesso, defesa, agarrão, pegar, carregar, caminhar carregando, esquiva/investida, dano e KO. Idle em oito direções; ações em quatro com orientação cardinal mais próxima. Mira livre e movimento em oito direções não significam oito direções desenhadas por ação. Edward não é espelhado para trocar o automail. Q/E compartilham pose; investida reutiliza esquiva; defesa/transporte incluem poses repetidas. Loops e duração adaptada à ação vêm do loader; KO segura o último frame. Isso descreve reprodução implementada, sem declarar qualidade temporal final validada.

Sete VFX: alquimia, impacto em área, arco do golpe, rastro da esquiva, espinhos, hit e defesa. Manifests definem frames/offsets/profundidade. Piso repetível, caixa e stone-atlas para parede/coluna substituem os desenhos procedurais principais; composição do mapa, sombras e círculo gravado continuam Godot. Fallbacks procedurais existem para recursos ausentes. Proveniência e receitas estão em `assets/pixellab/README.md`, metadata/crafted/manifest e receitas adjacentes.

## Do's and Don'ts

### Do:
- **Do** usar os exports locais e nine-slice existentes como fonte visual.
- **Do** manter Silkscreen 32 no menu, 24 nos títulos e fonte nativa na leitura.
- **Do** verificar 960 × 540, nomes largos com reticências e separação dos nomes próximos.
- **Do** preservar avisos de alcance, placar explícito e a identificação provisória.

### Don't:
- **Don't** apresentar áudio sintetizado ou animações derivadas como acabamento final.
- **Don't** afirmar oito direções únicas para ações, geração ao vivo ou teste nativo Windows sem evidência.
- **Don't** inventar aprovação de concept seed/comps ou ampliar a disposição de ship dos três itens revisados.
- **Don't** substituir molduras opacas por cartões translúcidos, UI web ou decoração que encubra combate.

## Escala da arena — 12/10/2026

Zoom padrão 1,5×, ajustável de 1× a 2× em passos de 0,25. O Node2D da arena aplica escala e origem no centro do viewport; HUD e menus ficam na CanvasLayer sem zoom. A câmera busca um ponto entre o jogador e o rival próximo; a mira converte coordenadas usando o inverso da escala. O preview de fundo dos menus mantém 1×. A janela e o viewport continuam 1280 × 720 e 960 × 540. Sprites atuais 64 × 64; arte futura local 128 × 128 planejada em docs/ART_LOCAL.md.
