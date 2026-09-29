# Tarefa Atual

## Nome
Implementar a batalha de Chefe do Setor (Capitão da Marinha Morgan) para conclusão da rota marítima.

## Objetivo
Fechar o ciclo do Vertical Slice com uma batalha final de setor desafiadora:
- Chefe: Capitão Morgan (Braço de Machado / Patrulha da Base da Marinha);
- mecânica:
  - vida substancialmente maior que os inimigos comuns;
  - ciclo de intenções com ataque pesado, bloqueio fortificado e golpe cortante;
  - arena temática com os assets de fundo já presentes no projeto (`res://assets/art/Boss 1 Morgan_bg.png`);
- conectar o nó final do mapa náutico (Setor 4) para invocar o chefe em vez de um lacaio comum;
- tela de vitória do setor ao derrotá-lo.

## Escopo
Implementar:
- dados do chefe `marine_captain_morgan` em `res://data/enemies/enemies.json`;
- vinculação no nó do Estágio 3/4 do mapa náutico (`scripts/map/map_scene.gd`);
- tratamento de vitória da run/setor no `RunScene`.

Não implementar:
- múltiplos atos ou segundo mapa (Grand Line) antes de validar o chefe do primeiro setor.

## Critérios de aceite
1. O estágio final do mapa leva ao combate contra o Chefe Morgan.
2. O chefe executa suas intenções no combate.
3. Derrotar o chefe conclui com êxito o setor da run.
4. Sem erros ou warnings no depurador do Godot.


