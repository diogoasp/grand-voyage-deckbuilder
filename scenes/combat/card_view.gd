class_name CardView
extends PanelContainer

signal card_play_requested(card_view: CardView)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

var instance_id: int = -1
var card_id: String = ""
var cost: int = 0

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_global_position: Vector2 = Vector2.ZERO

var play_threshold_y: float = 420.0


func setup(card_instance: CardInstance, card_data: Dictionary) -> void:
	instance_id = card_instance.instance_id
	card_id = card_instance.card_id
	cost = int(card_data["cost"])

	name_label.text = str(card_data["name"])
	cost_label.text = "Custo: %d" % cost
	description_label.text = str(card_data["description"])


func _gui_input(event: InputEvent) -> void:
	if disabled_by_parent():
		return

	if event is InputEventMouseButton:
		handle_mouse_button(event)

	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)


func handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		start_drag(event.global_position)
	else:
		end_drag()


func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not is_dragging:
		return

	global_position = event.global_position - drag_offset


func start_drag(mouse_global_position: Vector2) -> void:
	is_dragging = true
	original_global_position = global_position
	drag_offset = mouse_global_position - global_position
	z_index = 100


func end_drag() -> void:
	if not is_dragging:
		return

	is_dragging = false
	z_index = 0

	if global_position.y < play_threshold_y:
		card_play_requested.emit(self)
	else:
		global_position = original_global_position


func disabled_by_parent() -> bool:
	return modulate.a < 1.0
