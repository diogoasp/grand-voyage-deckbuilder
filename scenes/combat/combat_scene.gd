extends Control

signal combat_victory
signal combat_defeat

const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/combat/CardView.tscn")
const CARD_SLOT_SIZE: Vector2 = Vector2(154, 220)

@onready var player_area: Control = $PlayerArea
@onready var player_placeholder: ColorRect = $PlayerArea/PlayerPlaceholder
@onready var player_status_container: HBoxContainer = $PlayerArea/PlayerStatusContainer

@onready var top_bar: HBoxContainer = $TopBar
@onready var player_hud: HBoxContainer = $TopBar/PlayerHUD
@onready var player_name_label: Label = $TopBar/PlayerHUD/PlayerNameLabel
@onready var player_hp_bar: ProgressBar = $TopBar/PlayerHUD/PlayerHPContainer/PlayerHPBar
@onready var player_hp_label: Label = $TopBar/PlayerHUD/PlayerHPContainer/PlayerHPBar/PlayerHPLabel
@onready var player_block_badge: Label = $TopBar/PlayerHUD/PlayerHPContainer/PlayerBlockBadge

@onready var crew_container: HBoxContainer = $TopBar/CrewContainer
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var bounty_label: Label = $TopBar/BountyLabel

@onready var energy_label: Label = $LeftHUD/EnergyContainer/EnergyVBox/EnergyLabel
@onready var draw_pile_label: Label = $LeftHUD/DeckContainer/DeckVBox/DrawPileLabel
@onready var discard_pile_label: Label = $RightHUD/DiscardContainer/DiscardVBox/DiscardPileLabel

@onready var enemy_area: VBoxContainer = $EnemyArea
@onready var enemy_intent_container: HBoxContainer = $EnemyArea/EnemyIntentContainer
@onready var enemy_name_label: Label = $EnemyArea/EnemyNameLabel
@onready var enemy_hp_label: Label = $EnemyArea/EnemyHPContainer/EnemyHPLabel
@onready var enemy_block_badge: Label = $EnemyArea/EnemyHPContainer/EnemyBlockBadge
@onready var enemy_status_container: HBoxContainer = $EnemyArea/EnemyStatusContainer
@onready var enemy_sprite: AnimatedSprite2D = $EnemyArea/EnemySprite

@onready var hand_area: HBoxContainer = $HandArea
@onready var end_turn_button: Button = $RightHUD/EndTurnButton

@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title_label: Label = $ResultPanel/ResultMargin/ResultVBox/ResultTitleLabel
@onready var result_body_label: Label = $ResultPanel/ResultMargin/ResultVBox/ResultBodyLabel
@onready var reward_title_label: Label = $ResultPanel/ResultMargin/ResultVBox/RewardTitleLabel
@onready var reward_cards_container: HBoxContainer = $ResultPanel/ResultMargin/ResultVBox/RewardCardsContainer
@onready var skip_reward_button: Button = $ResultPanel/ResultMargin/ResultVBox/SkipRewardButton
@onready var next_combat_button: Button = $ResultPanel/ResultMargin/ResultVBox/NextCombatButton


var player: Combatant
var enemy: Combatant
var effect_resolver: EffectResolver

var deck_manager: DeckManager
var combat_context: CombatContext

var reward_claimed: bool = false

var current_enemy_id: String = "marine_recruit"
var current_enemy_data: Dictionary = {}
var enemy_intent: Dictionary = {}

var cards_per_turn: int = 5
var max_energy: int = 3

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
	skip_reward_button.pressed.connect(_on_skip_reward_pressed)
	next_combat_button.pressed.connect(_on_next_combat_pressed)
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

	player.damage_taken.connect(_on_player_damage_taken)
	player.block_gained.connect(_on_player_block_gained)

	enemy.damage_taken.connect(_on_enemy_damage_taken)
	enemy.block_gained.connect(_on_enemy_block_gained)

	deck_manager = DeckManager.new()
	deck_manager.setup_from_deck_ids(GameState.current_deck)
	deck_manager.draw_cards(cards_per_turn)

	combat_context = CombatContext.new()
	combat_context.setup(
		player,
		enemy,
		deck_manager,
		max_energy
	)

	# Aplica efeitos passivos de Akuma no Mi no início do combate
	if GameState.eaten_fruit == "kiri_kiri_no_mi":
		player.gain_block(4)
		print("Passiva Akuma no Mi [Kiri Kiri no Mi]: Corpo de Névoa concedeu 4 de bloqueio inicial.")
	elif GameState.eaten_fruit == "goro_goro_no_mi":
		enemy.take_damage(4, true)
		print("Passiva Akuma no Mi [Goro Goro no Mi]: Descarga Estática causou 4 de dano de raio inicial.")

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
	player_hp_bar.max_value = player.max_hp
	player_hp_bar.value = player.hp

	if player.block > 0:
		player_block_badge.text = "🛡 %d" % player.block
		player_block_badge.visible = true
	else:
		player_block_badge.visible = false

	enemy_name_label.text = enemy.display_name
	enemy_hp_label.text = "HP: %s" % enemy.get_hp_text()

	if enemy.block > 0:
		enemy_block_badge.text = "🛡 %d" % enemy.block
		enemy_block_badge.visible = true
	else:
		enemy_block_badge.visible = false

	energy_label.text = "%d/%d" % [
		combat_context.energy,
		combat_context.max_energy
	]
	draw_pile_label.text = "🎴 Deck: %d" % deck_manager.get_draw_count()
	discard_pile_label.text = "🗑 Descarte: %d" % deck_manager.get_discard_count()
	gold_label.text = "Ouro: %d" % GameState.gold
	bounty_label.text = "Bounty: %d" % GameState.bounty

	update_enemy_intent_display()

	for card_view in get_card_views_in_hand():
		var can_play := not combat_finished and combat_context.can_spend_energy(card_view.cost)

		if can_play:
			card_view.modulate.a = 1.0
			card_view.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			card_view.modulate.a = 0.45
			card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_view.reset_visual_state()

	end_turn_button.disabled = combat_finished
	update_status_icons()
	update_crew_display()


func update_enemy_intent_display() -> void:
	if enemy_intent_container == null:
		return

	for child in enemy_intent_container.get_children():
		child.queue_free()

	if combat_finished:
		return

	if enemy_intent.is_empty():
		var label := Label.new()
		label.text = "❓"
		label.tooltip_text = "Intenção desconhecida"
		enemy_intent_container.add_child(label)
		return

	var effects: Array = enemy_intent.get("effects", [])
	if effects.is_empty():
		return

	for effect in effects:
		if not effect is Dictionary:
			continue

		var effect_type: String = str(effect.get("type", ""))
		var value: int = int(effect.get("value", 0))
		var target: String = str(effect.get("target", ""))

		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_PASS

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		badge.add_child(hbox)

		var icon_label := Label.new()
		var value_label := Label.new()
		hbox.add_child(icon_label)
		hbox.add_child(value_label)

		if effect_type == "damage" and target == "player":
			icon_label.text = "⚔"
			icon_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
			value_label.text = "%d" % value
			value_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
			badge.tooltip_text = "Intenção: Atacar causando %d de dano." % value
		elif effect_type == "block" and target == "self":
			icon_label.text = "🛡"
			icon_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
			value_label.text = "%d" % value
			value_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
			badge.tooltip_text = "Intenção: Defender ganhando %d de bloqueio." % value
		else:
			icon_label.text = "✦"
			icon_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
			value_label.text = "%s %d" % [effect_type, value]
			badge.tooltip_text = "Intenção: Aplicar %s (%d)." % [effect_type, value]

		enemy_intent_container.add_child(badge)


func update_status_icons() -> void:
	if player_status_container != null:
		for child in player_status_container.get_children():
			child.queue_free()

		if player != null and player.intangible > 0:
			var status_badge := PanelContainer.new()
			var label := Label.new()
			label.text = "☁ Névoa (%d)" % player.intangible
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			status_badge.add_child(label)
			status_badge.tooltip_text = "Intangibilidade (Forma de Névoa): Dano recebido reduzido a no máximo 1 por %d turno(s)." % player.intangible
			player_status_container.add_child(status_badge)

		if player != null and player.weakness > 0:
			var weak_badge := PanelContainer.new()
			var label := Label.new()
			label.text = "💔 Fraco (%d)" % player.weakness
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
			weak_badge.add_child(label)
			weak_badge.tooltip_text = "Fraqueza: Dano causado reduzido em 25%% por %d turno(s)." % player.weakness
			player_status_container.add_child(weak_badge)

	if enemy_status_container != null:
		for child in enemy_status_container.get_children():
			child.queue_free()

		if enemy != null and enemy.weakness > 0:
			var enemy_weak_badge := PanelContainer.new()
			var label := Label.new()
			label.text = "💔 Fraco (%d)" % enemy.weakness
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
			enemy_weak_badge.add_child(label)
			enemy_weak_badge.tooltip_text = "Fraqueza: Dano causado reduzido em 25%% por %d turno(s)." % enemy.weakness
			enemy_status_container.add_child(enemy_weak_badge)


func update_crew_display() -> void:
	if crew_container == null:
		return

	for child in crew_container.get_children():
		child.queue_free()

	if GameState.crew_members.is_empty():
		return

	for crew_id in GameState.crew_members:
		if not DataLoader.has_crew(crew_id):
			continue

		var crew_data: Dictionary = DataLoader.get_crew(crew_id)
		var crew_widget := create_crew_icon_widget(crew_data)
		crew_container.add_child(crew_widget)


func create_crew_icon_widget(crew_data: Dictionary) -> Control:
	var crew_name: String = str(crew_data.get("name", "Tripulante"))
	var role: String = str(crew_data.get("role", "Aventureiro"))
	var rarity: String = str(crew_data.get("rarity", "common")).to_lower()
	var face_path: String = str(crew_data.get("face_path", ""))
	var passive_desc: String = str(crew_data.get("passive_description", ""))

	var role_lower := role.to_lower()
	if "combatente" in role_lower or role_lower == "combatant":
		passive_desc = "Adiciona 5 cartas ao baralho."
	elif passive_desc == "":
		passive_desc = str(crew_data.get("description", "Membro valioso da tripulação."))

	var border_color := Color(0.35, 0.42, 0.52) # Comum
	var rarity_name := "Comum"
	match rarity:
		"uncommon":
			border_color = Color(0.2, 0.7, 0.85) # Azul turquesa
			rarity_name = "Incomum"
		"rare":
			border_color = Color(0.85, 0.4, 0.95) # Roxo místico
			rarity_name = "Raro"
		"legendary":
			border_color = Color(0.95, 0.8, 0.25) # Dourado lendário
			rarity_name = "Lendário"

	var role_icon := "⚓"
	match role_lower:
		"médico", "medico", "doctor":
			role_icon = "💉"
		"cozinheiro", "chef":
			role_icon = "🍖"
		"navegador", "navigator":
			role_icon = "🧭"
		"combatente", "combatant":
			role_icon = "⚔"
		"carpinteiro", "carpenter":
			role_icon = "🔨"
		"atirador", "sniper":
			role_icon = "🎯"

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(30, 30)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.15, 0.2, 0.95)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = border_color
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_right = 6
	stylebox.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", stylebox)

	var has_valid_face := false
	if face_path != "" and ResourceLoader.exists(face_path):
		var face_tex: Texture2D = load(face_path)
		if face_tex != null:
			var tex_rect := TextureRect.new()
			tex_rect.texture = face_tex
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(26, 26)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			panel.add_child(tex_rect)
			has_valid_face = true

	if not has_valid_face:
		var icon_lbl := Label.new()
		icon_lbl.text = role_icon
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 16)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(icon_lbl)

	panel.tooltip_text = "[ %s ]\nProfissão: %s\nRaridade: %s\nHabilidade: %s" % [
		crew_name,
		role,
		rarity_name,
		passive_desc
	]

	return panel


func get_card_views_in_hand() -> Array[CardView]:
	var card_views: Array[CardView] = []

	for slot in hand_area.get_children():
		for child in slot.get_children():
			if child is CardView:
				card_views.append(child)

	return card_views




func _on_card_play_requested(card_view: CardView, _drop_position: Vector2) -> void:
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

	combat_context.spend_energy(cost)

	print("Carta jogada: %s" % str(card_data["name"]))

	trigger_crew_assist_visual(str(card_data.get("id", "")))
	resolve_card_effects(card_data)
	deck_manager.move_card_from_hand_to_discard(card_instance.instance_id)

	if enemy.is_defeated():
		end_combat_with_victory()

	rebuild_hand_ui()
	update_ui()


func trigger_crew_assist_visual(card_id: String) -> void:
	if card_id == "":
		return

	# Procura se algum tripulante recrutado possui esta carta associada
	var matching_crew: Dictionary = {}
	for crew_id in GameState.crew_members:
		if not DataLoader.has_crew(crew_id):
			continue
		var cdata: Dictionary = DataLoader.get_crew(crew_id)
		var associated: Array = cdata.get("associated_cards", [])
		if associated.has(card_id):
			matching_crew = cdata
			break

	if matching_crew.is_empty():
		return

	var combat_path: String = str(matching_crew.get("combat_path", ""))
	if combat_path == "" or not ResourceLoader.exists(combat_path):
		return

	var tex: Texture2D = load(combat_path)
	if tex == null:
		return

	# Cria o sprite/TextureRect do aliado ao lado do jogador
	var assist_rect := TextureRect.new()
	assist_rect.texture = tex
	assist_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	assist_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Dimensões adequadas para o espaço de combate (ex: 180x225)
	assist_rect.custom_minimum_size = Vector2(180, 225)
	assist_rect.size = Vector2(180, 225)
	assist_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Posição inicial: ao lado da PlayerArea, deslizando da esquerda para a direita
	var target_pos := Vector2(player_area.position.x + 130.0, player_area.position.y - 10.0)
	var start_pos := target_pos + Vector2(-60.0, 0.0)
	var exit_pos := target_pos + Vector2(40.0, 0.0)

	assist_rect.position = start_pos
	assist_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(assist_rect)

	var tween := create_tween()
	# Desliza para dentro e surge
	tween.tween_property(assist_rect, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(assist_rect, "modulate:a", 1.0, 0.2)
	# Permanece brevemente em ação
	tween.tween_interval(0.4)
	# Desliza e desaparece
	tween.tween_property(assist_rect, "position", exit_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(assist_rect, "modulate:a", 0.0, 0.25)
	tween.tween_callback(assist_rect.queue_free)


func can_play_card(cost: int) -> bool:
	if combat_finished:
		return false

	if not combat_context.can_spend_energy(cost):
		print("Energia insuficiente.")
		return false

	return true

func resolve_card_effects(card_data: Dictionary) -> void:
	var effects: Array = card_data.get("effects", [])
	var results: Array[Dictionary] = effect_resolver.resolve_effects(
		effects,
		combat_context,
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

	enemy.clear_block()
	enemy.tick_turn_statuses()

	if enemy_intent.is_empty():
		print("Inimigo não possui intenção.")
		return

	var effects: Array = enemy_intent.get("effects", [])
	var results: Array[Dictionary] = effect_resolver.resolve_effects(
		effects,
		combat_context,
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

	combat_context.reset_energy()
	player.clear_block()
	player.tick_turn_statuses()

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

	if victory:
		next_combat_button.text = "Continuar Viagem"
		setup_victory_card_rewards()
	else:
		next_combat_button.text = "Fim da Expedição"
		reward_title_label.visible = false
		reward_cards_container.visible = false
		skip_reward_button.visible = false
		next_combat_button.visible = true

	result_panel.visible = true
	update_ui()


func setup_victory_card_rewards() -> void:
	for child in reward_cards_container.get_children():
		child.queue_free()

	var reward_candidates: Array[String] = get_combat_card_reward_pool()
	reward_candidates.shuffle()

	var chosen_rewards: Array[String] = []
	for i in range(mini(3, reward_candidates.size())):
		chosen_rewards.append(reward_candidates[i])

	if chosen_rewards.is_empty():
		reward_title_label.visible = false
		reward_cards_container.visible = false
		skip_reward_button.visible = false
		next_combat_button.visible = true
		return

	reward_title_label.visible = true
	reward_cards_container.visible = true
	skip_reward_button.visible = true
	next_combat_button.visible = false

	for card_id in chosen_rewards:
		var card_data: Dictionary = DataLoader.get_card(card_id)
		if card_data.is_empty():
			continue

		var card_button := Button.new()
		card_button.custom_minimum_size = Vector2(150, 215)
		var c_name: String = str(card_data.get("name", card_id))
		var c_cost: int = int(card_data.get("cost", 0))
		var c_desc: String = str(card_data.get("description", ""))
		var c_type: String = str(card_data.get("type", "carta")).to_upper()
		card_button.text = "🔷 %d  |  [%s]\n\n%s\n\n%s" % [c_cost, c_type, c_name, c_desc]
		card_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_button.pressed.connect(_on_reward_card_chosen.bind(card_id))
		reward_cards_container.add_child(card_button)


func get_combat_card_reward_pool() -> Array[String]:
	var pool: Array[String] = []
	var all_cards: Array[String] = DataLoader.get_all_card_ids()

	for cid in all_cards:
		var data: Dictionary = DataLoader.get_card(cid)
		var source: String = str(data.get("source", ""))
		# Only offer combat drops, training techniques, or starter basics as rewards
		if source in ["combat_reward", "training", "starter_deck"]:
			pool.append(cid)
		elif source == "milestone_reward" and MetaProgression.is_card_unlocked(cid):
			pool.append(cid)

	return pool


func _on_reward_card_chosen(card_id: String) -> void:
	GameState.add_card_to_deck(card_id)
	var card_data: Dictionary = DataLoader.get_card(card_id)
	var card_name: String = str(card_data.get("name", card_id))

	reward_title_label.text = "✓ %s adicionado ao seu deck!" % card_name
	reward_cards_container.visible = false
	skip_reward_button.visible = false
	next_combat_button.visible = true


func _on_skip_reward_pressed() -> void:
	reward_title_label.text = "Recompensa de carta pulada."
	reward_cards_container.visible = false
	skip_reward_button.visible = false
	next_combat_button.visible = true


func _on_next_combat_pressed() -> void:
	if player != null and player.is_defeated():
		combat_defeat.emit()
	else:
		combat_victory.emit()


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
			
func is_position_inside_control(target_position: Vector2, control: Control) -> bool:
	var rect := Rect2(control.global_position, control.size)
	return rect.has_point(target_position)

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


func _on_enemy_damage_taken(result: Dictionary) -> void:
	var final_damage: int = int(result.get("final_damage", 0))
	var blocked_damage: int = int(result.get("blocked_damage", 0))

	if final_damage > 0:
		spawn_floating_text(enemy_area, "-%d" % final_damage, Color(1.0, 0.25, 0.25))
		flash_target(enemy_area, Color(1.8, 0.3, 0.3, 1.0))
		shake_target(enemy_area, 6.0)
	elif blocked_damage > 0:
		spawn_floating_text(enemy_area, "Bloqueado! (%d)" % blocked_damage, Color(0.3, 0.7, 1.0))
		flash_target(enemy_area, Color(0.5, 0.8, 1.5, 1.0))


func _on_player_damage_taken(result: Dictionary) -> void:
	var final_damage: int = int(result.get("final_damage", 0))
	var blocked_damage: int = int(result.get("blocked_damage", 0))
	var was_intangible: bool = bool(result.get("was_intangible", false))

	if was_intangible:
		spawn_floating_text(player_area, "☁ Névoa (-%d)" % final_damage, Color(0.6, 0.9, 1.0))
		flash_target(player_area, Color(0.5, 0.9, 1.5, 1.0))
		shake_target(player_area, 3.0)
	elif final_damage > 0:
		spawn_floating_text(player_area, "-%d" % final_damage, Color(1.0, 0.2, 0.2))
		flash_target(player_area, Color(1.8, 0.2, 0.2, 1.0))
		shake_target(player_area, 8.0)
	elif blocked_damage > 0:
		spawn_floating_text(player_area, "Bloqueado! (%d)" % blocked_damage, Color(0.3, 0.7, 1.0))
		flash_target(player_area, Color(0.5, 0.8, 1.5, 1.0))


func _on_player_block_gained(amount: int) -> void:
	spawn_floating_text(player_area, "+%d Bloqueio" % amount, Color(0.4, 0.8, 1.0))


func _on_enemy_block_gained(amount: int) -> void:
	spawn_floating_text(enemy_area, "+%d Bloqueio" % amount, Color(0.4, 0.8, 1.0))


func flash_target(target: Control, flash_color: Color) -> void:
	if not is_instance_valid(target):
		return
	var tween := create_tween()
	target.modulate = flash_color
	tween.tween_property(target, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func shake_target(target: Control, intensity: float = 6.0) -> void:
	if not is_instance_valid(target):
		return
	var orig_pos := target.position
	var tween := create_tween()
	tween.tween_property(target, "position", orig_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.04)
	tween.tween_property(target, "position", orig_pos + Vector2(randf_range(-intensity * 0.6, intensity * 0.6), randf_range(-intensity * 0.6, intensity * 0.6)), 0.04)
	tween.tween_property(target, "position", orig_pos, 0.05)


func spawn_floating_text(parent_target: Control, text: String, color: Color) -> void:
	if not is_instance_valid(parent_target):
		return

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.top_level = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var spawn_pos: Vector2 = parent_target.global_position + Vector2(parent_target.size.x * 0.35, 10.0)
	label.global_position = spawn_pos
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", spawn_pos.y - 45.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(label.queue_free)
