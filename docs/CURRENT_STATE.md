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

## Eventos
Existe `res://scenes/events/EventScene.tscn`.

Script:
`res://scripts/events/event_scene.gd`

Dados:
`res://data/events/events.json`

Evento inicial conhecido:
- `old_port_trainer`

A cena:
- carrega evento via `DataLoader`;
- mostra título e corpo;
- cria escolhas dinamicamente;
- aplica efeitos simples;
- pode adicionar carta ao deck;
- pode conceder recursos;
- mostra botão de continuar depois da escolha.

Efeitos de evento atualmente são resolvidos localmente na `EventScene`.

Não extrair `EventEffectResolver` até existir necessidade real em mais de um ou dois eventos adicionais.

## Fluxo atual
Fluxo provisório esperado:

```text
Main
→ reset_run
→ EventScene
→ escolha
→ Continue
→ CombatScene
```

Atualmente a troca de cena é direta/provisória.

## Dívida técnica conhecida
1. `EventScene` instancia diretamente `CombatScene`.
2. Falta uma cena/controlador de run para trocar entre telas.
3. Rebuild da mão deve ser observado em mudanças futuras para evitar problemas de `queue_free()` durante sinais.
4. O sistema de status ainda não existe.
5. UI visual ainda é de protótipo.
6. Eventos ainda resolvem efeitos localmente.
7. Não há mapa náutico ainda.
8. Não há sistema de cidade ainda.
9. Não há save da run ainda.
10. Não há tripulação runtime ainda.

## Próximo marco
Criar uma camada de navegação da run (`RunScene` / `RunController`) para que cenas de conteúdo não conheçam diretamente umas às outras.

Objetivo:

```text
RunScene
├── recebe pedidos de transição
├── remove a tela atual
├── instancia a próxima tela
└── preserva GameState
```

Depois disso, conectar evento, combate e futuramente mapa/cidade.

## Regra de escopo
Não iniciar mapa, cidade, tripulação, frutas ou metaprogressão antes de estabilizar o controlador básico de fluxo da run.
