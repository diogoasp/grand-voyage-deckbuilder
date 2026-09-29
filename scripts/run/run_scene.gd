extends Control

const EVENT_SCENE: PackedScene = preload("res://scenes/events/EventScene.tscn")
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/CombatScene.tscn")
const CITY_SCENE: PackedScene = preload("res://scenes/city/CityScene.tscn")

@onready var screen_container: Control = $ScreenContainer

var current_screen: Node = null


func _ready() -> void:
	start_run()


func start_run() -> void:
	GameState.reset_run()
	show_event("old_port_trainer")


func clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		if current_screen.get_parent() == screen_container:
			screen_container.remove_child(current_screen)
		current_screen.queue_free()
		current_screen = null


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
	show_combat("marine_recruit")


func _on_combat_victory() -> void:
	show_city()


func _on_city_depart_requested() -> void:
	show_combat("bandit_sailor")


func _on_combat_defeat() -> void:
	start_run()
