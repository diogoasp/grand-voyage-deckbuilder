class_name CharacterSelectScene
extends Control

signal back_requested
signal expedition_started(style_id: String, prof_id: String, prof_rarity: String, gender: String)

const REMOVE_WHITE_BG_SHADER: Shader = preload("res://shaders/remove_white_bg.gdshader")

@onready var back_button: Button = $MainLayout/TopBar/BackButton
@onready var male_button: Button = $MainLayout/TopBar/GenderContainer/MaleButton
@onready var female_button: Button = $MainLayout/TopBar/GenderContainer/FemaleButton
@onready var styles_list: HBoxContainer = $MainLayout/SplitContent/LeftColumn/StylesList
@onready var prof_list: HBoxContainer = $MainLayout/SplitContent/LeftColumn/ProfList
@onready var character_portrait: TextureRect = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/CharacterPortrait
@onready var style_info_label: RichTextLabel = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/StyleInfoLabel
@onready var prof_info_label: RichTextLabel = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/ProfInfoLabel
@onready var deck_preview_label: RichTextLabel = $MainLayout/SplitContent/RightColumn/SummaryPanel/Margin/Scroll/SummaryVBox/DeckPreviewLabel
@onready var start_game_button: Button = $MainLayout/BottomBar/StartGameButton

var selected_gender: String = "male"
var selected_style_id: String = "swordsman"
var selected_prof_id: String = "combatant"
const PLAYER_PROF_RARITY: String = "common"

var style_buttons: Dictionary = {}
var prof_buttons: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	male_button.pressed.connect(_on_gender_selected.bind("male"))
	female_button.pressed.connect(_on_gender_selected.bind("female"))
	start_game_button.pressed.connect(_on_start_game_pressed)

	rebuild_styles_ui()
	rebuild_professions_ui()
	update_preview_display()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_gender_selected(gender: String) -> void:
	selected_gender = gender
	_refresh_button_highlights()
	update_preview_display()


func _on_start_game_pressed() -> void:
	var prof_rarity: String = MetaProgression.get_profession_rarity(selected_prof_id)
	expedition_started.emit(selected_style_id, selected_prof_id, prof_rarity, selected_gender)


func rebuild_styles_ui() -> void:
	style_buttons.clear()
	for child in styles_list.get_children():
		child.queue_free()

	var styles: Dictionary = DataLoader.get_all_combat_styles()
	for sid in styles.keys():
		var data: Dictionary = styles[sid]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 105)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var mastery_lvl: int = MetaProgression.get_style_mastery_level(sid)
		var style_pts: int = MetaProgression.get_style_infamy(sid)

		btn.text = "%s\n[Nv. %d Maestria]\n(%d Infâmia)\n\nHP: %d | Ouro: %d" % [
			data.get("name", sid),
			mastery_lvl,
			style_pts,
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
		btn.custom_minimum_size = Vector2(130, 105)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var rarity_str: String = MetaProgression.get_profession_rarity(pid).capitalize()
		var prof_pts: int = MetaProgression.get_profession_infamy(pid)

		btn.text = "%s\n[%s]\n(%d Infâmia)\n\n%s" % [
			data.get("name", pid),
			rarity_str,
			prof_pts,
			"★ Com Passiva" if data.get("has_passive", false) else "⚔ +5 Cartas"
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
	if male_button != null:
		male_button.modulate = Color(1.3, 1.2, 0.8, 1.0) if selected_gender == "male" else Color(0.8, 0.8, 0.8, 0.8)
	if female_button != null:
		female_button.modulate = Color(1.3, 1.2, 0.8, 1.0) if selected_gender == "female" else Color(0.8, 0.8, 0.8, 0.8)

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
	var portrait_path := "res://assets/art/main_char/%s/base.png" % selected_gender
	if ResourceLoader.exists(portrait_path):
		var tex: Texture2D = load(portrait_path)
		character_portrait.texture = tex
		if character_portrait.material == null:
			var mat := ShaderMaterial.new()
			mat.shader = REMOVE_WHITE_BG_SHADER
			mat.set_shader_parameter("threshold", 0.94)
			mat.set_shader_parameter("softness", 0.04)
			character_portrait.material = mat
		character_portrait.visible = true
	else:
		character_portrait.visible = false

	var style_data: Dictionary = DataLoader.get_combat_style(selected_style_id)
	var prof_data: Dictionary = DataLoader.get_profession(selected_prof_id)

	# Exibição do Estilo de Combate com Maestria
	var s_name: String = str(style_data.get("name", selected_style_id))
	var s_title: String = str(style_data.get("title", ""))
	var s_desc: String = str(style_data.get("description", ""))
	var s_hp: int = int(style_data.get("starting_hp", 70))
	var s_gold: int = int(style_data.get("starting_gold", 0))
	var s_food: int = int(style_data.get("starting_food", 5))

	var style_lvl: int = MetaProgression.get_style_mastery_level(selected_style_id)
	var style_next_info: Dictionary = MetaProgression.get_next_style_level_info(selected_style_id)
	var style_prog_str := ""
	if style_next_info.get("is_max", false):
		style_prog_str = "[color=#f0c040]★ Maestria Máxima (Nível %d)[/color]" % style_lvl
	else:
		style_prog_str = "Nível %d ([color=#70d0ff]%d/%d Infâmia[/color] p/ Nv. %d: [i]%s[/i])" % [
			style_lvl,
			style_next_info.get("current_infamy", 0),
			style_next_info.get("required_infamy", 0),
			style_next_info.get("next_level", 2),
			style_next_info.get("desc", "")
		]

	style_info_label.text = "[color=#f0c040][b]Estilo: %s[/b] — %s[/color]\n[color=#b0b8c0]%s[/color]\n• [b]Maestria:[/b] %s\n• [color=#70d080]HP Inicial:[/color] %d  |  • [color=#e0d050]Ouro:[/color] %d  |  • [color=#60b0ff]Provisões:[/color] %d" % [
		s_name, s_title, s_desc, style_prog_str, s_hp, s_gold, s_food
	]

	# Exibição da Profissão com Raridade Dinâmica
	var current_rarity: String = MetaProgression.get_profession_rarity(selected_prof_id)
	var next_rarity_info: Dictionary = MetaProgression.get_next_profession_rarity_info(selected_prof_id)

	var p_name: String = str(prof_data.get("name", selected_prof_id))
	var p_desc: String = str(prof_data.get("description", ""))
	var p_pname: String = str(prof_data.get("passive_name", ""))
	var p_pdesc: String = str(prof_data.get("passive_description", ""))

	var rarity_prog_str := ""
	if next_rarity_info.get("is_max", false):
		rarity_prog_str = "[color=#e070ff]★ Raridade Máxima (Lendário)[/color]"
	else:
		rarity_prog_str = "%s ([color=#70d0ff]%d/%d Infâmia[/color] p/ %s)" % [
			current_rarity.capitalize(),
			next_rarity_info.get("current_infamy", 0),
			next_rarity_info.get("required_infamy", 0),
			next_rarity_info.get("next_name", "")
		]

	var bonus_text := ""
	if selected_prof_id == "combatant":
		match current_rarity:
			"common":
				bonus_text = "[color=#ff7070][b]Arsenal Comum:[/b] Inicia com 5 cartas comuns de ataque/defesa.[/color]"
			"uncommon":
				bonus_text = "[color=#70d0ff][b]Arsenal Incomum:[/b] Inicia com 3 cartas comuns e 2 incomuns de combate.[/color]"
			"rare":
				bonus_text = "[color=#d070ff][b]Arsenal Raro:[/b] Inicia com 3 cartas incomuns e 2 raras de combate.[/color]"
			"legendary":
				bonus_text = "[color=#f0c040][b]Arsenal Lendário:[/b] Inicia com 3 cartas raras e 2 lendárias de combate![/color]"
	else:
		match current_rarity:
			"common":
				bonus_text = "[color=#70e0b0][b]Arsenal Comum:[/b] Inicia com 1 carta comum temática.[/color]"
			"uncommon":
				bonus_text = "[color=#70d0ff][b]Arsenal Incomum:[/b] Inicia com 1 carta comum e 1 incomum temática.[/color]"
			"rare":
				bonus_text = "[color=#d070ff][b]Arsenal Raro:[/b] Inicia com 2 cartas incomuns e 1 rara temática.[/color]"
			"legendary":
				bonus_text = "[color=#f0c040][b]Arsenal Lendário:[/b] Inicia com 2 cartas raras e 1 lendária temática![/color]"

	prof_info_label.text = "[color=#50e0d0][b]Profissão: %s[/b] — Raridade: %s[/color]\n[color=#b0b8c0]%s[/color]\n• [b]Passiva (%s):[/b] [i]%s[/i]\n• %s" % [
		p_name, rarity_prog_str, p_desc, p_pname, p_pdesc, bonus_text
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
	var current_pool: Array = prof_pool.get(current_rarity, [])
	var pool_names: Array[String] = []
	for cid in current_pool:
		var c_name := str(cid)
		if DataLoader.has_card(cid):
			c_name = DataLoader.get_card(cid).get("name", cid)
		pool_names.append(c_name)

	deck_preview_label.text = "[color=#f5d070][b]Baralho Base do Estilo (%d cartas):[/b][/color]\n%s\n\n[color=#70d0ff][b]Possíveis Cartas Iniciais da Profissão (%s):[/b][/color]\n%s" % [
		card_names.size(),
		", ".join(card_names),
		current_rarity.capitalize(),
		", ".join(pool_names)
	]
