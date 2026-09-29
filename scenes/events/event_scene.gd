extends Control

signal continue_requested

@onready var title_label: Label = $EventPanel/Margin/EventVBox/TitleLabel
@onready var body_label: Label = $EventPanel/Margin/EventVBox/BodyLabel
@onready var choices_vbox: VBoxContainer = $EventPanel/Margin/EventVBox/ChoicesVBox
@onready var continue_button: Button = $EventPanel/Margin/EventVBox/ContinueButton

var current_event_id: String = "old_port_trainer"
var current_event_data: Dictionary = {}


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	load_event(current_event_id)


func setup(event_id: String) -> void:
	current_event_id = event_id
	if is_node_ready():
		load_event(current_event_id)


func load_event(event_id: String) -> void:
	if not DataLoader.has_event(event_id):
		push_error("Evento não encontrado: %s" % event_id)
		return

	continue_button.visible = false

	current_event_id = event_id
	current_event_data = DataLoader.get_event(event_id)

	title_label.text = str(current_event_data.get("title", "Evento"))
	body_label.text = str(current_event_data.get("body", ""))

	create_choice_buttons()


func create_choice_buttons() -> void:
	clear_choice_buttons()

	var choices: Array = current_event_data.get("choices", [])

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = str(choice.get("label", "Escolha"))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		choices_vbox.add_child(button)


func clear_choice_buttons() -> void:
	for child in choices_vbox.get_children():
		child.queue_free()


func _on_choice_pressed(choice: Dictionary) -> void:
	var effects: Array = choice.get("effects", [])

	for effect in effects:
		if effect is Dictionary:
			resolve_event_effect(effect)

	disable_choices()
	continue_button.visible = true

func _on_continue_pressed() -> void:
	continue_requested.emit()

func resolve_event_effect(effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))

	match effect_type:
		"add_card_to_deck":
			var card_id: String = str(effect.get("card_id", ""))
			GameState.add_card_to_deck(card_id)

		"gain_resource":
			var resource: String = str(effect.get("resource", ""))
			var value: int = int(effect.get("value", 0))
			apply_gain_resource(resource, value)

		"recruit_crew":
			var crew_id: String = str(effect.get("crew_id", ""))
			GameState.recruit_crew(crew_id)

		"heal":
			var heal_val: int = int(effect.get("value", 0))
			GameState.heal_player(heal_val)

		"consume_fruit":
			var fruit_id: String = str(effect.get("fruit_id", ""))
			GameState.consume_fruit(fruit_id)

		_:
			push_warning("Efeito de evento desconhecido: %s" % effect_type)


func apply_gain_resource(resource: String, value: int) -> void:
	match resource:
		"gold":
			GameState.gain_gold(value)
			print("Ganhou %d ouro." % value)

		"bounty":
			GameState.gain_bounty(value)
			print("Ganhou %d bounty." % value)

		_:
			push_warning("Recurso desconhecido em evento: %s" % resource)


func disable_choices() -> void:
	for child in choices_vbox.get_children():
		if child is Button:
			child.disabled = true
