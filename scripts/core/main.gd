extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Grand Voyage Deckbuilder iniciado.")
	
	var label := Label.new()
	label.text = "Projeto iniciado"
	add_child(label)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
