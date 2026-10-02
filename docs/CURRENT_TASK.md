# Tarefa Atual
 
## Nome
Adição do Chefe de Briss: Harrison, Líder dos Rebeldes (Tritão Barracuda) e Suporte a Sprites de Ataque/Idle em Combate.

## Objetivo
1. **Dados de Inimigo (`res://data/enemies/enemies.json`):**
   - Criação da entrada `boss_harrison` baseada nas especificações e design do personagem:
     - Nome: "Harrison, Líder dos Rebeldes de Briss"
     - Raça: Tritão Barracuda (ex-pirata, ex-escravo, líder rebelde).
     - HP: 80.
     - Sprites dedicados: `idle_sprite_path` e `attack_sprite_path`.
     - Ciclo de Intenções:
       - *Corte de Barracuda*: 10 de dano ao jogador;
       - *Vontade Inquebrantável*: 12 de bloqueio próprio + 5 de dano ao jogador;
       - *Lâmina da Libertação*: 16 de dano ao jogador.
2. **Apresentação em Combate (`CombatScene` e `combat_scene.gd`):**
   - Adição do nó `EnemyTextureRect` no `EnemyArea` com suporte ao shader de remoção de fundo e dimensionamento adequado.
   - Carregamento dinâmico em `load_enemy()`: se o inimigo tiver `idle_sprite_path`, usa o `enemy_texture_rect` e oculta o `AnimatedSprite2D` de placeholder.
   - Alternância de sprite durante a ação de ataque:
     - Em `resolve_enemy_turn()`, quando o inimigo executa intenção com dano, troca momentaneamente para `attack_sprite_path`, executa animação de investida/lunge frontal em direção ao capitão via Tween, e retorna para a posição original com `idle_sprite_path`.
   - Ajuste das animações de feedback de dano, bloqueio e cura (`flash_target`) para iluminar o elemento visual ativo (`enemy_texture_rect` ou `enemy_sprite`).
3. **Integração no Mapa Náutico (`MapGenerator`):**
   - Elegibilidade de Harrison na pool de chefes do Ato 1 (`allowed_acts: [1]`) através de `get_sector_boss(1)`.

## Critérios de aceite
1. Harrison configurado em `data/enemies/enemies.json` com estatísticas, lore e intenções balanceadas para o Ato 1.
2. Harrison renderizado em combate com `idle.png` como sprite padrão.
3. Transição para `attack.png` e animação de investida executada durante turnos de ataque do chefe.
4. Feedback de dano, flash e bloqueio aplicado adequadamente ao sprite ativo.
5. Validação com Godot headless limpa e sem erros.




