# Tarefa Atual
 
## Nome
Integração das Artes do Protagonista (Masculino e Feminino), Seleção no Menu e Apresentação em Batalha com Shader de Remoção de Fundo Branco.

## Objetivo
1. **Seleção de Gênero/Capitão (`CharacterSelectScene`):**
   - Inclusão dos botões de gênero ("♂ Masculino" e "♀ Feminino") na barra superior da tela de preparação.
   - Exibição dinâmica da arte base (`res://assets/art/main_char/{gender}/base.png`) na coluna de resumo do capitão.
   - Encaminhamento do gênero selecionado através do sinal `expedition_started`.
2. **Propagação e Persistência do Capitão (`GameState`, `main.gd`, `run_scene.gd`):**
   - Propriedade `player_gender` (padrão `"male"`) integrada a `GameState.reset_run`, `setup_custom_run`, `save_run_state` e `load_run_state`.
   - Propagação correta a partir de `main.gd` e `run_scene.gd` ao iniciar ou carregar runs.
3. **Apresentação em Combate (`CombatScene`):**
   - Substituição do placeholder geométrico (`ColorRect`) por `TextureRect` (`PlayerSprite`).
   - Carregamento da ilustração de combate (`res://assets/art/main_char/{gender}/combat.png`) de acordo com o capitão selecionado.
   - Aplicação de `flip_h = true` para que o capitão fique voltado para a direita em direção aos inimigos.
   - Criação e aplicação do shader `res://shaders/remove_white_bg.gdshader` para remoção suave do fundo branco sólido das ilustrações.
   - Aplicação do mesmo shader e espelhamento no slide-in de assistências de tripulantes (`trigger_crew_assist_visual`).

## Critérios de aceite
1. Seleção entre Masculino e Feminino na tela de preparação de expedição, atualizando a prévia da arte (`base.png`).
2. Persistência de `player_gender` no salvamento e carregamento da run.
3. Capitão renderizado com sua respectiva arte de combate (`combat.png`) em batalha, espelhado para a direita (`flip_h = true`) e com fundo branco removido via shader.
4. Assistências de tripulantes renderizadas sem artefatos de fundo branco.
5. Validação com Godot headless limpa e sem erros.




