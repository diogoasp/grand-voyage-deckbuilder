# Tarefa Atual

## Nome
Implementar o primeiro Tripulante funcional (Médico) como Relíquia Viva.

## Objetivo
Materializar o conceito central de tripulante definido no documento de direção:
- tripulantes não são apenas bônus passivos nem apenas cartas: são entidades que atuam entre encontros e trazem sinergias;
- implementar o Médico da Tripulação:
  - passiva de viagem: cura uma quantidade moderada de HP ao término de cada nó do mapa;
  - custo de manutenção: consome comida ao viajar;
  - carta associada: garante a carta `field_medicine` no deck enquanto estiver na tripulação;
- gerenciar a tripulação ativa no `GameState`.

## Escopo
Implementar:
- modelo de dados de tripulante em `GameState` (`crew_members`);
- oportunidade de recrutamento via evento ou cidade;
- aplicação da passiva do médico ao concluir nós navegados no mapa;
- exibição da tripulação ativa na interface do mapa náutico.

Não implementar:
- sistema complexo de lealdade/traição ou demissão complexa;
- múltiplos tripulantes simultâneos antes de validar o primeiro.

## Critérios de aceite
1. O jogador consegue recrutar o médico durante a jornada.
2. A passiva do médico cura o capitão entre setores do mapa náutico.
3. A carta de medicina fica vinculada à presença do médico.
4. O consumo de comida reflete o custo logístico da tripulação.
5. Sem erros ou warnings no depurador do Godot.
