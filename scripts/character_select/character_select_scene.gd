class_name CharacterSelectScene
extends Control

signal back_requested
signal expedition_started(style_id: String, prof_id: String, prof_rarity: String)

@onready var back_button: Button = $MainLayout/TopBar/BackButton
@onready var styles_list: HBoxContainer = $MainLayout/SplitContent/LeftColumn/StylesList
@onready var prof_list: HBoxContainer = $MainLayout/SplitContent/LeftColumn/ProfList
@onready var style_info_label: RichTextLabel = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/StyleInfoLabel
@onready var prof_info_label: RichTextLabel = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/ProfInfoLabel
@onready var deck_preview_label: RichTextLabel = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/DeckPreviewLabel
@onready var start_game_button: Button = $MainLayout/BottomBar/StartGameButton

var selected_style_id: String = "swordsman"
var selected_prof_id: String = "combatant"
const PLAYER_PROF_RARITY: String = "common"

var style_buttons: Dictionary = {}
var prof_buttons: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)

	rebuild_styles_ui()
	rebuild_professions_ui()
	update_preview_display()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_start_game_pressed() -> void:
	expedition_started.emit(selected_style_id, selected_prof_id, PLAYER_PROF_RARITY)


func rebuild_styles_ui() -> void:
	style_buttons.clear()
	for child in styles_list.get_children():
		child.queue_free()

	var styles: Dictionary = DataLoader.get_all_combat_styles()
	for sid in styles.keys():
		var data: Dictionary = styles[sid]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 95)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "%s\n\nHP: %d\nOuro: %d" % [
			data.get("name", sid),
			int(data.get("starting_hp", 70)),
			int(data.get("starting_gold", 0))
		]
		btn.pressed.connect(_on_style_selected.bind(sid))
		styles_list.add_child(btn)
		style_buttons[sid] = btn

	_refresh_button_highlights()


func rebuild_professions_ui() -> void:
	prof_buttons.clear()
	for child in prof_list.get_children():
		child.queue_free()

	var profs: Dictionary = DataLoader.get_all_professions()
	for pid in profs.keys():
		var data: Dictionary = profs[pid]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 95)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var passive_badge := "★ Com Passiva" if data.get("has_passive", false) else "⚔ +5 Cartas"
		btn.text = "%s\n\n%s" % [
			data.get("name", pid),
			passive_badge
		]
		btn.pressed.connect(_on_prof_selected.bind(pid))
		prof_list.add_child(btn)
		prof_buttons[pid] = btn

	_refresh_button_highlights()


func _on_style_selected(sid: String) -> void:
	selected_style_id = sid
	_refresh_button_highlights()
	update_preview_display()


func _on_prof_selected(pid: String) -> void:
	selected_prof_id = pid
	_refresh_button_highlights()
	update_preview_display()


func _refresh_button_highlights() -> void:
	for sid in style_buttons.keys():
		var btn: Button = style_buttons[sid]
		if sid == selected_style_id:
			btn.modulate = Color(1.3, 1.2, 0.8, 1.0)
		else:
			btn.modulate = Color(0.8, 0.8, 0.8, 0.8)

	for pid in prof_buttons.keys():
		var btn: Button = prof_buttons[pid]
		if pid == selected_prof_id:
			btn.modulate = Color(0.8, 1.3, 1.1, 1.0)
		else:
			btn.modulate = Color(0.8, 0.8, 0.8, 0.8)


func update_preview_display() -> void:
	var style_data: Dictionary = DataLoader.get_combat_style(selected_style_id)
	var prof_data: Dictionary = DataLoader.get_profession(selected_prof_id)

	# Exibição do Estilo de Combate
	var s_name: String = str(style_data.get("name", selected_style_id))
	var s_title: String = str(style_data.get("title", ""))
	var s_desc: String = str(style_data.get("description", ""))
	var s_hp: int = int(style_data.get("starting_hp", 70))
	var s_gold: int = int(style_data.get("starting_gold", 0))
	var s_food: int = int(style_data.get("starting_food", 5))

	style_info_label.text = "[color=#f0c040][b]Estilo: %s[/b] — %s[/color]\n[color=#b0b8c0]%s[/color]\n• [color=#70d080]HP Inicial:[/color] %d  |  • [color=#e0d050]Ouro:[/color] %d  |  • [color=#60b0ff]Provisões:[/color] %d" % [
		s_name, s_title, s_desc, s_hp, s_gold, s_food
	]

	# Exibição da Profissão
	var p_name: String = str(prof_data.get("name", selected_prof_id))
	var p_desc: String = str(prof_data.get("description", ""))
	var p_pname: String = str(prof_data.get("passive_name", ""))
	var p_pdesc: String = str(prof_data.get("passive_description", ""))

	var bonus_text := ""
	if selected_prof_id == "combatant":
		bonus_text = "[color=#ff7070][b]Arsenal de Combate:[/b] Adiciona 5 cartas comuns de ataque/defesa ao baralho inicial.[/color]"
	else:
		bonus_text = "[color=#70e0b0][b]Efeito de Raridade (Comum):[/b] Adiciona 1 carta comum temática ao baralho inicial.[/color]"

	prof_info_label.text = "[color=#50e0d0][b]Profissão: %s[/b] (Raridade do Capitão: Comum)[/color]\n[color=#b0b8c0]%s[/color]\n• [b]Passiva (%s):[/b] [i]%s[/i]\n• %s" % [
		p_name, p_desc, p_pname, p_pdesc, bonus_text
	]

	# Preview das cartas do baralho
	var starter_cards: Array = style_data.get("starter_deck", []).duplicate()
	var card_names: Array[String] = []
	for cid in starter_cards:
		var c_name := str(cid)
		if DataLoader.has_card(cid):
			c_name = DataLoader.get_card(cid).get("name", cid)
		card_names.append(c_name)

	var prof_pool: Dictionary = prof_data.get("card_pool", {})
	var common_pool: Array = prof_pool.get("common", [])
	var pool_names: Array[String] = []
	for cid in common_pool:
		var c_name := str(cid)
		if DataLoader.has_card(cid):
			c_name = DataLoader.get_card(cid).get("name", cid)
		pool_names.append(c_name)

	deck_preview_label.text = "[color=#f5d070][b]Baralho Base do Estilo (%d cartas):[/b][/color]\n%s\n\n[color=#70d0ff][b]Possíveis Cartas Iniciais da Profissão:[/b][/color]\n%s" % [
		card_names.size(),
		", ".join(card_names),
		", ".join(pool_names)
	]
