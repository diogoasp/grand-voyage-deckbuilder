# Tarefa Atual

## Nome
Implementar estrutura básica de Mapa Náutico na RunScene.

## Objetivo
Criar uma representação simples de mapa náutico (carta de navegação) com escolha de rota entre nós:
- nós representam os tipos de encontros já existentes (`combate`, `evento`, `cidade`);
- o jogador escolhe o próximo destino a partir da rota ativa;
- a `RunScene` coordena a transição do mapa para o nó selecionado e retorna ao mapa ao término do nó.

## Escopo
Implementar:
- `MapScene` com nós visíveis e selecionáveis em colunas/níveis simples;
- tipos de nós: Combate, Evento e Porto (Cidade);
- `RunScene` transiciona entre `MapScene` e a cena correspondente do nó;
- ao concluir o nó, a `RunScene` reabre o mapa com o nó marcado como visitado e os nós alcançáveis habilitados.

Não implementar:
- geração procedural complexa ou regras complexas de vento/correntes marítimas;
- perda de comida por travessia sem navegador (ainda);
- salvar estado do mapa em disco.

## Critérios de aceite
1. O jogador consegue escolher o próximo nó navegável em uma rota.
2. Clicar no nó abre o encontro correto (`EventScene`, `CombatScene` ou `CityScene`).
3. Concluir o encontro retorna ao mapa para a próxima escolha.
4. GameState preserva recursos durante todo o fluxo do mapa.
5. Sem erros ou avisos no depurador do Godot.
