extends Control

signal node_selected(node_data: Dictionary)

@onready var title_label: Label = $TopBar/TitleLabel
@onready var status_label: Label = $TopBar/StatusLabel
@onready var columns_container: HBoxContainer = $MapPanel/ColumnsContainer
@onready var prompt_label: Label = $BottomBar/PromptLabel

# Lista de colunas/estágios da rota marítima
# Cada nó: id, stage, type ("event", "combat", "city"), target_id, label, icon
var map_stages: Array[Array] = [
	# Estágio 0: Ponto de partida (Treinamento OU Recrutar Médico no cais)
	[
		{
			"id": "node_0_0",
			"stage": 0,
			"type": "event",
			"target_id": "old_port_trainer",
			"title": "Velho Lutador",
			"desc": "Treino de Postura"
		},
		{
			"id": "node_0_1",
			"stage": 0,
			"type": "event",
			"target_id": "wandering_doctor",
			"title": "Médico do Cais",
			"desc": "Recrutar Dr. Lin"
		}
	],
	# Estágio 1: Primeira rota de mar (Combate: Patrulha da Marinha OU Saqueador)
	[
		{
			"id": "node_1_0",
			"stage": 1,
			"type": "combat",
			"target_id": "marine_recruit",
			"title": "Recruta da Marinha",
			"desc": "Patrulha costeira"
		},
		{
			"id": "node_1_1",
			"stage": 1,
			"type": "combat",
			"target_id": "bandit_sailor",
			"title": "Saqueador do Mar",
			"desc": "Pirataria rival"
		}
	],
	# Estágio 2: Parada náutica (Porto seguro / Cidade)
	[
		{
			"id": "node_2_0",
			"stage": 2,
			"type": "city",
			"target_id": "port",
			"title": "Porto Seguro",
			"desc": "Taverna & Mercado"
		}
	],
	# Estágio 3: Águas profundas (Confronto final do setor)
	[
		{
			"id": "node_3_0",
			"stage": 3,
			"type": "combat",
			"target_id": "bandit_sailor",
			"title": "Embosca no Estreito",
			"desc": "Ameaça marítima"
		}
	]
]

var current_stage: int = 0
var completed_node_ids: Array[String] = []


func _ready() -> void:
	update_status_display()
	rebuild_map_ui()


func setup_state(stage: int, completed_nodes: Array[String]) -> void:
	current_stage = stage
	completed_node_ids = completed_nodes
	if is_node_ready():
		update_status_display()
		rebuild_map_ui()


func update_status_display() -> void:
	var crew_names: Array[String] = []
	for crew_id in GameState.crew_members:
		if DataLoader.has_crew(crew_id):
			var data: Dictionary = DataLoader.get_crew(crew_id)
			crew_names.append("%s (%s)" % [data.get("name", crew_id), data.get("role", "")])
		else:
			crew_names.append(crew_id)

	var crew_str := "Nenhum" if crew_names.is_empty() else ", ".join(crew_names)

	status_label.text = "HP: %d/%d | Ouro: %d | Comida: %d | Bounty: %d\nTripulação: %s" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.gold,
		GameState.food,
		GameState.bounty,
		crew_str
	]


func rebuild_map_ui() -> void:
	for child in columns_container.get_children():
		child.queue_free()

	if current_stage >= map_stages.size():
		prompt_label.text = "Rota do setor concluída! O capitão dominou estas águas."
		return

	prompt_label.text = "Escolha a próxima ilha/encontro no mapa para traçar o rumo:"

	for stage_idx in range(map_stages.size()):
		var stage_nodes: Array = map_stages[stage_idx]

		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.theme_override_constants/separation = 16
		column.alignment = BoxContainer.ALIGNMENT_CENTER

		# Cabeçalho da coluna/milha náutica
		var stage_header := Label.new()
		stage_header.text = "Setor %d" % (stage_idx + 1)
		stage_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage_header.theme_override_colors/font_color = Color(0.7, 0.7, 0.7)
		column.add_child(stage_header)

		for node_data in stage_nodes:
			var node_button := create_node_button(node_data, stage_idx)
			column.add_child(node_button)

		columns_container.add_child(column)


func create_node_button(node_data: Dictionary, stage_idx: int) -> Button:
	var button := Button.new()
	var node_id: String = node_data.get("id", "")
	var node_type: String = node_data.get("type", "")
	var title: String = node_data.get("title", "")
	var desc: String = node_data.get("desc", "")

	var type_prefix := ""
	match node_type:
		"combat":
			type_prefix = "[Combate] "
		"event":
			type_prefix = "[Evento] "
		"city":
			type_prefix = "[Porto] "

	button.text = "%s%s\n(%s)" % [type_prefix, title, desc]
	button.custom_minimum_size = Vector2(170, 75)

	var is_completed: bool = completed_node_ids.has(node_id)
	var is_current_reachable: bool = (stage_idx == current_stage)

	if is_completed:
		button.disabled = true
		button.text = "[Visitado]\n" + title
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif is_current_reachable:
		button.disabled = false
		button.modulate = Color(1.1, 1.1, 0.9, 1.0)
		button.pressed.connect(_on_node_pressed.bind(node_data))
	else:
		button.disabled = true
		button.modulate = Color(0.7, 0.7, 0.7, 0.4)

	return button


func _on_node_pressed(node_data: Dictionary) -> void:
	node_selected.emit(node_data)
