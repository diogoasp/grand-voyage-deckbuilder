# Tarefa Atual

## Nome
Geografia Canônica do South Blue (Ato 1), Seleção Temática de Chefes & Transição para Grand Line (Ato 2).

## Objetivo
Implementar a estrutura canônica de Atos/Fases do mundo de One Piece:
- Geração da rota do **South Blue (Ato 1)** partindo da ilhota desconhecida:
  - Setor 1: Karate Island, Sorbet Kingdom ou Ilha Misteriosa (sempre Evento);
  - Setor 2: Centaurea Kingdom, Judo Island ou Torino Kingdom;
  - Setor 3: Ilha Misteriosa (sempre Evento) ou Baterilla Island;
  - Setor 4: Briss Kingdom (Grande Porto Seguro antes da Grande Travessia);
  - Setor 5: Batalha de Chefe do South Blue (Capitão Morgan ou Comodoro Pudding-Pudding).
- **Restrição de Akuma no Mi:** Frutas são extremamente raras e **não aparecem nos Blues** (`allowed_acts: [2]`); disponíveis apenas na Grand Line.
- **Sorteio e Balanceamento de Chefes:** Suporte ao atributo `allowed_acts` em `enemies.json` para sortear chefes condizentes com a fase da narrativa.
- **Transição Multi-Atos:** Ao derrotar o chefe de Briss Kingdom / South Blue, o jogador pode zarpar rumo à Grand Line (Ato 2: Reverse Mountain / Whiskey Peak), preservando HP, ouro, deck e tripulação.

## Critérios de aceite
1. Mapa do South Blue gera exatamente as ilhas e tipos especificados em cada setor.
2. Ilhas Misteriosas contêm exclusivamente nós do tipo `event`.
3. Eventos de Akuma no Mi não aparecem no South Blue (Ato 1).
4. Chefes são filtrados por `allowed_acts`, sorteando Morgan ou Pudding-Pudding no South Blue.
5. Vencer o chefe do South Blue permite zarpar para a Grand Line (Ato 2) mantendo o estado da expedição.
6. Validação do Godot headless sem erros de parser/script.




