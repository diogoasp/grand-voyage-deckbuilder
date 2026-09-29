extends Control

signal node_selected(node_data: Dictionary)
signal new_expedition_requested

const MAP_GENERATOR = preload("res://scripts/map/map_generator.gd")

@onready var title_label: Label = $MainLayout/TopBar/TitleLabel
@onready var status_label: Label = $MainLayout/TopBar/StatusLabel
@onready var columns_container: HBoxContainer = $MainLayout/MapPanel/ColumnsContainer
@onready var prompt_label: Label = $MainLayout/BottomBar/PromptLabel
@onready var victory_button: Button = $MainLayout/BottomBar/VictoryButton

# Lista de colunas/estágios da rota marítima
# Cada nó: id, stage, type ("event", "combat", "boss", "city"), target_id, title, desc
var map_stages: Array[Array] = []

var current_stage: int = 0
var completed_node_ids: Array[String] = []


func _ready() -> void:
	if victory_button != null:
		victory_button.pressed.connect(_on_victory_button_pressed)
	if map_stages.is_empty():
		generate_default_sector_map()
	update_status_display()
	rebuild_map_ui()


func generate_default_sector_map() -> void:
	map_stages = MAP_GENERATOR.generate_sector_map(1)


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

	var fruit_str := "Nenhuma"
	if GameState.has_eaten_fruit():
		if DataLoader.has_fruit(GameState.eaten_fruit):
			fruit_str = DataLoader.get_fruit(GameState.eaten_fruit).get("name", GameState.eaten_fruit)
		else:
			fruit_str = GameState.eaten_fruit

	status_label.text = "HP: %d/%d | Ouro: %d | Comida: %d | Bounty: %d\nTripulação: %s | Fruta: %s" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.gold,
		GameState.food,
		GameState.bounty,
		crew_str,
		fruit_str
	]


func rebuild_map_ui() -> void:
	for child in columns_container.get_children():
		child.queue_free()

	if current_stage >= map_stages.size():
		prompt_label.text = "🏆 ROTA DO SETOR CONCLUÍDA! O Capitão Morgan foi derrotado e o mar deste setor foi dominado!"
		if victory_button != null:
			victory_button.visible = true
		return

	if victory_button != null:
		victory_button.visible = false

	prompt_label.text = "Escolha a próxima ilha/encontro no mapa para traçar o rumo:"

	for stage_idx in range(map_stages.size()):
		var stage_nodes: Array = map_stages[stage_idx]

		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 16)
		column.alignment = BoxContainer.ALIGNMENT_CENTER

		# Cabeçalho da coluna/milha náutica
		var stage_header := Label.new()
		stage_header.text = "Setor %d" % (stage_idx + 1)
		stage_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
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
		"boss":
			type_prefix = "💀 [CHEFE] "

	button.text = "%s%s\n(%s)" % [type_prefix, title, desc]
	button.custom_minimum_size = Vector2(170, 75)

	var is_completed: bool = completed_node_ids.has(node_id)
	var is_current_reachable: bool = (stage_idx == current_stage)

	if is_completed:
		button.disabled = true
		button.text = "[Derrotado]\n" + title if node_type == "boss" else "[Visitado]\n" + title
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif is_current_reachable:
		button.disabled = false
		if node_type == "boss":
			button.modulate = Color(1.3, 0.7, 0.7, 1.0)
		else:
			button.modulate = Color(1.1, 1.1, 0.9, 1.0)
		button.pressed.connect(_on_node_pressed.bind(node_data))
	else:
		button.disabled = true
		if node_type == "boss":
			button.modulate = Color(0.9, 0.5, 0.5, 0.5)
		else:
			button.modulate = Color(0.7, 0.7, 0.7, 0.4)

	return button


func _on_node_pressed(node_data: Dictionary) -> void:
	node_selected.emit(node_data)


func _on_victory_button_pressed() -> void:
	new_expedition_requested.emit()
