# Tarefa Atual

## Nome
Implementar a primeira camada de Haki simples com postura/recurso e cartas dedicadas.

## Objetivo
Materializar o pilar de design de Haki conforme definido em `GRAND_VOYAGE_CONCEITO_E_DIRECAO.md`:
- Haki funciona como disciplina marcial acessível a qualquer capitão, sem a penalidade de fraqueza ao mar das Akuma no Mi;
- implementar uma forma de Haki: **Haki de Armamento (Busoshoku Haki)** ou **Haki de Observação (Kenbunshoku Haki)**;
- mecânica:
  - Armamento: potencializa o próximo ataque ou converte dano em penetração de armadura/anulação de resistências;
  - Observação: prevê com exatidão dano futuro ou concede esquiva/bloqueio reativo;
- treinamento através de mentor/evento ou cidade.

## Escopo
Implementar:
- dados e cartas de Haki em `res://data/cards/cards.json`;
- suporte de treino de Haki em eventos ou no porto (`CityScene` / `EventScene`);
- resolução de efeitos específicos de Haki no `EffectResolver` e `CombatContext`;
- validação com o fluxo atual.

Não implementar:
- sistema complexo de Haki do Conquistador em área;
- árvore completa com dezenas de técnicas de Haki avançado.

## Critérios de aceite
1. O capitão pode adquirir técnicas de Haki durante a run.
2. Cartas de Haki funcionam em combate sem gerar erros.
3. Diferenciação clara entre cartas físicas, de Akuma no Mi e de Haki.
4. Sem erros ou warnings no depurador do Godot.

