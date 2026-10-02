# Tarefa Atual
 
## Nome
Integração das Sprites do Marinheiro Padrão (`marine_recruit`) e Cenários de Fundo em Combate (`briss.png`, `harbor_island.png`, `misterious_island.png`).

## Objetivo
1. **Sprites do Marinheiro Padrão (`marine_recruit`):**
   - Configurado em `data/enemies/enemies.json`:
     - `idle_sprite_path`: `res://assets/art/enemies/marine/idle.png`
     - `attack_sprite_path`: `res://assets/art/enemies/marine/attack.png`
     - `damaged_sprite_path`: `res://assets/art/enemies/marine/damaged.png`
   - Suporte adicionado em `CombatScene` e `combat_scene.gd`:
     - Renderização no `EnemyTextureRect` com shader de transparência.
     - Animação de investida com troca para `attack.png` durante ataques.
     - Troca momentânea para `damaged.png` ao sofrer dano (além do flash vermelho e número flutuante).
2. **Cenários Dinâmicos de Combate (`assets/scenarios/`):**
   - Removidos os nós antigos de fundo do Morgan da cena `CombatScene.tscn`.
   - Adicionado nó `ScenarioBackground` (`TextureRect`) com stretch mode adequado (Keep Aspect Covered).
   - Implementado em `combat_scene.gd` (`setup_combat_background`) e `run_scene.gd`:
     - `briss.png` para o chefe Harrison / Reino de Briss.
     - `harbor_island.png` para ilhas portuárias (Karate, Sorbet, Centaurea, Baterilla) e patrulha de marinheiros.
     - `misterious_island.png` para Ilha Misteriosa e encontros neutros.

## Critérios de aceite
1. Marinheiro padrão exibe `idle.png`, ataca com `attack.png` e reage a dano com `damaged.png`.
2. Cenário de combate se adapta dinamicamente ao contexto do inimigo e ilha atual.
3. Cenas e scripts sem erros de parser/validação no Godot.




