extends Node

func _ready() -> void:
	GameState.reset_run()

	var event_scene := preload("res://scenes/events/EventScene.tscn").instantiate()
	add_child(event_scene)
