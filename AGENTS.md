# AGENTS.md

## Projeto
Grand Voyage Deckbuilder é um jogo 2D em Godot 4.x, desenvolvido em GDScript, com estrutura roguelite deckbuilder náutica.

O projeto está em fase de vertical slice. A prioridade é entregar um loop jogável pequeno e estável antes de expandir conteúdo.

## Objetivo do agente
Atuar principalmente como executor técnico local.

O agente deve:
- ler o estado atual antes de alterar código;
- seguir a arquitetura existente;
- implementar tarefas pequenas e delimitadas;
- preservar comportamento existente salvo quando a tarefa exigir mudança;
- validar o projeto após alterações;
- apresentar resumo do que mudou e o diff relevante;
- não tomar decisões arquiteturais amplas sem instrução explícita.

## Regras arquiteturais
- Engine: Godot 4.x.
- Linguagem principal: GDScript.
- Preferir arquitetura data-driven.
- Cartas, inimigos, eventos, tripulantes e conteúdos equivalentes devem ficar em arquivos externos sempre que possível.
- Não criar subclasses por carta ou por inimigo.
- Separar lógica de jogo, dados e apresentação.
- Evitar acoplamento de lógica à UI.
- `CombatScene` coordena input, apresentação e fluxo do combate.
- `CombatContext` representa o estado lógico runtime do combate.
- `EffectResolver` aplica efeitos de gameplay sobre o contexto.
- `DeckManager` controla draw pile, hand, discard pile e operações relacionadas.
- `Combatant` representa entidades que possuem HP, block e operações relacionadas.
- `CardInstance` representa uma instância runtime de uma carta definida em dados.
- `DataLoader` carrega conteúdo data-driven.
- `GameState` guarda o estado atual da run.

## Regras de game design
- Não adicionar escopo desnecessário.
- O vertical slice vem antes da versão completa.
- Combates não devem conceder carta como recompensa comum.
- Cartas devem vir principalmente de eventos, treinamentos, tripulação, frutas e Haki.
- Tripulantes funcionam como relíquias vivas, com efeitos externos e possíveis cartas associadas.
- Progressão entre runs deve desbloquear conteúdo.
- Narrativa deve ser curta e funcional.
- Evitar dependência excessiva de nomes e habilidades canônicas em materiais públicos.

## Regras de implementação
Antes de editar:
1. Leia `docs/CURRENT_STATE.md`.
2. Leia `docs/CURRENT_TASK.md`.
3. Inspecione apenas os arquivos necessários para a tarefa.
4. Use a implementação existente como padrão.

Durante a edição:
- faça a menor alteração suficiente;
- evite refactors fora do escopo;
- não renomeie APIs públicas sem necessidade;
- não duplique lógica existente;
- preserve tipagem GDScript quando já utilizada;
- use `push_warning()` / `push_error()` para falhas de dados quando adequado;
- não esconda erros com soluções temporárias silenciosas.

Após editar:
1. Rode validações disponíveis.
2. Se Godot CLI estiver disponível, use modo headless para detectar erros de parser/script.
3. Verifique `git diff`.
4. Corrija erros diretamente relacionados à tarefa.
5. Não faça commit automaticamente.

## Git
- Nunca execute `git commit`, `git push`, `git reset --hard`, `git clean -fd` ou comandos destrutivos sem solicitação explícita.
- `git status` e `git diff` são permitidos e recomendados.
- Não altere arquivos fora do escopo apenas para "limpar" o projeto.

## Godot e cenas
- Cenas `.tscn` podem ser editadas em texto quando a alteração for simples e segura.
- Para UI complexa ou layout visual, prefira alterações pequenas e solicite validação visual manual.
- Nunca mova manualmente um `Control` gerenciado diretamente por um `Container` durante hover/drag.
- Para cartas da mão, preserve o padrão `HBoxContainer -> CardSlot(Control) -> CardView`.
- `CardView.setup()` só deve ser chamado depois que a instância estiver dentro da SceneTree, pois os `@onready` precisam estar inicializados.

## Dados
- Cartas: `res://data/cards/cards.json`
- Inimigos: `res://data/enemies/enemies.json`
- Eventos: `res://data/events/events.json`

Ao adicionar conteúdo:
- manter IDs estáveis;
- validar referências entre JSONs;
- não hardcodar nomes de cartas/inimigos em lógica quando IDs/dados forem suficientes.

## Critério de conclusão
Uma tarefa está concluída quando:
- o comportamento pedido foi implementado;
- não há erro conhecido de parser/script causado pela alteração;
- os dados envolvidos continuam válidos;
- o diff está restrito ao escopo;
- o agente informa arquivos alterados, comportamento implementado, validações executadas e riscos/pontos de teste manual.
