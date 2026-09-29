# Estado Atual do Projeto

## Fase
Pré-produção / vertical slice.

O combate básico já está funcional e o projeto começou a conectar eventos ao fluxo da run.

## Arquitetura atual

### Autoloads

#### GameState
Responsável pelo estado atual da run.

Estado conhecido:
- `player_max_hp`
- `player_hp`
- `gold`
- `food`
- `ship_integrity`
- `bounty`
- `current_deck`

Responsabilidades já implementadas:
- reset da run;
- ganho de ouro;
- ganho de bounty;
- persistência do HP da run;
- adicionar carta ao deck.

#### DataLoader
Responsável por carregar dados externos.

Dados já carregados:
- cartas;
- inimigos;
- eventos.

APIs existentes incluem:
- `get_card`
- `has_card`
- `get_enemy`
- `has_enemy`
- `get_event`
- `has_event`

## Combate

### Combatant
Classe runtime baseada em `RefCounted`.

Responsabilidades:
- `id`
- `display_name`
- `max_hp`
- `hp`
- `block`
- receber dano;
- ganhar block;
- limpar block;
- verificar derrota;
- curar.

### CardInstance
Classe runtime baseada em `RefCounted`.

Responsabilidades:
- `instance_id`
- `card_id`

### DeckManager
Classe runtime responsável por:
- draw pile;
- hand;
- discard pile;
- criação de instâncias;
- compra;
- reshuffle;
- descarte da mão;
- mover carta da mão para descarte;
- localizar carta na mão;
- contadores de pilhas.

### CombatContext
Classe runtime que agrupa o estado necessário para resolução de efeitos.

Responsabilidades atuais:
- `player`
- `enemy`
- `deck_manager`
- `energy`
- `max_energy`
- reset de energia;
- gastar energia;
- ganhar energia;
- verificar se energia pode ser gasta.

### EffectResolver
Responsável por aplicar efeitos de gameplay ao `CombatContext`.

Efeitos implementados:
- `damage`
- `block`
- `draw`
- `gain_energy`
- `heal`

Observação:
- `self` é interpretado em função da origem do efeito.
- Para `enemy_intent`, `self` aponta para o inimigo.
- Para cartas, `self` aponta para o jogador.

### CombatScene
Responsabilidades atuais:
- inicialização do combate;
- criação de player/enemy;
- criação de `DeckManager`;
- criação de `CombatContext`;
- energia via contexto;
- turnos;
- intenção inimiga;
- uso do `EffectResolver`;
- UI;
- drag/drop de cartas;
- vitória/derrota;
- recompensas;
- persistência do HP da run.

## Cartas
Dados: `res://data/cards/cards.json`

Cartas conhecidas:
- `strike_basic`
- `defend_basic`
- `quick_thinking`
- `second_wind`
- `field_medicine`

Efeitos usados:
- dano;
- block;
- draw;
- energia;
- cura.

O deck inicial deve permanecer simples. Cartas de teste avançadas podem ser obtidas via eventos em vez de fazerem parte permanentemente do deck inicial.

## Inimigos
Dados: `res://data/enemies/enemies.json`

Inimigos conhecidos:
- `marine_recruit`
- `bandit_sailor`

O sistema suporta pool de intenções com peso.

Recompensas conhecidas:
- ouro;
- bounty.

Combate comum não deve conceder carta automaticamente.

## UI de cartas
Existe `res://scenes/combat/CardView.tscn`.

Estrutura esperada:

```text
CardView [PanelContainer]
└── VBoxContainer
    ├── NameLabel
    ├── CostLabel
    └── DescriptionLabel
```

Padrão da mão:

```text
HandArea [HBoxContainer]
└── CardSlot [Control]
    └── CardView
```

Dimensões atuais recomendadas:
- `CardView`: aproximadamente `120 x 180`
- `CardSlot`: aproximadamente `130 x 190`

O `CardSlot` evita conflito entre animação da carta e layout gerenciado pelo `HBoxContainer`.

Interação:
- hover move `CardView` localmente no slot;
- drag usa posição global enquanto arrasta;
- ataque exige alvo inimigo;
- defesa/skill de jogador exige alvo jogador;
- feedback de alvo válido é atualizado durante o drag;
- validação usa sobreposição/área de destino com tolerância.

## Navegação e Fluxo da Run

### RunScene
Existe `res://scenes/run/RunScene.tscn`.

Script:
`res://scripts/run/run_scene.gd`

Responsabilidades:
- controlar a tela ativa via `ScreenContainer`;
- instanciar e gerenciar `current_screen`;
- limpar a tela anterior com segurança (`clear_current_screen`);
- iniciar a run (`start_run`) com `GameState.reset_run()`;
- exibir eventos (`show_event`);
- exibir combates (`show_combat`);
- escutar o sinal `continue_requested` de `EventScene` para transicionar para o combate.

## Eventos
Existe `res://scenes/events/EventScene.tscn`.

Script:
`res://scenes/events/event_scene.gd`

Dados:
`res://data/events/events.json`

Evento inicial conhecido:
- `old_port_trainer`

A cena:
- carrega evento via `DataLoader`;
- fornece método `setup(event_id)` para configuração desacoplada;
- mostra título e corpo;
- cria escolhas dinamicamente;
- aplica efeitos simples;
- pode adicionar carta ao deck;
- pode conceder recursos;
- emite sinal `continue_requested` ao clicar em Continuar (totalmente desacoplada de `CombatScene`).

Efeitos de evento atualmente são resolvidos localmente na `EventScene`.

Não extrair `EventEffectResolver` até existir necessidade real em mais de um ou dois eventos adicionais.

## Fluxo atual
Fluxo atual implementado:

```text
Main
→ RunScene (start_run -> GameState.reset_run())
→ EventScene ("old_port_trainer")
→ escolha
→ Continue (continue_requested)
→ RunScene substitui tela
→ CombatScene ("marine_recruit")
```

## Dívida técnica conhecida
1. `CombatScene` ainda gerencia vitória/derrota localmente com botões de teste ("Novo Combate" / "Reiniciar Run") em vez de emitir sinais para a `RunScene`.
2. Rebuild da mão deve ser observado em mudanças futuras para evitar problemas de `queue_free()` durante sinais.
3. O sistema de status ainda não existe.
4. UI visual ainda é de protótipo.
5. Eventos ainda resolvem efeitos localmente.
6. Não há mapa náutico ainda.
7. Não há sistema de cidade ainda.
8. Não há save da run ainda.
9. Não há tripulação runtime ainda.

## Próximo marco
Conectar a saída do combate (`CombatScene`) à `RunScene`:
- `CombatScene` deve emitir sinais de vitória/derrota em vez de tratar reinício e próximo combate internamente.
- `RunScene` coordena o pós-combate e decide o próximo passo da run.

## Regra de escopo
Não iniciar mapa, cidade, tripulação, frutas ou metaprogressão antes de estabilizar a transição completa de combate -> run.
