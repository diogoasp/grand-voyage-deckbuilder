extends Control

const MAP_SCENE: PackedScene = preload("res://scenes/map/MapScene.tscn")
const EVENT_SCENE: PackedScene = preload("res://scenes/events/EventScene.tscn")
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/CombatScene.tscn")
const CITY_SCENE: PackedScene = preload("res://scenes/city/CityScene.tscn")

@onready var screen_container: Control = $ScreenContainer

var current_screen: Node = null

var current_stage: int = 0
var completed_nodes: Array[String] = []
var active_node_data: Dictionary = {}


func _ready() -> void:
	start_run()


func start_run() -> void:
	GameState.reset_run()
	current_stage = 0
	completed_nodes.clear()
	active_node_data.clear()
	show_map()


func clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		if current_screen.get_parent() == screen_container:
			screen_container.remove_child(current_screen)
		current_screen.queue_free()
		current_screen = null


func show_map() -> void:
	clear_current_screen()

	var map_scene: Node = MAP_SCENE.instantiate()
	if map_scene.has_method("setup_state"):
		map_scene.setup_state(current_stage, completed_nodes)

	if map_scene.has_signal("node_selected"):
		map_scene.node_selected.connect(_on_map_node_selected)

	current_screen = map_scene
	screen_container.add_child(map_scene)


func _on_map_node_selected(node_data: Dictionary) -> void:
	active_node_data = node_data
	var node_type: String = str(node_data.get("type", ""))
	var target_id: String = str(node_data.get("target_id", ""))

	match node_type:
		"event":
			show_event(target_id)
		"combat":
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
	clear_current_screen()

	var event_scene: Node = EVENT_SCENE.instantiate()
	if event_scene.has_method("setup"):
		event_scene.setup(event_id)

	if event_scene.has_signal("continue_requested"):
		event_scene.continue_requested.connect(_on_event_continue_requested)

	current_screen = event_scene
	screen_container.add_child(event_scene)


func show_combat(enemy_id: String = "marine_recruit") -> void:
	clear_current_screen()

	var combat_scene: Node = COMBAT_SCENE.instantiate()
	if "current_enemy_id" in combat_scene:
		combat_scene.current_enemy_id = enemy_id

	if combat_scene.has_signal("combat_victory"):
		combat_scene.combat_victory.connect(_on_combat_victory)

	if combat_scene.has_signal("combat_defeat"):
		combat_scene.combat_defeat.connect(_on_combat_defeat)

	current_screen = combat_scene
	screen_container.add_child(combat_scene)


func show_city() -> void:
	clear_current_screen()

	var city_scene: Node = CITY_SCENE.instantiate()
	if city_scene.has_signal("depart_requested"):
		city_scene.depart_requested.connect(_on_city_depart_requested)

	current_screen = city_scene
	screen_container.add_child(city_scene)


func _on_event_continue_requested() -> void:
	complete_active_node()


func _on_combat_victory() -> void:
	complete_active_node()


func _on_city_depart_requested() -> void:
	complete_active_node()


func _on_combat_defeat() -> void:
	start_run()
