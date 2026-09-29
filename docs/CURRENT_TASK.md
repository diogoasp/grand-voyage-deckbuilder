# Tarefa Atual

## Nome
Criar `RunScene` como controlador do fluxo da run.

## Objetivo
Remover a responsabilidade de `EventScene` instanciar diretamente `CombatScene`.

Criar uma cena controladora que:
- seja carregada pelo `Main`;
- mantenha um container para a tela ativa;
- instancie `EventScene`;
- receba um pedido de continuação do evento;
- substitua o evento por `CombatScene`;
- preserve `GameState`.

## Escopo
Implementar apenas:

```text
Main
→ RunScene
→ EventScene
→ CombatScene
```

Não implementar:
- mapa;
- cidade;
- save;
- `EventEffectResolver`;
- status;
- tripulação;
- frutas;
- sistema genérico de roteamento.

## Arquivos prováveis

Criar:
- `res://scenes/run/RunScene.tscn`
- `res://scripts/run/run_scene.gd`

Alterar:
- `res://scripts/core/main.gd`
- `res://scripts/events/event_scene.gd`

Possivelmente:
- `res://scenes/events/EventScene.tscn`

## Contrato recomendado

### EventScene
`EventScene` não deve conhecer `CombatScene`.

Adicionar:

```gdscript
signal continue_requested
```

Ao clicar em continuar:

```gdscript
func _on_continue_pressed() -> void:
    continue_requested.emit()
```

Não instanciar nenhuma cena dentro de `_on_continue_pressed()`.

### RunScene
Responsável por carregar e trocar telas.

Estrutura sugerida:

```text
RunScene [Control]
└── ScreenContainer [Control]
```

API mínima sugerida:

```gdscript
func show_event(event_id: String) -> void
func show_combat(enemy_id: String) -> void
func clear_current_screen() -> void
```

Não criar router genérico nesta tarefa.

### Inicialização
Ao entrar na run:
- resetar a run apenas no ponto apropriado;
- mostrar `old_port_trainer`.

Após `continue_requested`:
- limpar a tela atual;
- mostrar combate.

Use um inimigo existente como combate inicial.

## Cuidados

### Remoção de tela
Evitar manter simultaneamente duas telas ativas.

Manter referência:

```gdscript
var current_screen: Node = null
```

e substituir de forma controlada.

### API da EventScene
Se `EventScene` já possui `current_event_id`, é aceitável adicionar:

```gdscript
func setup(event_id: String) -> void
```

Mas `setup()` não deve acessar `@onready` antes da entrada na SceneTree.

Uma abordagem segura:
- `setup()` apenas armazena o ID;
- `_ready()` chama `load_event(current_event_id)`.

## Critérios de aceite
1. `Main` não instancia mais `EventScene` diretamente.
2. `Main` instancia `RunScene`.
3. `RunScene` mostra o evento inicial.
4. Escolher uma opção continua aplicando seu efeito.
5. `ContinueButton` dispara um signal.
6. `EventScene` não referencia `CombatScene`.
7. `RunScene` recebe o signal e abre `CombatScene`.
8. `GameState` mantém a alteração feita pelo evento.
9. A carta obtida no evento aparece no deck usado pelo combate.
10. Não há erros de parser/script causados pela alteração.
11. Não implementar sistemas fora do escopo.

## Validação manual

```text
Evento aparece
→ escolher recompensa de carta
→ Continue
→ combate aparece
→ deck contém a carta obtida
```

Também testar:

```text
Evento
→ escolher ouro
→ Continue
→ combate
→ ouro permanece no GameState
```

## Entrega do agente
Ao finalizar, informar:
- arquivos criados;
- arquivos alterados;
- fluxo implementado;
- validações executadas;
- resultado de `git diff --stat`;
- pontos que exigem teste visual.

Não fazer commit.
