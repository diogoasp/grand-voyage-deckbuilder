extends Node


func _ready() -> void:
	var run_scene := preload("res://scenes/run/RunScene.tscn").instantiate()
	add_child(run_scene)
