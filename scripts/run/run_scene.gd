extends Control

const MAP_SCENE: PackedScene = preload("res://scenes/map/MapScene.tscn")
const EVENT_SCENE: PackedScene = preload("res://scenes/events/EventScene.tscn")
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/CombatScene.tscn")
const CITY_SCENE: PackedScene = preload("res://scenes/city/CityScene.tscn")
const MAP_GENERATOR = preload("res://scripts/map/map_generator.gd")

@onready var screen_container: Control = $ScreenContainer
@onready var settings_button: Button = $TopRightUI/SettingsButton
@onready var settings_overlay: ColorRect = $SettingsOverlay
@onready var reset_run_button: Button = $SettingsOverlay/SettingsPanel/Margin/VBox/ResetRunButton
@onready var close_settings_button: Button = $SettingsOverlay/SettingsPanel/Margin/VBox/CloseSettingsButton

var current_screen: Node = null

var current_stage: int = 0
var completed_nodes: Array[String] = []
var active_node_data: Dictionary = {}
var sector_map: Array[Array] = []
var last_selected_node_id: String = ""


func _ready() -> void:
	randomize()
	settings_button.pressed.connect(_on_settings_button_pressed)
	close_settings_button.pressed.connect(_on_close_settings_button_pressed)
	reset_run_button.pressed.connect(_on_reset_run_pressed)
	settings_overlay.visible = false

	if GameState.has_saved_run():
		load_saved_run()
	else:
		start_run()


func _on_settings_button_pressed() -> void:
	settings_overlay.visible = true


func _on_close_settings_button_pressed() -> void:
	settings_overlay.visible = false


func _on_reset_run_pressed() -> void:
	settings_overlay.visible = false
	start_run()


func start_run() -> void:
	randomize()
	GameState.delete_saved_run()
	GameState.reset_run()
	current_stage = 0
	completed_nodes.clear()
	active_node_data.clear()
	last_selected_node_id = ""
	sector_map = MAP_GENERATOR.generate_sector_map(1)
	save_run()
	show_map()



func save_run() -> void:
	var extra: Dictionary = {
		"current_stage": current_stage,
		"completed_nodes": completed_nodes,
		"sector_map": sector_map,
		"last_selected_node_id": last_selected_node_id
	}
	GameState.save_run_state(extra)


func load_saved_run() -> void:
	var extra: Dictionary = GameState.load_run_state()
	current_stage = int(extra.get("current_stage", 0))
	last_selected_node_id = str(extra.get("last_selected_node_id", ""))
	
	completed_nodes.clear()
	for nid in extra.get("completed_nodes", []):
		completed_nodes.append(str(nid))

	sector_map.clear()
	var raw_map = extra.get("sector_map", [])
	var map_valid := true
	if raw_map is Array and not raw_map.is_empty():
		for stage in raw_map:
			if stage is Array and not stage.is_empty():
				for n in stage:
					if not (n is Dictionary) or n.is_empty() or not n.has("id"):
						map_valid = false
						break
				if not map_valid:
					break
				sector_map.append(stage)
			else:
				map_valid = false
				break
	else:
		map_valid = false

	if not map_valid or sector_map.is_empty():
		sector_map = MAP_GENERATOR.generate_sector_map(1)
	else:
		# Verifica se os nós possuem 'next_nodes' populados; se não tiverem (save antigo), reconstrói as rotas
		var needs_connections := false
		for stage_idx in range(sector_map.size() - 1):
			var stage_nodes: Array = sector_map[stage_idx]
			for node in stage_nodes:
				if not node.has("next_nodes") or (node.get("next_nodes", []) as Array).is_empty():
					needs_connections = true
					break
			if needs_connections:
				break
		if needs_connections:
			for stage_idx in range(sector_map.size() - 1):
				MAP_GENERATOR.build_stage_connections(sector_map[stage_idx], sector_map[stage_idx + 1])

	show_map()



func clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		if current_screen.get_parent() == screen_container:
			screen_container.remove_child(current_screen)
		current_screen.queue_free()
		current_screen = null


func switch_to_screen(new_screen: Node) -> void:
	if not is_instance_valid(new_screen):
		return

	clear_current_screen()
	current_screen = new_screen

	if new_screen is CanvasItem:
		new_screen.modulate.a = 0.0
		screen_container.add_child(new_screen)
		var tween := create_tween()
		tween.tween_property(new_screen, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		screen_container.add_child(new_screen)


func show_map() -> void:
	var map_scene: Node = MAP_SCENE.instantiate()
	if "map_stages" in map_scene and not sector_map.is_empty():
		map_scene.map_stages = sector_map

	if map_scene.has_method("setup_state"):
		map_scene.setup_state(current_stage, completed_nodes, last_selected_node_id)

	if map_scene.has_signal("node_selected"):
		map_scene.node_selected.connect(_on_map_node_selected)

	if map_scene.has_signal("new_expedition_requested"):
		map_scene.new_expedition_requested.connect(start_run)

	switch_to_screen(map_scene)


func _on_map_node_selected(node_data: Dictionary) -> void:
	active_node_data = node_data
	last_selected_node_id = str(node_data.get("id", ""))
	save_run()
	var node_type: String = str(node_data.get("type", ""))
	var target_id: String = str(node_data.get("target_id", ""))

	match node_type:
		"event":
			show_event(target_id)
		"combat", "boss":
			show_combat(target_id)
		"city":
			show_city()
		_:
			push_warning("Tipo de nó desconhecido no mapa: %s" % node_type)
			show_map()


func complete_active_node() -> void:
	var node_id: String = str(active_node_data.get("id", ""))
	if node_id != "" and not completed_nodes.has(node_id):
		completed_nodes.append(node_id)

	apply_crew_travel_effects()

	current_stage += 1
	active_node_data.clear()
	save_run()
	show_map()



func apply_crew_travel_effects() -> void:
	for crew_id in GameState.crew_members:
		if not DataLoader.has_crew(crew_id):
			continue

		var crew_data: Dictionary = DataLoader.get_crew(crew_id)

		# Custo de manutenção (comida)
		var food_cost: int = int(crew_data.get("food_cost_per_sector", 0))
		if food_cost > 0:
			GameState.spend_food(food_cost)

		# Passiva de cura em viagem (Médico)
		var heal_amount: int = int(crew_data.get("passive_heal_per_sector", 0))
		if heal_amount > 0:
			GameState.heal_player(heal_amount)
			print("Passiva da tripulação [%s]: capitão recuperou +%d HP na travessia." % [
				crew_data.get("name", crew_id),
				heal_amount
			])


func show_event(event_id: String) -> void:
	var event_scene: Node = EVENT_SCENE.instantiate()
	if event_scene.has_method("setup"):
		event_scene.setup(event_id)

	if event_scene.has_signal("continue_requested"):
		event_scene.continue_requested.connect(_on_event_continue_requested)

	switch_to_screen(event_scene)


func show_combat(enemy_id: String = "marine_recruit") -> void:
	var combat_scene: Node = COMBAT_SCENE.instantiate()
	if "current_enemy_id" in combat_scene:
		combat_scene.current_enemy_id = enemy_id

	if combat_scene.has_signal("combat_victory"):
		combat_scene.combat_victory.connect(_on_combat_victory)

	if combat_scene.has_signal("combat_defeat"):
		combat_scene.combat_defeat.connect(_on_combat_defeat)

	switch_to_screen(combat_scene)


func show_city() -> void:
	var city_scene: Node = CITY_SCENE.instantiate()
	if city_scene.has_signal("depart_requested"):
		city_scene.depart_requested.connect(_on_city_depart_requested)

	switch_to_screen(city_scene)


func _on_event_continue_requested() -> void:
	complete_active_node()


func _on_combat_victory() -> void:
	complete_active_node()


func _on_city_depart_requested() -> void:
	complete_active_node()


func _on_combat_defeat() -> void:
	start_run()
