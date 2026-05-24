extends Control
const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/combat/CardView.tscn")
const CARD_SLOT_SIZE: Vector2 = Vector2(130, 190)

@onready var player_area: Control = $PlayerArea
@onready var player_name_label: Label = $PlayerArea/PlayerNameLabel
@onready var player_hp_label: Label = $TopBar/PlayerHPLabel

@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var block_label: Label = $TopBar/BlockLabel

@onready var draw_pile_label: Label = $TopBar/DrawPileLabel
@onready var discard_pile_label: Label = $TopBar/DiscardPileLabel

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var bounty_label: Label = $TopBar/BountyLabel

@onready var enemy_hp_label: Label = $TopBar/EnemyHPLabel
@onready var enemy_area: VBoxContainer = $EnemyArea
@onready var enemy_name_label: Label = $EnemyArea/EnemyNameLabel
@onready var enemy_intent_label: Label = $EnemyArea/EnemyIntentLabel

@onready var hand_area: HBoxContainer = $HandArea
@onready var end_turn_button: Button = $EndTurnButton

@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title_label: Label = $ResultPanel/ResultVBox/ResultTitleLabel
@onready var result_body_label: Label = $ResultPanel/ResultVBox/ResultBodyLabel
@onready var next_combat_button: Button = $ResultPanel/ResultVBox/NextCombatButton
@onready var reset_run_button: Button = $ResultPanel/ResultVBox/ResetRunButton


var player: Combatant
var enemy: Combatant
var effect_resolver: EffectResolver

var deck_manager: DeckManager

var reward_claimed: bool = false

var current_enemy_id: String = "marine_recruit"
var current_enemy_data: Dictionary = {}
var enemy_intent: Dictionary = {}

var energy: int = 3
var max_energy: int = 3
var cards_per_turn: int = 5

var combat_finished: bool = false

var dragged_card_view: CardView = null
var dragged_card_required_target: String = ""

var starting_deck_ids: Array[String] = [
	"strike_basic",
	"strike_basic",
	"strike_basic",
	"defend_basic",
	"defend_basic",
	"defend_basic"
]

func _ready() -> void:
	randomize()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	next_combat_button.pressed.connect(_on_next_combat_pressed)
	reset_run_button.pressed.connect(_on_reset_run_pressed)
	start_combat()

func start_combat_against(enemy_id: String) -> void:
	current_enemy_id = enemy_id
	start_combat()

func start_combat() -> void:
	result_panel.visible = false

	combat_finished = false
	reward_claimed = false

	player = Combatant.new()
	player.setup("player", "Capitão", GameState.player_max_hp)
	player.hp = GameState.player_hp

	effect_resolver = EffectResolver.new()

	load_enemy(current_enemy_id)

	energy = max_energy

	deck_manager = DeckManager.new()
	deck_manager.setup_from_deck_ids(GameState.current_deck)
	deck_manager.draw_cards(cards_per_turn)

	rebuild_hand_ui()
	update_ui()

	print("Combate iniciado.")


func load_enemy(enemy_id: String) -> void:
	if not DataLoader.has_enemy(enemy_id):
		push_error("Inimigo não encontrado: %s" % enemy_id)
		return

	current_enemy_id = enemy_id
	current_enemy_data = DataLoader.get_enemy(enemy_id)

	var enemy_name: String = str(current_enemy_data["name"])
	var enemy_max_hp: int = int(current_enemy_data["max_hp"])

	enemy = Combatant.new()
	enemy.setup(enemy_id, enemy_name, enemy_max_hp)

	select_enemy_intent()


func select_enemy_intent() -> void:
	if current_enemy_data.is_empty():
		enemy_intent = {}
		return

	var intent_pool: Array = current_enemy_data.get("intent_pool", [])

	if intent_pool.is_empty():
		enemy_intent = {}
		return

	enemy_intent = pick_weighted_intent(intent_pool)

func pick_weighted_intent(intent_pool: Array) -> Dictionary:
	var total_weight: int = 0

	for intent in intent_pool:
		if not intent is Dictionary:
			continue

		total_weight += max(int(intent.get("weight", 0)), 0)

	if total_weight <= 0:
		push_warning("Intent pool sem pesos válidos.")
		return {}

	var roll: int = randi_range(1, total_weight)
	var accumulated_weight: int = 0

	for intent in intent_pool:
		if not intent is Dictionary:
			continue

		accumulated_weight += max(int(intent.get("weight", 0)), 0)

		if roll <= accumulated_weight:
			return intent

	return {}


func rebuild_hand_ui() -> void:
	clear_hand_ui()

	for card_instance in deck_manager.hand:
		if card_instance == null or not card_instance.is_valid():
			push_warning("Instância de carta inválida na mão.")
			continue

		var card_id: String = card_instance.card_id

		if not DataLoader.has_card(card_id):
			push_warning("Carta ausente do banco: %s" % card_id)
			continue

		var card_data: Dictionary = DataLoader.get_card(card_id)

		var card_slot := Control.new()
		card_slot.custom_minimum_size = CARD_SLOT_SIZE
		card_slot.size = CARD_SLOT_SIZE
		card_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		hand_area.add_child(card_slot)

		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		card_slot.add_child(card_view)

		card_view.position = Vector2.ZERO
		card_view.setup(card_instance, card_data)
		card_view.card_drag_started.connect(_on_card_drag_started)
		card_view.card_drag_ended.connect(_on_card_drag_ended)
		card_view.card_play_requested.connect(_on_card_play_requested)


func clear_hand_ui() -> void:
	for child in hand_area.get_children():
		child.queue_free()

func update_ui() -> void:
	player_name_label.text = player.display_name
	player_hp_label.text = "HP: %s" % player.get_hp_text()
	enemy_hp_label.text = "Inimigo: %s | Bloqueio: %d" % [
		enemy.get_hp_text(),
		enemy.block
	]
	energy_label.text = "Energia: %d/%d" % [energy, max_energy]
	block_label.text = "Bloqueio: %d" % player.block
	draw_pile_label.text = "Deck: %d" % deck_manager.get_draw_count()
	discard_pile_label.text = "Descarte: %d" % deck_manager.get_discard_count()
	gold_label.text = "Ouro: %d" % GameState.gold
	bounty_label.text = "Bounty: %d" % GameState.bounty

	enemy_name_label.text = enemy.display_name
	enemy_intent_label.text = get_enemy_intent_text()

	for card_view in get_card_views_in_hand():
		var can_play := not combat_finished and energy >= card_view.cost

		if can_play:
			card_view.modulate.a = 1.0
			card_view.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			card_view.modulate.a = 0.45
			card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_view.reset_visual_state()

	end_turn_button.disabled = combat_finished

func get_card_views_in_hand() -> Array[CardView]:
	var card_views: Array[CardView] = []

	for slot in hand_area.get_children():
		for child in slot.get_children():
			if child is CardView:
				card_views.append(child)

	return card_views

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


func _on_card_play_requested(card_view: CardView, drop_position: Vector2) -> void:
	if combat_finished:
		card_view.return_to_original_position()
		return

	if not is_instance_valid(card_view):
		return

	var instance_id: int = card_view.instance_id

	if instance_id == -1:
		push_warning("CardView sem instance_id.")
		card_view.return_to_original_position()
		return

	var card_instance: CardInstance = deck_manager.find_card_in_hand(instance_id)

	if card_instance == null:
		push_warning("Instância de carta não encontrada na mão: %d" % instance_id)
		card_view.return_to_original_position()
		return

	var card_id: String = card_instance.card_id

	if not DataLoader.has_card(card_id):
		push_warning("Carta não encontrada no banco: %s" % card_id)
		card_view.return_to_original_position()
		return

	var card_data: Dictionary = DataLoader.get_card(card_id)
	var cost: int = int(card_data["cost"])

	if not can_play_card(cost):
		card_view.return_to_original_position()
		update_ui()
		return

	var required_target: String = get_required_drop_target(card_data)

	if not is_card_over_valid_target(card_view, required_target):
		print("Alvo inválido para carta: %s" % str(card_data["name"]))
		card_view.return_to_original_position()
		return

	play_card(card_instance, card_data)


func play_card(card_instance: CardInstance, card_data: Dictionary) -> void:
	var cost: int = int(card_data["cost"])

	energy -= cost

	print("Carta jogada: %s" % str(card_data["name"]))

	resolve_card_effects(card_data)
	deck_manager.move_card_from_hand_to_discard(card_instance.instance_id)

	if enemy.is_defeated():
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


func resolve_card_effects(card_data: Dictionary) -> void:
	var effects: Array = card_data.get("effects", [])
	var results: Array[Dictionary] = effect_resolver.resolve_effects(
		effects,
		player,
		enemy,
		"card"
	)

	print_effect_results(results)

func _on_end_turn_pressed() -> void:
	if combat_finished:
		return

	deck_manager.discard_hand()
	resolve_enemy_turn()

	if combat_finished:
		rebuild_hand_ui()
		update_ui()
		return

	start_player_turn()
	rebuild_hand_ui()
	update_ui()


func resolve_enemy_turn() -> void:
	print("Turno do inimigo.")

	if enemy_intent.is_empty():
		print("Inimigo não possui intenção.")
		return

	var effects: Array = enemy_intent.get("effects", [])
	var results: Array[Dictionary] = effect_resolver.resolve_effects(
		effects,
		player,
		enemy,
		"enemy_intent"
	)

	print_effect_results(results)

	if player.is_defeated():
		end_combat_with_defeat()

func print_effect_results(results: Array[Dictionary]) -> void:
	for result in results:
		var message: String = str(result.get("message", ""))

		if message == "":
			continue

		if bool(result.get("success", true)):
			print(message)
		else:
			push_warning(message)

func start_player_turn() -> void:
	print("Novo turno do jogador.")

	energy = max_energy
	player.clear_block()

	select_enemy_intent()
	deck_manager.draw_cards(cards_per_turn)


func end_combat_with_victory() -> void:
	if combat_finished:
		return

	combat_finished = true
	GameState.set_player_hp(player.hp)

	var reward_text: String = claim_combat_rewards()

	print("Vitória! Inimigo derrotado.")

	show_result_panel(
		"Vitória!",
		"%s\n\nHP restante: %d/%d\nOuro total: %d\nBounty total: %d" % [
			reward_text,
			GameState.player_hp,
			GameState.player_max_hp,
			GameState.gold,
			GameState.bounty
		],
		true
	)


func end_combat_with_defeat() -> void:
	if combat_finished:
		return

	combat_finished = true
	GameState.set_player_hp(player.hp)

	print("Derrota. O capitão caiu.")

	show_result_panel(
		"Derrota",
		"O capitão caiu.\nA run terminou.",
		false
	)
	
func claim_combat_rewards() -> String:
	if reward_claimed:
		return ""

	reward_claimed = true

	var rewards: Dictionary = current_enemy_data.get("rewards", {})

	if rewards.is_empty():
		return "Nenhuma recompensa definida."

	var gold_min: int = int(rewards.get("gold_min", 0))
	var gold_max: int = int(rewards.get("gold_max", gold_min))
	var bounty_reward: int = int(rewards.get("bounty", 0))

	if gold_max < gold_min:
		gold_max = gold_min

	var gold_reward: int = randi_range(gold_min, gold_max)

	GameState.gain_gold(gold_reward)
	GameState.gain_bounty(bounty_reward)

	var message := "Recompensas recebidas:\n%d ouro\n%d bounty" % [
		gold_reward,
		bounty_reward
	]

	print(message)
	print("Total atual: %d ouro, %d bounty." % [
		GameState.gold,
		GameState.bounty
	])

	return message
	
func show_result_panel(title: String, body: String, victory: bool) -> void:
	result_title_label.text = title
	result_body_label.text = body

	next_combat_button.visible = victory
	reset_run_button.visible = true

	result_panel.visible = true
	update_ui()
	
func _on_next_combat_pressed() -> void:
	var next_enemy_id := pick_next_test_enemy_id()
	start_combat_against(next_enemy_id)


func _on_reset_run_pressed() -> void:
	GameState.reset_run()
	start_combat_against("marine_recruit")
	
func pick_next_test_enemy_id() -> String:
	if current_enemy_id == "marine_recruit":
		return "bandit_sailor"

	return "marine_recruit"
	
func get_required_drop_target(card_data: Dictionary) -> String:
	var effects: Array = card_data.get("effects", [])

	for effect in effects:
		if not effect is Dictionary:
			continue

		var target: String = str(effect.get("target", ""))

		if target == "enemy":
			return "enemy"

		if target == "player":
			return "player"

	return "none"
	
func is_card_over_valid_target(card_view: CardView, required_target: String) -> bool:
	match required_target:
		"enemy":
			return is_card_over_control(card_view, enemy_area, Vector2(80, 80))

		"player":
			return is_card_over_control(card_view, player_area, Vector2(80, 80))

		"none":
			return true

		_:
			return false

func is_card_over_control(card_view: CardView, control: Control, padding: Vector2 = Vector2.ZERO) -> bool:
	var card_rect := Rect2(card_view.global_position, card_view.size)

	var target_rect := Rect2(control.global_position, control.size)
	target_rect.position -= padding
	target_rect.size += padding * 2.0

	return card_rect.intersects(target_rect)
			
func is_position_inside_control(position: Vector2, control: Control) -> bool:
	var rect := Rect2(control.global_position, control.size)
	return rect.has_point(position)

func _on_card_drag_started(card_view: CardView) -> void:
	dragged_card_view = card_view

	var card_data: Dictionary = DataLoader.get_card(card_view.card_id)
	dragged_card_required_target = get_required_drop_target(card_data)

	highlight_target_area(dragged_card_required_target)


func _on_card_drag_ended(_card_view: CardView) -> void:
	dragged_card_view = null
	dragged_card_required_target = ""
	clear_target_highlights()
	
func highlight_target_area(required_target: String) -> void:
	clear_target_highlights()

	match required_target:
		"enemy":
			enemy_area.modulate = Color(1.12, 1.12, 1.12, 1.0)

		"player":
			player_area.modulate = Color(1.12, 1.12, 1.12, 1.0)

		"none":
			enemy_area.modulate = Color(1.12, 1.12, 1.12, 1.0)
			player_area.modulate = Color(1.12, 1.12, 1.12, 1.0)


func clear_target_highlights() -> void:
	enemy_area.modulate = Color(1, 1, 1, 1)
	player_area.modulate = Color(1, 1, 1, 1)

func _process(_delta: float) -> void:
	if dragged_card_view == null:
		return

	if not is_instance_valid(dragged_card_view):
		return

	update_drag_target_feedback()
	
func update_drag_target_feedback() -> void:
	clear_target_highlights()

	if dragged_card_required_target == "":
		return

	var is_valid_target := is_card_over_valid_target(
		dragged_card_view,
		dragged_card_required_target
	)

	match dragged_card_required_target:
		"enemy":
			if is_valid_target:
				enemy_area.modulate = Color(1.35, 1.35, 1.35, 1.0)
			else:
				enemy_area.modulate = Color(1.12, 1.12, 1.12, 1.0)

		"player":
			if is_valid_target:
				player_area.modulate = Color(1.35, 1.35, 1.35, 1.0)
			else:
				player_area.modulate = Color(1.12, 1.12, 1.12, 1.0)

		"none":
			enemy_area.modulate = Color(1.12, 1.12, 1.12, 1.0)
			player_area.modulate = Color(1.12, 1.12, 1.12, 1.0)
