class_name MainMenuScene
extends Control

signal new_run_selected
signal continue_run_selected
signal records_selected

@onready var continue_button: Button = $VBoxContainer/MenuButtons/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/MenuButtons/NewGameButton
@onready var diary_button: Button = $VBoxContainer/MenuButtons/DiaryButton
@onready var records_button: Button = $VBoxContainer/MenuButtons/RecordsButton
@onready var settings_button: Button = $VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton

@onready var save_info_panel: PanelContainer = $VBoxContainer/SaveInfoPanel
@onready var save_info_label: Label = $VBoxContainer/SaveInfoPanel/MarginContainer/SaveInfoLabel
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel

var has_active_save: bool = false


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	diary_button.pressed.connect(_on_locked_feature_pressed.bind("Diário"))
	records_button.pressed.connect(_on_records_pressed)
	settings_button.pressed.connect(_on_locked_feature_pressed.bind("Configurações"))
	quit_button.pressed.connect(_on_quit_pressed)

	refresh_save_status()


func refresh_save_status() -> void:
	has_active_save = GameState.has_saved_run()
	continue_button.disabled = not has_active_save

	if has_active_save:
		var summary: Dictionary = GameState.peek_saved_run_summary()
		var extra: Dictionary = summary.get("extra", {})

		var hp: int = int(summary.get("player_hp", 0))
		var max_hp: int = int(summary.get("player_max_hp", 0))
		var gold: int = int(summary.get("gold", 0))
		var food: int = int(summary.get("food", 0))
		var bounty: int = int(summary.get("bounty", 0))
		var deck_size: int = (summary.get("current_deck", []) as Array).size()
		var stage_idx: int = int(extra.get("current_stage", 0)) + 1

		var crew_count: int = (summary.get("crew_members", []) as Array).size()
		var fruit_name: String = str(summary.get("eaten_fruit", ""))
		var fruit_info := "Nenhuma"
		if fruit_name != "":
			if DataLoader.has_fruit(fruit_name):
				fruit_info = DataLoader.get_fruit(fruit_name).get("name", fruit_name)
			else:
				fruit_info = fruit_name

		var style_id: String = str(summary.get("combat_style", "swordsman"))
		var style_name := style_id
		if DataLoader.has_combat_style(style_id):
			style_name = DataLoader.get_combat_style(style_id).get("name", style_id)

		var prof_id: String = str(summary.get("player_profession", "combatant"))
		var prof_name := prof_id
		if DataLoader.has_profession(prof_id):
			prof_name = DataLoader.get_profession(prof_id).get("name", prof_id)

		var act_num: int = int(summary.get("current_act", 1))
		var sea_name := "South Blue" if act_num == 1 else "Grand Line"

		save_info_label.text = "⚓ EXPEDIÇÃO EM CURSO: %s (Setor %d)\n• Capitão: %s (%s)  |  Vida: %d/%d  |  Ouro: %d  |  Comida: %d\n• Deck: %d cartas  |  Tripulação: %d  |  Akuma no Mi: %s" % [
			sea_name, stage_idx, style_name, prof_name, hp, max_hp, gold, food, deck_size, crew_count, fruit_info
		]
		save_info_panel.visible = true
	else:
		save_info_panel.visible = false
		feedback_label.text = "Nenhuma expedição em andamento. Inicie uma nova jornada!"


func _on_continue_pressed() -> void:
	continue_run_selected.emit()


func _on_new_game_pressed() -> void:
	new_run_selected.emit()


func _on_records_pressed() -> void:
	records_selected.emit()


var feedback_tween: Tween = null


func _on_locked_feature_pressed(feature_name: String) -> void:
	feedback_label.text = "🔒 [%s] estará disponível em atualizações futuras!" % feature_name
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
	feedback_label.modulate.a = 1.0
	feedback_tween = create_tween()
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 2.0).set_delay(1.5)


func _on_quit_pressed() -> void:
	get_tree().quit()
