# Tarefa Atual

## Nome
Implementar a primeira Akuma no Mi simples com micro-mecânica e cartas de poder.

## Objetivo
Materializar o pilar de design de Akuma no Mi conforme definido em `GRAND_VOYAGE_CONCEITO_E_DIRECAO.md`:
- frutas funcionam como fonte de identidade de build;
- implementar uma fruta original/simples: **Fruta da Névoa (Kiri Kiri no Mi / Fog-Fog Fruit - Logia/Paramecia Utilitária)**;
- mecânica:
  - concede estado passivo/carta de poder que gera camuflagem/esquiva ou bloqueio etéreo;
  - cartas de poder associadas da fruta adicionadas ao deck ao consumir;
  - vulnerabilidade temática da fruta: fraqueza ao mar/água (ou penalidade de integridade/dano em tempestade/naufrágio);
- oportunidade de descoberta/consumo através de evento ou nó de tesouro.

## Escopo
Implementar:
- dados da fruta em `res://data/fruits/fruits.json` e carregamento em `DataLoader`;
- cartas da fruta em `res://data/cards/cards.json`;
- registro da fruta ativa no `GameState` (`eaten_fruit`);
- efeito de consumir fruta em evento/encontro;
- exibição do poder ativo na UI do capitão.

Não implementar:
- árvore gigantesca de dezenas de frutas;
- sistema complexo de despertar (awakening);
- múltiplas frutas por personagem.

## Critérios de aceite
1. O jogador pode encontrar e comer a fruta durante a run.
2. `GameState` registra a fruta comida e adiciona suas cartas de poder ao deck.
3. Cartas da fruta funcionam no combate através do `EffectResolver`.
4. Sem erros ou warnings no depurador do Godot.
