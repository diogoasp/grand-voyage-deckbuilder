class_name CardView
extends PanelContainer

signal card_drag_started(card_view: CardView)
signal card_drag_ended(card_view: CardView)
signal card_play_requested(card_view: CardView, drop_position: Vector2)

const CARD_SIZE: Vector2 = Vector2(120, 180)

const BASE_POSITION: Vector2 = Vector2.ZERO
const HOVER_POSITION: Vector2 = Vector2(0, -24)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

var instance_id: int = -1
var card_id: String = ""
var cost: int = 0

var is_dragging: bool = false
var is_hovered: bool = false

var drag_offset: Vector2 = Vector2.ZERO
var return_global_position: Vector2 = Vector2.ZERO
var tween: Tween


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	name_label.clip_text = true
	cost_label.clip_text = true
	description_label.clip_text = true
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func setup(card_instance: CardInstance, card_data: Dictionary) -> void:
	instance_id = card_instance.instance_id
	card_id = card_instance.card_id
	cost = int(card_data["cost"])

	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	position = BASE_POSITION

	name_label.text = str(card_data["name"])
	cost_label.text = "Custo: %d" % cost
	description_label.text = str(card_data["description"])


func _gui_input(event: InputEvent) -> void:
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
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
		end_drag(event.global_position)


func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not is_dragging:
		return

	global_position = event.global_position - drag_offset


func start_drag(mouse_global_position: Vector2) -> void:
	stop_current_tween()

	is_dragging = true
	return_global_position = global_position
	drag_offset = mouse_global_position - global_position
	z_index = 100

	card_drag_started.emit(self)


func end_drag(mouse_global_position: Vector2) -> void:
	if not is_dragging:
		return

	is_dragging = false
	z_index = 0

	card_drag_ended.emit(self)
	card_play_requested.emit(self, mouse_global_position)


func return_to_original_position() -> void:
	stop_current_tween()

	tween = create_tween()
	tween.tween_property(
		self,
		"global_position",
		return_global_position,
		0.15
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_mouse_entered() -> void:
	if is_dragging:
		return

	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	is_hovered = true
	z_index = 10
	animate_to_local_position(HOVER_POSITION)


func _on_mouse_exited() -> void:
	if is_dragging:
		return

	is_hovered = false
	z_index = 0
	animate_to_local_position(BASE_POSITION)


func animate_to_local_position(target_position: Vector2) -> void:
	stop_current_tween()

	tween = create_tween()
	tween.tween_property(
		self,
		"position",
		target_position,
		0.12
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func reset_visual_state() -> void:
	stop_current_tween()
	is_dragging = false
	is_hovered = false
	z_index = 0
	position = BASE_POSITION


func stop_current_tween() -> void:
	if tween != null and tween.is_valid():
		tween.kill()
