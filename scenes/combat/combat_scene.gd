extends Control

@onready var player_hp_label: Label = $TopBar/PlayerHPLabel
@onready var enemy_hp_label: Label = $TopBar/EnemyHPLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var block_label: Label = $TopBar/BlockLabel
@onready var draw_pile_label: Label = $TopBar/DrawPileLabel
@onready var discard_pile_label: Label = $TopBar/DiscardPileLabel

@onready var enemy_name_label: Label = $EnemyArea/EnemyNameLabel
@onready var enemy_intent_label: Label = $EnemyArea/EnemyIntentLabel

@onready var hand_area: HBoxContainer = $HandArea
@onready var end_turn_button: Button = $EndTurnButton


var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0

var energy: int = 3
var max_energy: int = 3
var cards_per_turn: int = 5

var current_enemy_id: String = "marine_recruit"
var current_enemy_data: Dictionary = {}

var enemy_name: String = ""
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_intent: Dictionary = {}

var combat_finished: bool = false
var next_card_instance_id: int = 1


var starting_deck_ids: Array[String] = [
	"strike_basic",
	"strike_basic",
	"strike_basic",
	"defend_basic",
	"defend_basic",
	"defend_basic"
]

var draw_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []


func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	start_combat()


func start_combat() -> void:
	combat_finished = false
	next_card_instance_id = 1

	player_hp = player_max_hp
	player_block = 0
	energy = max_energy
	
	load_enemy(current_enemy_id)

	draw_pile.clear()
	hand.clear()
	discard_pile.clear()

	for card_id in starting_deck_ids:
		draw_pile.append(create_card_instance(card_id))

	draw_pile.shuffle()

	draw_cards(cards_per_turn)
	rebuild_hand_ui()
	update_ui()

	print("Combate iniciado.")


func create_card_instance(card_id: String) -> Dictionary:
	if not DataLoader.has_card(card_id):
		push_error("Carta não encontrada no banco: %s" % card_id)
		return {}

	var instance := {
		"instance_id": next_card_instance_id,
		"card_id": card_id
	}

	next_card_instance_id += 1

	return instance


func draw_cards(amount: int) -> void:
	for i in range(amount):
		if draw_pile.is_empty():
			reshuffle_discard_into_draw_pile()

		if draw_pile.is_empty():
			return

		var card_instance: Dictionary = draw_pile.pop_back()
		hand.append(card_instance)


func reshuffle_discard_into_draw_pile() -> void:
	if discard_pile.is_empty():
		return

	print("Embaralhando descarte no deck de compra.")

	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()


func rebuild_hand_ui() -> void:
	clear_hand_ui()

	for card_instance in hand:
		var card_id: String = str(card_instance["card_id"])
		var instance_id: int = int(card_instance["instance_id"])

		if not DataLoader.has_card(card_id):
			push_warning("Carta ausente do banco: %s" % card_id)
			continue

		var card_data: Dictionary = DataLoader.get_card(card_id)

		var card_button := Button.new()
		card_button.custom_minimum_size = Vector2(160, 110)
		card_button.text = get_card_button_text(card_data)
		card_button.set_meta("instance_id", instance_id)
		card_button.set_meta("card_id", card_id)
		card_button.set_meta("cost", int(card_data["cost"]))
		card_button.pressed.connect(_on_card_button_pressed.bind(card_button))

		hand_area.add_child(card_button)


func clear_hand_ui() -> void:
	for child in hand_area.get_children():
		child.queue_free()


func get_card_button_text(card_data: Dictionary) -> String:
	var card_name: String = str(card_data["name"])
	var cost: int = int(card_data["cost"])
	var description: String = str(card_data["description"])

	return "%s\nCusto %d\n%s" % [
		card_name,
		cost,
		description
	]


func update_ui() -> void:
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	enemy_hp_label.text = "Inimigo: %d/%d" % [enemy_hp, enemy_max_hp]
	energy_label.text = "Energia: %d/%d" % [energy, max_energy]
	block_label.text = "Bloqueio: %d" % player_block
	draw_pile_label.text = "Deck: %d" % draw_pile.size()
	discard_pile_label.text = "Descarte: %d" % discard_pile.size()

	enemy_name_label.text = enemy_name

	if combat_finished:
		enemy_intent_label.text = "Combate encerrado"
	else:
		enemy_intent_label.text = get_enemy_intent_text()

	for child in hand_area.get_children():
		if child is Button:
			var cost: int = int(child.get_meta("cost", 0))
			child.disabled = combat_finished or energy < cost

	end_turn_button.disabled = combat_finished


func _on_card_button_pressed(card_button: Button) -> void:
	if combat_finished:
		return

	if not is_instance_valid(card_button):
		return

	var instance_id: int = int(card_button.get_meta("instance_id", -1))

	if instance_id == -1:
		push_warning("Botão de carta sem instance_id.")
		return

	var card_instance: Dictionary = find_card_in_hand(instance_id)

	if card_instance.is_empty():
		push_warning("Instância de carta não encontrada na mão: %d" % instance_id)
		return

	var card_id: String = str(card_instance["card_id"])

	if not DataLoader.has_card(card_id):
		push_warning("Carta não encontrada no banco: %s" % card_id)
		return

	var card_data: Dictionary = DataLoader.get_card(card_id)
	var cost: int = int(card_data["cost"])

	if not can_play_card(cost):
		update_ui()
		return

	play_card(card_instance, card_data)


func find_card_in_hand(instance_id: int) -> Dictionary:
	for card_instance in hand:
		if int(card_instance["instance_id"]) == instance_id:
			return card_instance

	return {}


func play_card(card_instance: Dictionary, card_data: Dictionary) -> void:
	var cost: int = int(card_data["cost"])

	energy -= cost

	print("Carta jogada: %s" % str(card_data["name"]))

	resolve_card_effects(card_data)
	move_card_from_hand_to_discard(int(card_instance["instance_id"]))

	if enemy_hp <= 0:
		end_combat_with_victory()

	rebuild_hand_ui()
	update_ui()


func can_play_card(cost: int) -> bool:
	if combat_finished:
		return false

	if energy < cost:
		print("Energia insuficiente.")
		return false

	return true


func move_card_from_hand_to_discard(instance_id: int) -> void:
	for i in range(hand.size()):
		var card_instance: Dictionary = hand[i]

		if int(card_instance["instance_id"]) == instance_id:
			var removed_card: Dictionary = hand.pop_at(i)
			discard_pile.append(removed_card)
			return

	push_warning("Não foi possível mover carta para descarte: %d" % instance_id)


func resolve_card_effects(card_data: Dictionary) -> void:
	var effects: Array = card_data["effects"]

	for effect in effects:
		resolve_effect(effect)


func resolve_effect(effect: Dictionary) -> void:
	var effect_type: String = str(effect["type"])
	var value: int = int(effect["value"])
	var target: String = str(effect["target"])

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


func _on_end_turn_pressed() -> void:
	if combat_finished:
		return

	discard_hand()
	resolve_enemy_turn()

	if combat_finished:
		rebuild_hand_ui()
		update_ui()
		return

	start_player_turn()
	rebuild_hand_ui()
	update_ui()


func discard_hand() -> void:
	for card_instance in hand:
		discard_pile.append(card_instance)

	hand.clear()

func load_enemy(enemy_id: String) -> void:
	if not DataLoader.has_enemy(enemy_id):
		push_error("Inimigo não encontrado: %s" % enemy_id)
		return

	current_enemy_id = enemy_id
	current_enemy_data = DataLoader.get_enemy(enemy_id)

	enemy_name = str(current_enemy_data["name"])
	enemy_max_hp = int(current_enemy_data["max_hp"])
	enemy_hp = enemy_max_hp

	select_enemy_intent()

func get_enemy_intent_text() -> String:
	if combat_finished:
		return "Combate encerrado"

	if enemy_intent.is_empty():
		return "Intenção: desconhecida"

	var effects: Array = enemy_intent.get("effects", [])

	if effects.is_empty():
		return "Intenção: nenhuma"

	var parts: Array[String] = []

	for effect in effects:
		var effect_type: String = str(effect["type"])
		var value: int = int(effect["value"])
		var target: String = str(effect["target"])

		if effect_type == "damage" and target == "player":
			parts.append("atacar causando %d de dano" % value)
		elif effect_type == "block" and target == "self":
			parts.append("defender ganhando %d de bloqueio" % value)
		else:
			parts.append("%s %d" % [effect_type, value])

	return "Intenção: " + ", ".join(parts)

func select_enemy_intent() -> void:
	if current_enemy_data.is_empty():
		enemy_intent = {}
		return

	var intent_pool: Array = current_enemy_data.get("intent_pool", [])

	if intent_pool.is_empty():
		enemy_intent = {}
		return

	enemy_intent = intent_pool[0]

func resolve_enemy_turn() -> void:
	print("Turno do inimigo.")

	if enemy_intent.is_empty():
		print("Inimigo não possui intenção.")
		return

	var effects: Array = enemy_intent.get("effects", [])

	for effect in effects:
		resolve_enemy_effect(effect)

	if player_hp <= 0:
		end_combat_with_defeat()

func resolve_enemy_effect(effect: Dictionary) -> void:
	var effect_type: String = str(effect["type"])
	var value: int = int(effect["value"])
	var target: String = str(effect["target"])

	match effect_type:
		"damage":
			if target == "player":
				apply_damage_to_player(value)

		_:
			push_warning("Tipo de efeito inimigo desconhecido: %s" % effect_type)
			
func apply_damage_to_player(amount: int) -> void:
	var blocked_damage: int = min(player_block, amount)
	var final_damage: int = amount - blocked_damage

	player_block -= blocked_damage
	player_hp -= final_damage
	player_hp = max(player_hp, 0)

	print("Bloqueado: %d. Dano recebido: %d." % [blocked_damage, final_damage])

func start_player_turn() -> void:
	print("Novo turno do jogador.")

	energy = max_energy
	player_block = 0

	select_enemy_intent()
	draw_cards(cards_per_turn)


func end_combat_with_victory() -> void:
	combat_finished = true
	print("Vitória! Inimigo derrotado.")


func end_combat_with_defeat() -> void:
	combat_finished = true
	print("Derrota. O capitão caiu.")
