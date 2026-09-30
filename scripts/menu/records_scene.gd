class_name RecordsScene
extends Control

signal back_requested

@onready var infamy_label: Label = $MainLayout/TopBar/InfamyLabel
@onready var stats_label: Label = $MainLayout/TopBar/StatsLabel
@onready var back_button: Button = $MainLayout/TopBar/BackButton

@onready var tab_container: TabContainer = $MainLayout/TabContainer

# Conteúdo da Aba 1 (Mercado Notório: Tripulantes & Akuma no Mi)
@onready var crew_container: VBoxContainer = $MainLayout/TabContainer/Mercado/Margin/Scroll/ContentVBox/CrewSection/CrewList
@onready var fruits_container: VBoxContainer = $MainLayout/TabContainer/Mercado/Margin/Scroll/ContentVBox/FruitSection/FruitList

# Conteúdo da Aba 2 (Marcos & Conquistas de Cartas)
@onready var milestones_container: VBoxContainer = $MainLayout/TabContainer/Conquistas/Margin/Scroll/MilestonesList

@onready var feedback_label: Label = $MainLayout/BottomBar/FeedbackLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	MetaProgression.infamy_changed.connect(_on_infamy_changed)
	refresh_display()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_infamy_changed(_new_val: int) -> void:
	refresh_display()


func refresh_display() -> void:
	infamy_label.text = "☠ Pontos de Infâmia: %d" % MetaProgression.infamy_points
	stats_label.text = "Infâmia Histórica: %d | Maior Bounty: %d | Expedições Vencidas: %d" % [
		MetaProgression.total_infamy_earned,
		MetaProgression.highest_bounty,
		MetaProgression.total_runs_completed
	]

	rebuild_shop_ui()
	rebuild_milestones_ui()


func rebuild_shop_ui() -> void:
	for child in crew_container.get_children():
		child.queue_free()
	for child in fruits_container.get_children():
		child.queue_free()

	# Tripulantes
	for crew_id in MetaProgression.CREW_SHOP_CATALOG.keys():
		var data: Dictionary = MetaProgression.CREW_SHOP_CATALOG[crew_id]
		var item_card := create_shop_item_card(data, "crew")
		crew_container.add_child(item_card)

	# Akuma no Mi
	for fruit_id in MetaProgression.FRUIT_SHOP_CATALOG.keys():
		var data: Dictionary = MetaProgression.FRUIT_SHOP_CATALOG[fruit_id]
		var item_card := create_shop_item_card(data, "fruit")
		fruits_container.add_child(item_card)


func create_shop_item_card(item_data: Dictionary, item_type: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.theme_override_constants.set("separation", 16)
	margin.add_child(hbox)

	var item_id: String = item_data["id"]
	var item_name: String = item_data["name"]
	var item_desc: String = item_data["desc"]
	var cost: int = item_data["cost"]

	var is_unlocked: bool = false
	if item_type == "crew":
		is_unlocked = MetaProgression.is_crew_unlocked(item_id)
	else:
		is_unlocked = MetaProgression.is_fruit_unlocked(item_id)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_lbl := Label.new()
	title_lbl.text = item_name
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4) if is_unlocked else Color(0.8, 0.85, 0.9))
	info_vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item_desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(desc_lbl)

	hbox.add_child(info_vbox)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(160, 42)

	if is_unlocked:
		action_btn.text = "✓ Desbloqueado"
		action_btn.disabled = true
		action_btn.modulate = Color(0.6, 0.9, 0.6, 1.0)
	else:
		action_btn.text = "Desbloquear (%d ☠)" % cost
		var can_afford: bool = (MetaProgression.infamy_points >= cost)
		action_btn.disabled = not can_afford
		action_btn.pressed.connect(_on_unlock_button_pressed.bind(item_id, item_type, item_name, cost))

	hbox.add_child(action_btn)
	return panel


func _on_unlock_button_pressed(item_id: String, item_type: String, item_name: String, _cost: int) -> void:
	var success := false
	if item_type == "crew":
		success = MetaProgression.unlock_crew(item_id)
	else:
		success = MetaProgression.unlock_fruit(item_id)

	if success:
		feedback_label.text = "🎉 Parabéns! [%s] foi desbloqueado e agora pode ser encontrado nas suas viagens!" % item_name
		refresh_display()
	else:
		feedback_label.text = "Pontos de Infâmia insuficientes."


func rebuild_milestones_ui() -> void:
	for child in milestones_container.get_children():
		child.queue_free()

	for ms in MetaProgression.MILESTONES_CATALOG:
		var ms_id: String = ms["id"]
		var title: String = ms["title"]
		var desc: String = ms["desc"]
		var card_id: String = ms["reward_card_id"]
		var card_name: String = ms["reward_card_name"]
		var c_type: String = ms["condition_type"]
		var threshold: int = ms["threshold"]

		var is_claimed: bool = MetaProgression.claimed_milestones.has(ms_id)

		var card_data: Dictionary = DataLoader.get_card(card_id)
		var card_desc: String = str(card_data.get("description", ""))

		var panel := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.theme_override_constants.set("separation", 16)
		margin.add_child(hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_lbl := Label.new()
		title_lbl.text = "%s — Recompensa: Carta [%s]" % [title, card_name]
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3) if is_claimed else Color(0.75, 0.8, 0.85))
		info_vbox.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = "Condição: %s\nEfeito da Carta: %s" % [desc, card_desc]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		info_vbox.add_child(desc_lbl)

		hbox.add_child(info_vbox)

		# Progresso
		var status_vbox := VBoxContainer.new()
		status_vbox.custom_minimum_size = Vector2(160, 0)
		status_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var status_lbl := Label.new()
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if is_claimed:
			status_lbl.text = "✓ DESBLOQUEADA\n(Na pool de combate)"
			status_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		else:
			var current_val: int = 0
			if c_type == "total_infamy":
				current_val = MetaProgression.total_infamy_earned
			elif c_type == "runs_completed":
				current_val = MetaProgression.total_runs_completed
			status_lbl.text = "Progresso: %d / %d" % [current_val, threshold]
			status_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))

		status_vbox.add_child(status_lbl)
		hbox.add_child(status_vbox)

		milestones_container.add_child(panel)
