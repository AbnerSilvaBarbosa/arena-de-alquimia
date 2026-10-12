# Combate com alquimia — versão 0.2.0

## Edward

- Q ativa a prévia da parede no cursor. Clique esquerdo confirma; botão direito, Q novamente ou Esc cancelam. Verde indica espaço disponível; vermelho indica obstáculo, jogador, limite de três paredes ou alcance excedido.
- Alcance de 240 unidades, grade de 16. A orientação acompanha a direção da mira: parede perpendicular à mira. O servidor valida posição, colisões, limite e resistência.
- A parede emerge do chão em 0,45 segundo, tem 80 de vida, bloqueia movimento e ataques e não expira. Continua até ser destruída ou reiniciar o round. O bloqueio vale desde o início da animação.
- E sobre uma parede própria combina espinhos: recupera até 40 de vida, aumenta a vida máxima a 120 e causa 10 de dano ao inimigo em contato, com intervalo de 0,6 segundo. A combinação também permanece. E fora de uma parede mantém espinhos em linha com aviso antes do impacto.
- Ataques, armas e caixas arremessadas podem destruir paredes. O dono também pode quebrar sua construção.

## Alphonse

- Q: animação de transmutação; após 0,42 segundo o servidor sorteia lança, martelo ou espada, com chances iguais. Pode repetir a mesma arma. Custa 18 de resistência; recarga de cinco segundos. Uma arma nova substitui a anterior, exceto se a lança estiver no chão: nesse caso é necessário recuperá-la.
- Lança: ataque de alcance 120, dano 16. E lança a arma a 700 unidades/segundo, causando 24 de dano no impacto. Para no chão ao atingir jogador/obstáculo ou terminar a trajetória. Aproximar-se e apertar F recupera a própria lança. A lança continua no chão até ser recuperada ou reiniciar o round.
- Martelo: ataque básico com preparação de 0,32 segundo, dano 34 e recarga de 0,95 segundo. E dá impacto de 42 de dano em área, com aviso antes de acertar.
- Espada: ataque básico de dano 18, recarga de 0,33 segundo; E dá corte de dano 24. Ambos são golpes corpo a corpo.
- Sem arma, mantém socos e impacto simples. Carregar uma caixa impede atacar/forjar. O bot também procura recuperar sua lança.

## Animação e multiplayer

As poses de conjuração, ataque e arremesso são os clips PixelLab já existentes. A parede cresce visualmente; os espinhos permanentes reutilizam um frame dos efeitos PixelLab. Armas possuem camada visual própria, ainda provisória. Forja, preparação do martelo, trajetória, dano, obstáculos e coleta são simulados no servidor e enviados nos snapshots.

O protocolo passou a 2. Cliente e servidor 0.2.0 precisam ser atualizados juntos; builds anteriores são rejeitadas na entrada. Não foi feito deploy na VPS.
