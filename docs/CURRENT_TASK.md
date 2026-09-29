# Tarefa Atual

## Nome
Conectar saída do combate à RunScene via sinais.

## Objetivo
Desacoplar a saída do combate em `CombatScene`:
- substituir a lógica interna de reiniciar run e próximo combate por emissão de sinais (`combat_victory`, `combat_defeat`);
- fazer a `RunScene` escutar os sinais de resultado do combate;
- permitir que a `RunScene` coordene a progressão ou encerramento da run.

## Escopo
Implementar:
- sinais em `CombatScene` (`combat_victory`, `combat_defeat`);
- botões de encerramento do combate emitem os sinais apropriados;
- `RunScene` conecta os sinais ao instanciar o combate;
- vitória avança para o próximo encontro ou tela de resumo; derrota reseta a run e retorna ao início.

Não implementar:
- mapa completo;
- sistema complexo de recompensas pós-combate (draft de cartas avançado);
- save/load persistente em disco.

## Critérios de aceite
1. `CombatScene` não reinicia a run nem altera a cena diretamente ao terminar o combate.
2. `CombatScene` emite sinais claros para o controlador pai (`RunScene`).
3. `RunScene` recebe os eventos e transiciona a tela adequadamente.
4. `GameState` mantém o estado atualizado (HP restante do capitão, ouro, etc.).
5. Nenhum erro de parser ou aviso no depurador do Godot.
