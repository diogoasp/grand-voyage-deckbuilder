extends Control

# Player Labels
@onready var player_hp_label: Label = $TopBar/PlayerHPLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var block_label: Label = $TopBar/BlockLabel

# Enemy Labels
@onready var enemy_hp_label: Label = $TopBar/EnemyHPLabel
@onready var enemy_name_label: Label = $EnemyArea/EnemyNameLabel
@onready var enemy_intent_label: Label = $EnemyArea/EnemyIntentLabel

# Action elements
@onready var hand_area: HBoxContainer = $HandArea
@onready var end_turn_button: Button = $EndTurnButton

var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0

var enemy_name: String = "Recruta da Marinha"
var enemy_hp: int = 32
var enemy_max_hp: int = 32
var enemy_damage: int = 6

var energy: int = 3
var max_energy: int = 3

var combat_finished: bool = false

var hand_cards: Array[Dictionary] = [
	{
		"id": "strike_basic",
		"name": "Golpe Básico",
		"cost": 1,
		"description": "Cause 6 de dano.",
		"effects": [
			{ "type": "damage", "value": 6, "target": "enemy" }
		]
	},
	{
		"id": "defend_basic",
		"name": "Defesa Básica",
		"cost": 1,
		"description": "Ganhe 5 de bloqueio.",
		"effects": [
			{ "type": "block", "value": 5, "target": "player" }
		]
	}
]

func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	create_hand()
	update_ui()

func create_hand() -> void:
	clear_hand()
	
	for card_data in hand_cards:
		var card_button := Button.new()
		card_button.custom_minimum_size = Vector2(120, 200)
		card_button.text = get_card_button_text(card_data)
		card_button.pressed.connect(_on_card_pressed.bind(card_data))
		hand_area.add_child(card_button)

func clear_hand() -> void:
	for child in hand_area.get_children():
		child.queue_free()

func get_card_button_text(card_data: Dictionary) -> String:
	return "%s\nCusto %d\n%s" % [
		card_data["name"],
		card_data["cost"],
		card_data["description"]
	]
	

func update_ui() -> void:
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	enemy_hp_label.text = "Inimigo: %d/%d" % [enemy_hp, enemy_max_hp]
	energy_label.text = "Energia: %d/%d" % [energy, max_energy]
	block_label.text = "Bloqueio: %d" % player_block
	
	enemy_name_label.text = enemy_name
	# Sobre as intenções, como base podemos ver a intenção atual. 
	# Com Haki da observação, podemos ver o dano que será causado. 
	# Com Haki avançado podemos ver, além do dano, a ação seguinte planejada
	enemy_intent_label.text = "Intenção: Atacar causando %d de dano" % enemy_damage
	
	for child in hand_area.get_children():
		if child is Button:
			var card_index := child.get_index()
			var card_data := hand_cards[card_index]
			var cost: int = card_data["cost"]
			child.disabled = combat_finished or energy < cost
			
	end_turn_button.disabled = combat_finished

func _on_card_pressed(card_data: Dictionary) -> void:
	var cost: int = card_data["cost"]
	
	if not can_play_card(cost):
		return
		
	energy -= cost
	resolve_card_effects(card_data)
	
	update_ui()

# TODO: Refatorar
func can_play_card(cost: int) -> bool:
	if combat_finished:
		return false

	if energy < cost:
		print("Energia insuficiente.")
		return false

	return true

func resolve_card_effects(card_data: Dictionary) -> void:
	print("Card jogada: %s" % card_data["name"])
	
	var effects: Array = card_data["effects"]
	
	for effect in effects:
		resolve_effect(effect)
	
	if enemy_hp <= 0:
		end_combat_with_victory()

func resolve_effect(effect: Dictionary) -> void:
	var effect_type: String = effect["type"]
	var value: int = effect["value"]
	var target: String = effect["target"]
	
	match effect_type:
		"damage":
			if target == "enemy":
				enemy_hp -= value
				enemy_hp = max(enemy_hp, 0)
				print("Causou %d de dano." % value)
		"block":
			if target == "player":
				player_block += value
				print("Ganhou %d de bloqueio." % value)
				
		_:
			push_warning("Tipo de efeito desconhecido: %s" % effect_type)

func _on_end_turn() -> void:
	if combat_finished:
		return
	
	resolve_enemy_turn()
	
	if combat_finished:
		update_ui()
		return
	
	start_player_turn()
	update_ui()

func start_player_turn() -> void:
	print("Novo turno do jogador.")
	energy = max_energy
	player_block = 0

func resolve_enemy_turn() -> void:
	print("Turno inimigo!")
	
	var incoming_damage := enemy_damage
	var blocked_damage = min (player_block, incoming_damage)
	var final_damage = incoming_damage - blocked_damage
	
	player_block -= blocked_damage
	player_hp -= final_damage
	player_hp = max(player_hp, 0)
	
	print("Bloqueado: %d. Dano recebido: %d." % [blocked_damage, final_damage])
	
	if player_hp <= 0:
		end_combat_with_defeat()

func end_combat_with_victory() -> void:
	combat_finished = true
	print("Vitória!")

func end_combat_with_defeat() -> void:
	combat_finished = true
	print("Derrota! O capitão caiu.")
	
func _on_end_turn_pressed() -> void:
	if combat_finished: return
	
	resolve_enemy_turn()
	
	if combat_finished:
		update_ui()
		return
		
	start_player_turn()
	update_ui()
	
	
	
	
