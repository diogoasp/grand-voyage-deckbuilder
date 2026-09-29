extends Control

signal depart_requested

@onready var title_label: Label = $CityPanel/CityVBox/TitleLabel
@onready var description_label: Label = $CityPanel/CityVBox/DescriptionLabel
@onready var status_label: Label = $CityPanel/CityVBox/StatusLabel
@onready var feedback_label: Label = $CityPanel/CityVBox/FeedbackLabel

@onready var rest_button: Button = $CityPanel/CityVBox/ActionsVBox/RestButton
@onready var train_button: Button = $CityPanel/CityVBox/ActionsVBox/TrainButton
@onready var supplies_button: Button = $CityPanel/CityVBox/ActionsVBox/SuppliesButton
@onready var depart_button: Button = $CityPanel/CityVBox/DepartButton

var action_taken: bool = false

const REST_HEAL_AMOUNT: int = 20
const TRAIN_GOLD_COST: int = 15
const SUPPLIES_GOLD_COST: int = 10
const SUPPLIES_FOOD_AMOUNT: int = 3


func _ready() -> void:
	rest_button.pressed.connect(_on_rest_pressed)
	train_button.pressed.connect(_on_train_pressed)
	supplies_button.pressed.connect(_on_supplies_pressed)
	depart_button.pressed.connect(_on_depart_pressed)

	feedback_label.text = ""
	update_status()
	update_buttons_state()


func update_status() -> void:
	status_label.text = "HP: %d/%d | Ouro: %d | Comida: %d" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.gold,
		GameState.food
	]


func update_buttons_state() -> void:
	if action_taken:
		rest_button.disabled = true
		train_button.disabled = true
		supplies_button.disabled = true
		depart_button.disabled = false
		return

	depart_button.disabled = false
	rest_button.disabled = GameState.player_hp >= GameState.player_max_hp
	train_button.disabled = GameState.gold < TRAIN_GOLD_COST
	supplies_button.disabled = GameState.gold < SUPPLIES_GOLD_COST


func _on_rest_pressed() -> void:
	if action_taken:
		return

	action_taken = true
	var before_hp := GameState.player_hp
	GameState.heal_player(REST_HEAL_AMOUNT)
	var healed := GameState.player_hp - before_hp

	feedback_label.text = "A tripulação descansou na taverna do porto (+%d HP)." % healed
	update_status()
	update_buttons_state()


func _on_train_pressed() -> void:
	if action_taken:
		return

	if not GameState.spend_gold(TRAIN_GOLD_COST):
		feedback_label.text = "Ouro insuficiente para treinar."
		return

	action_taken = true
	GameState.add_card_to_deck("strike_basic")
	feedback_label.text = "Treinamento concluído no porto (-%d Ouro, +1 Golpe Básico ao deck)." % TRAIN_GOLD_COST
	update_status()
	update_buttons_state()


func _on_supplies_pressed() -> void:
	if action_taken:
		return

	if not GameState.spend_gold(SUPPLIES_GOLD_COST):
		feedback_label.text = "Ouro insuficiente para comprar provisões."
		return

	action_taken = true
	GameState.food += SUPPLIES_FOOD_AMOUNT
	feedback_label.text = "Provisões adquiridas no mercado (-%d Ouro, +%d Comida)." % [
		SUPPLIES_GOLD_COST,
		SUPPLIES_FOOD_AMOUNT
	]
	update_status()
	update_buttons_state()


func _on_depart_pressed() -> void:
	depart_requested.emit()
