# Tarefa Atual

## Nome
Sistema de Recompensa de Cartas (Draft pós-combate estilo roguelite).

## Objetivo
Permitir que o jogador construa e especialize seu deck de combate após vencer batalhas marítimas:
- ao vencer um combate, apresentar 3 opções de cartas retiradas da pool permitida de recompensas;
- permitir que o jogador escolha uma para adicionar ao deck (`GameState.add_card_to_deck`) ou opte por pular ("Pular Recompensa de Carta") para não inflar o deck;
- transicionar de volta para o mapa após a escolha ou salto.

## Escopo
Implementar:
- novas cartas de recompensa náutica em `data/cards/cards.json` (`cutlass_slash`, `brace_impact`, `sailors_gambit`);
- método `DataLoader.get_all_card_ids()` para consulta da pool de cartas;
- interface de escolha de recompensas dinâmicas em `CombatScene.tscn` e `combat_scene.gd`;
- suporte a pular a recompensa sem adicionar cartas.

## Critérios de aceite
1. Vitória em combate exibe o painel de recompensas com ouro, bounty e a escolha de cartas.
2. Clicar em uma carta a adiciona imediatamente ao deck e libera o botão de avançar.
3. Clicar em "Pular Recompensa" ignora a aquisição e avança para a próxima etapa.
4. Sem erros ou warnings no parser/depurador do Godot.




