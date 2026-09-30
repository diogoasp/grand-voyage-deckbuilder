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

Efeitos implementados e suportados pelo sistema de cartas e intenções:

1. **`damage` (Dano):**
   - Propriedades: `value: int`, `target: "enemy" | "player"`, `ignore_block: bool (opcional, padrão false)`.
   - Comportamento: Deduz da armadura/bloqueio antes da vida, a menos que `ignore_block: true` (Haki de Armamento/perfurante). Se o alvo estiver com `intangible > 0`, o dano final recebido é fixado em no máximo 1.

2. **`block` (Bloqueio):**
   - Propriedades: `value: int`, `target: "player" | "self"`.
   - Comportamento: Adiciona armadura temporária ao combatente, protegendo o HP até o início do seu próximo turno.

3. **`draw` (Compra de Cartas):**
   - Propriedades: `value: int`, `target: "player"`.
   - Comportamento: Compra `value` cartas do draw pile para a mão do jogador (com reshuffle automático do descarte se necessário).

4. **`gain_energy` (Ganho de Energia):**
   - Propriedades: `value: int`, `target: "player"`.
   - Comportamento: Adiciona energia imediata para jogar mais cartas no turno corrente.

5. **`heal` (Cura):**
   - Propriedades: `value: int`, `target: "player"`.
   - Comportamento: Recupera o HP do combatente até o limite do seu `max_hp`.

6. **`intangible` (Intangibilidade / Logia / Forma de Névoa):**
   - Propriedades: `value: int (turnos)`, `target: "player"`.
   - Comportamento: Concede o status de intangibilidade por `value` turno(s). Durante o efeito, qualquer dano final recebido não pode ultrapassar 1.

Observação sobre alvos:
- `"enemy"`: aponta para o inimigo ativo.
- `"player"`: aponta para o capitão/jogador.
- `"self"`: dinâmico conforme a origem: para `enemy_intent`, aponta para o inimigo; para cartas, aponta para o jogador.


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

#### Padrão Visual de Status e Intenções em Combate:
1. **Vida e Bloqueio (Player e Inimigo):**
   - Localizados diretamente sobre ou adjacentes a cada combatente (`PlayerArea` e `EnemyArea`).
   - HP representado por texto conciso (`HP: X/Y`).
   - Bloqueio exibido dinamicamente em badge azul celeste (`🛡 X`) ao lado do HP apenas quando `block > 0`.
   - A TopBar superior é reservada exclusivamente para recursos globais da batalha/run: Energia (`⚡`), Ouro, Bounty e contagem de cartas (Deck e Descarte).
2. **Padrão de Ícones de Intenção do Inimigo:**
   - **Ataque:** Ícone de espada (`⚔`) com o valor numérico de dano ao lado, ambos com fonte vermelha (`Color(1.0, 0.25, 0.25)`). Hover exibe tooltip: `"Intenção: Atacar causando X de dano."`.
   - **Defesa/Bloqueio:** Ícone de escudo (`🛡`) com o valor numérico de armadura ao lado, ambos com fonte azul (`Color(0.3, 0.7, 1.0)`). Hover exibe tooltip: `"Intenção: Defender ganhando X de bloqueio."`.
   - **Efeitos Utilitários / Buffs futuros:** Ícone estelar (`✦`) com valor numérico em tom âmbar/amarelo (`Color(0.9, 0.8, 0.4)`), exibindo tooltip explicativa da intenção ao sobrepor.


## Cartas
Dados: `res://data/cards/cards.json`

Cartas conhecidas:
- `strike_basic`
- `defend_basic`
- `quick_thinking`
- `second_wind`
- `field_medicine`
- `mist_form`
- `dense_fog`
- `buso_strike`
- `kenbun_focus`
- `cutlass_slash` (Corte de Alfanje: 9 de dano)
- `brace_impact` (Aparar Impacto: 8 de bloqueio)
- `sailors_gambit` (Artimanha do Marujo: 4 de dano + 1 compra)

Efeitos usados:
- dano;
- block;
- draw;
- energia;
- cura;
- intangível;
- perfurante (ignore_block).

O deck inicial permanece simples (Golpes e Defesas Básicas). Após vitórias em combate, o jogador tem a opção de fazer um Draft escolhendo 1 entre 3 cartas aleatórias ou pular a recompensa para manter o deck enxuto.


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
- menu de opções/configurações acessível pelo botão de engrenagem (`⚙`) no topo direito da tela, com suporte a reiniciar a run;
- exibir eventos (`show_event`);
- exibir combates (`show_combat`);
- escutar o sinal `continue_requested` de `EventScene` para transicionar para o combate.

## Eventos
Existe `res://scenes/events/EventScene.tscn`.

Script:
`res://scenes/events/event_scene.gd`

Dados:
`res://data/events/events.json`

Eventos conhecidos e agrupamento por fase (`allowed_stages`):
- `old_port_trainer` (Fase 0 - Cais): Treino de Defesa Básica, Haki de Armamento ou Ouro.
- `wandering_doctor` (Fase 0 - Cais): Recrutamento do Dr. Lin (+1 Medicina de Campo) ou Cura rápida.
- `mysterious_chest` (Fase 1 - Mar Aberto): Consumir Akuma no Mi (Kiri Kiri no Mi) ou Vender por 50 Ouro.
- `stranded_merchant` (Fases 1 e 2 - Águas de Travessia): Doar mantimentos por ouro, resgatar cartógrafo (+1 Pensamento Rápido) ou orientar (+Bounty).
- `siren_shallows` (Fases 1 e 2 - Baixios Perigosos): Risco de dano por ouro em destroços ou ritmo firme (+1 Segundo Fôlego).

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
- nós com tipos distintos: `combate`, `evento`, `porto` (cidade) e `boss` (chefe de setor);
- limitação e ramificação de rotas (estilo *Slay the Spire*): cada ilha conecta proceduralmente a 1 ou 2 ilhas subsequentes via `next_nodes`, impedindo acesso irrestrito a todos os nós do estágio seguinte;
- rastrear o último nó selecionado (`last_selected_node_id`) com persistência de run;
- renderizar linhas visuais de navegação via overlay (`MapLinesOverlay`):
  - linhas ativas/acessíveis desenhadas em tom dourado náutico (`Color(0.9, 0.75, 0.25, 0.85)`);
  - linhas inativas ou futuras desenhadas em azul-ardósia sutil/translúcido (`Color(0.35, 0.45, 0.6, 0.4)`);
- indicar nós visitados/derrotados e desabilitar nós fora da rota alcançável;
- permitir que o jogador traceje estrategicamente seu rumo;
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

## Haki (Força de Vontade Marcial)

Dados:
`res://data/cards/cards.json`

Cartas de Haki implementadas:
- `buso_strike` (Golpe com Armamento / Busoshoku Strike):
  - Tipo: Ataque marcial infundido de Haki;
  - Custo: 1 Energia;
  - Efeito: 8 de dano perfurante que ignora totalmente o bloqueio do inimigo (`ignore_block: true`);
  - Obtenção: evento do Velho Lutador do Porto (`old_port_trainer`).
- `kenbun_focus` (Foco de Observação / Kenbunshoku Focus):
  - Tipo: Habilidade sensorial de antecipação;
  - Custo: 1 Energia;
  - Efeito: Ganha 6 de Bloqueio e compra 1 carta do deck;
  - Obtenção: treino especial no porto seguro (`CityScene`).

Suporte arquitetural:
- `Combatant.take_damage(amount, ignore_block)` agora aceita bypass de armadura para ataques com Armamento;
- `EffectResolver` reconhece o parâmetro `ignore_block` e resolve o dano perfurante informando o feedback no combate;
- `CityScene` e `EventScene` integradas para permitir treinamento deliberado de Haki.

## Fluxo atual
Fluxo atual implementado:

```text
Main
→ RunScene (start_run -> GameState.reset_run())
## Chefe de Setor (Confronto Final do Ato)

Dados:
`res://data/enemies/enemies.json`

Chefe implementado:
- `marine_captain_morgan` (Capitão Morgan 'Mão de Machado'):
  - HP: 65;
  - Recompensas: 50-75 Ouro, 30 Bounty;
  - Ciclo de Intenções:
    - *Golpe de Machado*: 9 de dano;
    - *Postura do Tirano*: 10 de bloqueio próprio + 4 de dano ao jogador;
    - *Execução Impiedosa*: 15 de dano massivo;
  - Conexão: ativado no nó final do setor através do tipo `"boss"`, com destaque visual no mapa (borda avermelhada e ícone de caveira).

## Geração Procedural da Carta Náutica (MapGenerator)

Script:
`res://scripts/map/map_generator.gd`

Responsabilidades:
- desacoplar a criação do mapa do script de cena;
- criar rotas procedurais e balanceadas para cada nova run (estilo *Slay the Spire*);
- consultar o `DataLoader` dinamicamente para sortear nós de acordo com o agrupamento por fase (`allowed_stages`):
  - **Estágio 0:** Eventos de cais elegíveis para fase 0 (`old_port_trainer`, `wandering_doctor`);
  - **Estágio 1:** Combates procedurais variados com pool dinâmico de inimigos comuns + eventos marítimos sorteados da pool da fase 1 (`mysterious_chest`, `stranded_merchant`, `siren_shallows`);
  - **Estágio 2:** Parada portuária (cidade com ações estratégicas de descanso/treino);
  - **Estágio 3:** Batalha de Chefe do Setor consultando dinamicamente a pool de chefes;
- persistir a rota na `RunScene` durante a travessia e gerar novo mapa ao iniciar nova expedição.


## Fluxo atual
Fluxo atual implementado:

```text
Main
→ RunScene (start_run -> GameState.reset_run() -> MapGenerator.generate_sector_map())
→ MapScene (Carta Náutica Procedural do Setor)
  ├── Setor 1: Escolha Inicial no Cais:
  │     ├── [A] Velho Lutador (Postura defensiva OU Despertar Haki de Armamento: Golpe perfurante)
  │     └── [B] Médico do Cais (Recrutar Dr. Lin: +1 Medicina de Campo, cura por setor)
  │     └── Conclusão -> Aplica passivas de viagem -> Retorna ao Mapa
  ├── Setor 2: Rota Procedural de Mar Aberto:
  │     ├── [A] Patrulha Costeira ("marine_recruit")
  │     ├── [B] Pirataria Rival ("bandit_sailor")
  │     └── [C] Baú Naufragado ("mysterious_chest" -> Comer Fruta da Névoa OU Vender por 50 Ouro)
  │     └── Vitória/Conclusão -> Aplica passivas de viagem -> Retorna ao Mapa
  ├── Setor 3: Porto Seguro (CityScene: Taverna, Treino Básico, Treino de Haki de Observação ou Provisões) -> Zarpar
  └── Setor 4: Batalha de Chefe (💀 [CHEFE] Capitão Morgan: 65 HP, Golpe 9, Postura Tirano 10/4, Execução 15)
        ├── Vitória -> Rota concluída -> Botão "Iniciar Nova Expedição" (regenera run e mapa)
        └── Derrota -> Reinicia a run
```

## Sistema de Persistência e Salvamento (Save/Load da Run)

Implementado em `GameState` e orquestrado por `RunScene`:
- **Serialização da Run:** Salva e restaura com fidelidade o estado completo:
  - Atributos do Capitão: `player_max_hp`, `player_hp`, `gold`, `food`, `ship_integrity`, `bounty`.
  - Construção do Deck: lista completa de IDs das cartas acumuladas no `current_deck`.
  - Tripulação ativa (`crew_members`) e Fruta do Diabo consumida (`eaten_fruit`).
  - Progresso Náutico: estágio atual do mapa (`current_stage`), nós concluídos (`completed_nodes`) e a matriz procedural do setor (`sector_map`).
- **Comportamento Automático:**
  - Auto-save automático ao concluir qualquer etapa marítima (`complete_active_node()`);
  - Ao iniciar o jogo, se houver save existente, a run é restaurada exatamente de onde o jogador parou;
  - Ao reiniciar manualmente via menu de opções (`⚙`) ou sofrer derrota em combate, o save anterior é deletado e uma nova expedição começa limpa.

## Dívida técnica conhecida
1. Rebuild da mão deve ser observado em mudanças futuras para evitar problemas de `queue_free()` durante sinais.
2. O sistema de status/buffs temporários em combate suporta atualmente intangibilidade, devendo ser estendido quando novos status surgirem.
3. UI visual ainda é de protótipo.
4. Trilha e efeitos sonoros (SFX/BGM) ainda não possuem assets de áudio integrados.

## Próximo marco
Conclusão do Vertical Slice alcançada e sistema de persistência de run integrado! O próximo marco é aprimorar o polimento sonoro (SFX/BGM) ou expandir as regras de metaprogressão (desbloqueio entre runs).



