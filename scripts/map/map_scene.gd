extends Control

signal node_selected(node_data: Dictionary)
signal new_expedition_requested

const MAP_GENERATOR = preload("res://scripts/map/map_generator.gd")

@onready var title_label: Label = $MainLayout/TopBar/TitleLabel
@onready var status_label: Label = $MainLayout/TopBar/StatusLabel
@onready var map_scroll: ScrollContainer = $MainLayout/MapPanel/MapScroll
@onready var scroll_content: Control = $MainLayout/MapPanel/MapScroll/ScrollContent
@onready var columns_container: HBoxContainer = $MainLayout/MapPanel/MapScroll/ScrollContent/ColumnsContainer
@onready var map_lines_overlay: Control = $MainLayout/MapPanel/MapScroll/ScrollContent/MapLinesOverlay
@onready var prompt_label: Label = $MainLayout/BottomBar/PromptLabel
@onready var victory_button: Button = $MainLayout/BottomBar/VictoryButton

# Lista de colunas/estágios da rota marítima
# Cada nó: id, stage, type ("event", "combat", "boss", "city"), target_id, title, desc, next_nodes
var map_stages: Array[Array] = []

var current_stage: int = 0
var completed_node_ids: Array[String] = []
var last_selected_node_id: String = ""

# Referência aos botões criados indexados por node_id
var node_buttons: Dictionary = {}


func _ready() -> void:
	if victory_button != null:
		victory_button.pressed.connect(_on_victory_button_pressed)
	if map_lines_overlay != null:
		map_lines_overlay.draw.connect(_on_lines_overlay_draw)
	if map_stages.is_empty():
		generate_default_sector_map()
	update_status_display()
	rebuild_map_ui()


func generate_default_sector_map() -> void:
	map_stages = MAP_GENERATOR.generate_sector_map(1)


func setup_state(stage: int, completed_nodes: Array[String], last_node_id: String = "") -> void:
	current_stage = stage
	completed_node_ids = completed_nodes
	last_selected_node_id = last_node_id
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


func find_node_data(node_id: String) -> Dictionary:
	for stage in map_stages:
		for n in stage:
			if n.get("id", "") == node_id:
				return n
	return {}


func rebuild_map_ui() -> void:
	node_buttons.clear()
	for child in columns_container.get_children():
		child.queue_free()

	var sea_name := "South Blue (Ato 1)" if GameState.current_act == 1 else "Grand Line (Ato 2)"
	if title_label != null:
		title_label.text = "Carta de Navegação Náutica — %s" % sea_name

	if current_stage >= map_stages.size():
		if GameState.current_act == 1:
			prompt_label.text = "🏆 O SOUTH BLUE FOI DOMINADO! Os portões da Reverse Mountain estão abertos!"
			if victory_button != null:
				victory_button.text = "Zarpar rumo à Grand Line ⛵"
				victory_button.visible = true
		else:
			prompt_label.text = "🏆 CONQUISTA DA GRAND LINE CONCLUÍDA! O mar deste setor foi dominado!"
			if victory_button != null:
				victory_button.text = "Iniciar Nova Expedição"
				victory_button.visible = true
		if map_lines_overlay != null:
			map_lines_overlay.queue_redraw()
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
			node_buttons[node_data.get("id", "")] = node_button
			column.add_child(node_button)

		columns_container.add_child(column)

	# Ajusta o tamanho mínimo horizontal dinamicamente conforme a quantidade de estágios
	if scroll_content != null:
		var target_min_width: float = maxf(1200.0, float(map_stages.size() * 260 + 100))
		scroll_content.custom_minimum_size = Vector2(target_min_width, 0)

	# Conecta redimensionamento do container para recalcular as linhas se a janela ou painel mudar
	if not columns_container.resized.is_connected(_request_overlay_redraw):
		columns_container.resized.connect(_request_overlay_redraw)

	# Aguarda frames de layout para posições e tamanhos dos botões estarem definidos no container
	_request_overlay_redraw()
	_scroll_to_current_stage()


func _scroll_to_current_stage() -> void:
	if map_scroll == null or not is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if map_scroll != null and is_instance_valid(map_scroll) and map_stages.size() > 0:
		var progress_ratio: float = float(current_stage) / float(maxi(map_stages.size() - 1, 1))
		var max_h_scroll: float = maxf(0.0, scroll_content.custom_minimum_size.x - map_scroll.size.x)
		var target_h: float = progress_ratio * max_h_scroll
		var tween := create_tween()
		tween.tween_property(map_scroll, "scroll_horizontal", int(target_h), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _request_overlay_redraw() -> void:
	if map_lines_overlay == null or not is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if map_lines_overlay != null and is_instance_valid(map_lines_overlay):
		map_lines_overlay.queue_redraw()


func is_node_accessible(node_data: Dictionary, stage_idx: int) -> bool:
	if stage_idx != current_stage:
		return false

	var node_id: String = node_data.get("id", "")
	if completed_node_ids.has(node_id):
		return false

	# No início da run (stage 0), todas as opções do estágio 0 estão disponíveis
	if current_stage == 0:
		return true

	# Nos estágios subsequentes, só é acessível se estiver em next_nodes do nó escolhido na etapa anterior
	if last_selected_node_id != "":
		var prev_data: Dictionary = find_node_data(last_selected_node_id)
		var next_list: Array = prev_data.get("next_nodes", [])
		if not next_list.is_empty():
			return next_list.has(node_id)

	# Fallback de segurança se não houver registro prévio ou se o nó anterior não tinha conexões válidas
	return true


func create_node_button(node_data: Dictionary, stage_idx: int) -> Button:
	var button := Button.new()
	var node_id: String = node_data.get("id", "")
	var node_type: String = node_data.get("type", "")
	var island_name: String = str(node_data.get("island_name", ""))
	var title: String = node_data.get("title", "")
	var desc: String = node_data.get("desc", "")

	var type_prefix := ""
	match node_type:
		"combat":
			type_prefix = "⚔ [Combate] "
		"event":
			type_prefix = "📜 [Evento] "
		"city":
			type_prefix = "⚓ [Porto] "
		"boss":
			type_prefix = "💀 [CHEFE DO MAR] "

	if island_name != "" and not title.begins_with(island_name):
		button.text = "%s%s\n%s\n(%s)" % [type_prefix, island_name, title, desc]
	else:
		button.text = "%s%s\n(%s)" % [type_prefix, title, desc]

	button.custom_minimum_size = Vector2(210, 85)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var is_completed: bool = completed_node_ids.has(node_id)
	var is_current_reachable: bool = is_node_accessible(node_data, stage_idx)

	if is_completed:
		button.disabled = true
		var done_label: String = "✓ [Derrotado]" if node_type == "boss" else "✓ [Visitado]"
		button.text = "%s\n%s" % [done_label, island_name if island_name != "" else title]
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
			button.modulate = Color(0.9, 0.5, 0.5, 0.4)
		else:
			button.modulate = Color(0.7, 0.7, 0.7, 0.4)

	return button


func _on_lines_overlay_draw() -> void:
	if map_lines_overlay == null or map_stages.is_empty():
		return

	# Percorre todas as conexões entre estágios
	for stage_idx in range(map_stages.size() - 1):
		var curr_nodes: Array = map_stages[stage_idx]
		for node in curr_nodes:
			var node_id: String = node.get("id", "")
			var from_btn: Button = node_buttons.get(node_id, null)
			if from_btn == null or not is_instance_valid(from_btn):
				continue

			var overlay_origin: Vector2 = map_lines_overlay.global_position
			var from_rect: Rect2 = from_btn.get_global_rect()
			# Ponto de saída no lado direito do botão de origem
			var global_from: Vector2 = Vector2(from_rect.end.x, from_rect.position.y + from_rect.size.y * 0.5)
			var local_from: Vector2 = global_from - overlay_origin

			var next_list: Array = node.get("next_nodes", [])
			for target_id in next_list:
				var to_btn: Button = node_buttons.get(target_id, null)
				if to_btn == null or not is_instance_valid(to_btn):
					continue

				var to_rect: Rect2 = to_btn.get_global_rect()
				# Ponto de chegada no lado esquerdo do botão de destino
				var global_to: Vector2 = Vector2(to_rect.position.x, to_rect.position.y + to_rect.size.y * 0.5)
				var local_to: Vector2 = global_to - overlay_origin

				# Determina se esta linha está ativa/alcançável
				var is_active_route := false
				if current_stage == 0 and stage_idx == 0:
					# No início, todas as conexões a partir do stage 0 são rotas potenciais ativas
					is_active_route = true
				elif stage_idx < current_stage:
					# Se o nó de origem foi o escolhido, sua conexão é destacada se foi percorrida
					if node_id == last_selected_node_id or completed_node_ids.has(node_id):
						is_active_route = true
				elif stage_idx == current_stage:
					# Linhas saindo do estágio atual
					if last_selected_node_id != "" and node_id == last_selected_node_id:
						is_active_route = true

				var line_color: Color
				var line_width: float = 2.0

				if is_active_route:
					line_color = Color(0.9, 0.75, 0.25, 0.85) # Dourado náutico brilhante
					line_width = 3.0
				else:
					line_color = Color(0.35, 0.45, 0.6, 0.4) # Azul-ardósia sutil/translúcido

				map_lines_overlay.draw_line(local_from, local_to, line_color, line_width, true)


func _on_node_pressed(node_data: Dictionary) -> void:
	node_selected.emit(node_data)


func _on_victory_button_pressed() -> void:
	new_expedition_requested.emit()
