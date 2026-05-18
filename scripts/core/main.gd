extends Node

func _ready() -> void:
	var combat_scene := preload("res://scenes/combat/CombatScene.tscn").instantiate()
	add_child(combat_scene)
