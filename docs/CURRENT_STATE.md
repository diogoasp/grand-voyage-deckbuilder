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

## Cidades e Portos

### CityScene
Existe `res://scenes/city/CityScene.tscn`.

Script:
`res://scripts/city/city_scene.gd`

Responsabilidades:
- materializar a parada portuária (equivalente náutico à fogueira de Slay the Spire);
- aplicar a regra de **uma única ação principal** por visita;
- ações implementadas:
  - Descansar na Taverna (+20 HP);
  - Treinar Técnicas (-15 Ouro, +1 Golpe Básico ao deck);
  - Comprar Provisões (-10 Ouro, +3 Comida);
- botão de Zarpar (`depart_requested`) para continuar a viagem náutica;
- feedback visual em tempo real do estado dos recursos (`HP`, `Ouro`, `Comida`).

## Mapa Náutico

### MapScene
Existe `res://scenes/map/MapScene.tscn`.

Script:
`res://scripts/map/map_scene.gd`

Responsabilidades:
- materializar a carta marítima com setores/estágios em colunas;
- nós com tipos distintos: `combate`, `evento` e `porto` (cidade);
- indicar nós visitados e habilitar apenas os nós alcançáveis do estágio atual da rota;
- permitir que o jogador escolha o rumo (bifurcação de rotas);
- emitir o sinal `node_selected(node_data)`.

## Tripulação (Relíquias Vivas)

Dados:
`res://data/crew/crew.json`

Tripulante inicial implementado:
- `doctor_lin` (Médico):
  - Passiva de viagem: cura o capitão em +6 HP a cada transição de setor no mapa náutico;
  - Custo de manutenção: consome 1 de Comida por setor viajado;
  - Cartas associadas: adiciona a carta `field_medicine` ao deck no recrutamento.

Suporte arquitetural:
- `DataLoader` carrega e fornece dados da tripulação (`get_crew`, `has_crew`);
- `GameState` rastreia `crew_members` ativos e fornece método `recruit_crew()`;
- `RunScene` aplica passivas de exploração e custos logísticos ao término de cada nó (`apply_crew_travel_effects()`);
- `MapScene` exibe em tempo real os membros da tripulação embarcados.

## Akuma no Mi (Frutas do Diabo)

Dados:
`res://data/fruits/fruits.json`

Primeira fruta implementada:
- `kiri_kiri_no_mi` (Kiri Kiri no Mi / Fruta da Névoa):
  - Tipo: Paramecia/Logia utilitária;
  - Passiva de combate: Corpo de Névoa (+4 de Bloqueio etéreo inicial ao abrir qualquer combate);
  - Cartas de poder adicionadas ao deck ao consumir:
    - `mist_form` (Forma de Névoa): 1 Energia, 8 de Bloqueio;
    - `dense_fog` (Névoa Espessa): 1 Energia, 4 de Bloqueio + 1 Compra de carta;
  - Risco/Penalidade temática: consome slot único de fruta do capitão (`eaten_fruit` no `GameState`).

Suporte arquitetural:
- `DataLoader` carrega e fornece dados de frutas (`get_fruit`, `has_fruit`);
- `GameState` rastreia `eaten_fruit`, método `consume_fruit(fruit_id)` que injeta cartas ao deck e impede comer uma segunda fruta;
- `EventScene` suporta efeito `"consume_fruit"` (evento `mysterious_chest`);
- `CombatScene` aplica automaticamente a passiva etérea da fruta no início da batalha;
- `MapScene` exibe em tempo real a fruta consumida no painel de status do capitão.

## Fluxo atual
Fluxo atual implementado:

```text
Main
→ RunScene (start_run -> GameState.reset_run())
→ MapScene (Carta Náutica do Setor)
  ├── Setor 1: Escolha Inicial no Cais:
  │     ├── [A] Velho Lutador (Postura defensiva / Recursos)
  │     └── [B] Médico do Cais (Recrutar Dr. Lin: +1 Medicina de Campo, cura por setor)
  │     └── Conclusão -> Aplica passivas de viagem -> Retorna ao Mapa
  ├── Setor 2: Escolha de Rota de Mar:
  │     ├── [A] Patrulha Costeira ("marine_recruit")
  │     ├── [B] Pirataria Rival ("bandit_sailor")
  │     └── [C] Baú Naufragado ("mysterious_chest" -> Comer Fruta da Névoa OU Vender por 50 Ouro)
  │     └── Vitória/Conclusão -> Aplica passivas de viagem -> Retorna ao Mapa
  ├── Setor 3: Porto Seguro (CityScene: 1 ação) -> Zarpar -> Retorna ao Mapa
  └── Setor 4: Águas Profundas ("bandit_sailor") -> Vitória -> Rota concluída
(Em caso de derrota no combate -> RunScene reinicia o ciclo via start_run())
```

## Dívida técnica conhecida
1. Rebuild da mão deve ser observado em mudanças futuras para evitar problemas de `queue_free()` durante sinais.
2. O sistema de status/buffs temporários em combate ainda não foi generalizado (passiva aplicada diretamente no init).
3. UI visual ainda é de protótipo.
4. Eventos e cidades ainda resolvem efeitos localmente.
5. Não há save da run em disco ainda.

## Próximo marco
Implementar a primeira camada de Haki simples (Haki de Observação / Kenbunshoku Haki ou Armamento / Busoshoku Haki) como mecânica distinta e complementar às Akuma no Mi.

## Regra de escopo
Não iniciar metaprogressão persistente nem múltiplas classes antes de validar Haki e sua coexistência com Akuma no Mi.

