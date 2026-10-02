# Tarefa Atual
 
## Nome
Integração de Sprites de Inimigos (`dino` e `bandit_sailor`), Novo Inimigo Exclusivo da Ilha Misteriosa e Refinamento de UI de Combate (Estilo Slay the Spire).

## Objetivo
1. **Novo Inimigo Dino Primordial (`dino`):**
   - Criado em `data/enemies/enemies.json` com `exclusive_islands: ["Ilha Misteriosa"]`.
   - HP balanceado (48 HP) e pool de intenções (Mordida Selvagem, Rugido Primitivo com debuff de fraqueza, Golpe de Cauda).
   - Sprites dedicados: `idle.png`, `attack.png` e `damaged.png` em `res://assets/art/enemies/dino/`.
   - Conexão procedural em `map_generator.gd` filtrando por ilhas exclusivas.
2. **Sprites do Saqueador do Mar (`bandit_sailor`):**
   - Configurado em `data/enemies/enemies.json` com caminhos para `res://assets/art/enemies/pirate_sailor/` (`idle.png`, `attack.png`, `damaged.png`).
3. **Refinamento de Elementos de Inimigo em Combate (Estilo Slay the Spire):**
   - Estrutura organizada no `EnemyArea`:
     - Topo: `EnemyIntentContainer` com badges emoldurados (ícones ⚔, 🛡, ✦ com valores e cores distintas).
     - Centro: Sprite do inimigo limpo e alinhado ao horizonte do capitão.
     - Base: Nome com sombra, barra de progresso de vida (`EnemyHPBar`) vermelha com texto centralizado (`HP / Max HP`), badge de bloqueio (`🛡`) e container de status (`EnemyStatusContainer`).

## Critérios de aceite
1. `bandit_sailor` exibe sprites da pasta `pirate_sailor` com animações de ataque e dano.
2. `dino` aparece em combates na Ilha Misteriosa com sprites de idle, ataque e dano.
3. UI dos inimigos organizada sem sobreposição de textos e com barra de vida estilizada.
4. Validação limpa no Godot headless.




