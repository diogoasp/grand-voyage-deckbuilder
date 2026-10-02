extends Control

signal back_to_menu_requested

const MAP_SCENE: PackedScene = preload("res://scenes/map/MapScene.tscn")
const EVENT_SCENE: PackedScene = preload("res://scenes/events/EventScene.tscn")
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/CombatScene.tscn")
const CITY_SCENE: PackedScene = preload("res://scenes/city/CityScene.tscn")
const MAP_GENERATOR = preload("res://scripts/map/map_generator.gd")

@onready var screen_container: Control = $ScreenContainer
@onready var settings_button: Button = $TopRightUI/SettingsButton
@onready var settings_overlay: ColorRect = $SettingsOverlay
@onready var reset_run_button: Button = $SettingsOverlay/SettingsPanel/Margin/VBox/ResetRunButton
@onready var return_to_menu_button: Button = $SettingsOverlay/SettingsPanel/Margin/VBox/ReturnToMenuButton
@onready var close_settings_button: Button = $SettingsOverlay/SettingsPanel/Margin/VBox/CloseSettingsButton

var current_screen: Node = null

var current_stage: int = 0
var completed_nodes: Array[String] = []
var active_node_data: Dictionary = {}
var sector_map: Array[Array] = []
var last_selected_node_id: String = ""


func _ready() -> void:
	randomize()
	settings_button.pressed.connect(_on_settings_button_pressed)
	close_settings_button.pressed.connect(_on_close_settings_button_pressed)
	reset_run_button.pressed.connect(_on_reset_run_pressed)
	return_to_menu_button.pressed.connect(_on_return_to_menu_pressed)
	settings_overlay.visible = false


func _on_settings_button_pressed() -> void:
	settings_overlay.visible = true


func _on_close_settings_button_pressed() -> void:
	settings_overlay.visible = false


func _on_reset_run_pressed() -> void:
	settings_overlay.visible = false
	start_run()


func _on_return_to_menu_pressed() -> void:
	settings_overlay.visible = false
	save_run()
	back_to_menu_requested.emit()


func start_run() -> void:
	start_custom_run(GameState.combat_style, GameState.player_profession, GameState.profession_rarity, GameState.player_gender)


func start_custom_run(style_id: String, prof_id: String, prof_rarity: String = "common", gender: String = "male") -> void:
	randomize()
	GameState.delete_saved_run()
	GameState.setup_custom_run(style_id, prof_id, prof_rarity, gender)
	current_stage = 0
	completed_nodes.clear()
	active_node_data.clear()
	last_selected_node_id = ""
	sector_map = MAP_GENERATOR.generate_sector_map(1)
	save_run()
	show_map()



func save_run() -> void:
	var extra: Dictionary = {
		"current_stage": current_stage,
		"completed_nodes": completed_nodes,
		"sector_map": sector_map,
		"last_selected_node_id": last_selected_node_id
	}
	GameState.save_run_state(extra)


func load_saved_run() -> void:
	var extra: Dictionary = GameState.load_run_state()
	current_stage = int(extra.get("current_stage", 0))
	last_selected_node_id = str(extra.get("last_selected_node_id", ""))
	
	completed_nodes.clear()
	for nid in extra.get("completed_nodes", []):
		completed_nodes.append(str(nid))

	sector_map.clear()
	var raw_map = extra.get("sector_map", [])
	var map_valid := true
	if raw_map is Array and not raw_map.is_empty():
		for stage in raw_map:
			if stage is Array and not stage.is_empty():
				for n in stage:
					if not (n is Dictionary) or n.is_empty() or not n.has("id"):
						map_valid = false
						break
				if not map_valid:
					break
				sector_map.append(stage)
			else:
				map_valid = false
				break
	else:
		map_valid = false

	if not map_valid or sector_map.is_empty():
		sector_map = MAP_GENERATOR.generate_sector_map(GameState.current_act)
		# Se o mapa teve que ser recriado devido a dados corrompidos no save, reconecta last_selected_node_id
		if last_selected_node_id != "" and not completed_nodes.is_empty():
			# Tenta achar se o nó ainda existe; se não, limpa para permitir escolher qualquer nó do estágio atual
			var found := false
			for st in sector_map:
				for node in st:
					if node.get("id", "") == last_selected_node_id:
						found = true
						break
				if found:
					break
			if not found:
				last_selected_node_id = ""
		save_run()
	else:
		# Verifica se os nós possuem 'next_nodes' populados; se não tiverem (save antigo), reconstrói as rotas
		var needs_connections := false
		for stage_idx in range(sector_map.size() - 1):
			var stage_nodes: Array = sector_map[stage_idx]
			for node in stage_nodes:
				if not node.has("next_nodes") or (node.get("next_nodes", []) as Array).is_empty():
					needs_connections = true
					break
			if needs_connections:
				break
		if needs_connections:
			for stage_idx in range(sector_map.size() - 1):
				MAP_GENERATOR.build_stage_connections(sector_map[stage_idx], sector_map[stage_idx + 1])
			save_run()

	show_map()



func clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		if current_screen.get_parent() == screen_container:
			screen_container.remove_child(current_screen)
		current_screen.queue_free()
		current_screen = null


func switch_to_screen(new_screen: Node) -> void:
	if not is_instance_valid(new_screen):
		return

	clear_current_screen()
	current_screen = new_screen

	if new_screen is CanvasItem:
		new_screen.modulate.a = 0.0
		screen_container.add_child(new_screen)
		var tween := create_tween()
		tween.tween_property(new_screen, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		screen_container.add_child(new_screen)


func show_map() -> void:
	var map_scene: Node = MAP_SCENE.instantiate()
	if "map_stages" in map_scene and not sector_map.is_empty():
		map_scene.map_stages = sector_map

	if map_scene.has_method("setup_state"):
		map_scene.setup_state(current_stage, completed_nodes, last_selected_node_id)

	if map_scene.has_signal("node_selected"):
		map_scene.node_selected.connect(_on_map_node_selected)

	if map_scene.has_signal("new_expedition_requested"):
		map_scene.new_expedition_requested.connect(_on_expedition_victory_requested)

	switch_to_screen(map_scene)


func _on_map_node_selected(node_data: Dictionary) -> void:
	active_node_data = node_data.duplicate(true)
	last_selected_node_id = str(node_data.get("id", ""))
	save_run()
	var node_type: String = str(node_data.get("type", ""))
	var target_id: String = str(node_data.get("target_id", ""))

	match node_type:
		"event":
			show_event(target_id)
		"combat", "boss":
			show_combat(target_id)
		"city":
			show_city()
		_:
			push_warning("Tipo de nó desconhecido no mapa: %s" % node_type)
			show_map()


func complete_active_node() -> void:
	var node_id: String = str(active_node_data.get("id", ""))
	if node_id != "" and not completed_nodes.has(node_id):
		completed_nodes.append(node_id)

	apply_crew_travel_effects()

	current_stage += 1
	active_node_data = {}
	refresh_future_event_nodes()
	save_run()
	show_map()


func refresh_future_event_nodes() -> void:
	var act: int = 1 if current_stage <= 4 else 2
	for stage_idx in range(current_stage, sector_map.size()):
		var stage_nodes = sector_map[stage_idx]
		if not (stage_nodes is Array):
			continue
		for node in stage_nodes:
			if not (node is Dictionary):
				continue
			if str(node.get("type", "")) == "event":
				var ev_id: String = str(node.get("target_id", ""))
				var is_valid := false
				if DataLoader.has_event(ev_id):
					var ev_data: Dictionary = DataLoader.get_event(ev_id)
					if DataLoader.is_event_available(ev_data, stage_idx, act):
						is_valid = true
				if not is_valid:
					var available_events: Array[Dictionary] = DataLoader.get_events_for_stage(stage_idx, act)
					if not available_events.is_empty():
						var picked: Dictionary = available_events[randi() % available_events.size()]
						node["target_id"] = str(picked.get("id", "old_port_trainer"))
						var ev_short: String = str(picked.get("short_title", picked.get("title", "Evento")))
						node["title"] = "%s (%s)" % [str(node.get("island_name", "Ilha")), ev_short]
						node["desc"] = str(picked.get("desc", ""))
					else:
						node["target_id"] = "old_port_trainer"
						node["title"] = "%s (Velho Lutador)" % str(node.get("island_name", "Ilha"))
						node["desc"] = "Treino de Postura ou Haki"



func apply_crew_travel_effects() -> void:
	# Passiva da profissão do Capitão (Médico)
	if GameState.player_profession == "doctor" and DataLoader.has_profession("doctor"):
		var prof_data: Dictionary = DataLoader.get_profession("doctor")
		var heal_table: Dictionary = prof_data.get("passive_heal_by_rarity", {})
		var prof_heal: int = int(heal_table.get(GameState.profession_rarity, 5))
		if prof_heal > 0:
			GameState.heal_player(prof_heal)
			print("Passiva da profissão do Capitão (Médico): +%d HP recuperados na travessia." % prof_heal)

	# Efeitos da Tripulação
	for crew_id in GameState.crew_members:
		if not DataLoader.has_crew(crew_id):
			continue

		var crew_data: Dictionary = DataLoader.get_crew(crew_id)

		# Custo de manutenção (comida)
		var food_cost: int = int(crew_data.get("food_cost_per_sector", 0))
		if food_cost > 0:
			GameState.spend_food(food_cost)

		# Passiva de cura em viagem (Médico da tripulação)
		var heal_amount: int = int(crew_data.get("passive_heal_per_sector", 0))
		if heal_amount > 0:
			GameState.heal_player(heal_amount)
			print("Passiva da tripulação [%s]: capitão recuperou +%d HP na travessia." % [
				crew_data.get("name", crew_id),
				heal_amount
			])


func show_event(event_id: String) -> void:
	var final_event_id: String = event_id
	var act: int = 1 if current_stage <= 4 else 2

	# Verifica se o evento predeterminado ainda é válido (ex: tripulante ou fruta já adquiridos)
	var is_valid := false
	if DataLoader.has_event(final_event_id):
		var ev_data: Dictionary = DataLoader.get_event(final_event_id)
		if DataLoader.is_event_available(ev_data, current_stage, act):
			is_valid = true

	if not is_valid:
		var available_events: Array[Dictionary] = DataLoader.get_events_for_stage(current_stage, act)
		if not available_events.is_empty():
			var picked: Dictionary = available_events[randi() % available_events.size()]
			final_event_id = str(picked.get("id", "old_port_trainer"))
		else:
			final_event_id = "old_port_trainer"

		# Sincroniza o active_node_data para manter consistência
		if not active_node_data.is_empty():
			active_node_data["target_id"] = final_event_id

	var event_scene: Node = EVENT_SCENE.instantiate()
	if event_scene.has_method("setup"):
		event_scene.setup(final_event_id)

	if event_scene.has_signal("continue_requested"):
		event_scene.continue_requested.connect(_on_event_continue_requested)

	switch_to_screen(event_scene)


func show_combat(enemy_id: String = "marine_recruit") -> void:
	var combat_scene: Node = COMBAT_SCENE.instantiate()
	if "current_enemy_id" in combat_scene:
		combat_scene.current_enemy_id = enemy_id

	# Se a ilha ativa definir um cenário específico, encaminha para o combate
	if "combat_background_path" in combat_scene and not active_node_data.is_empty():
		var island_name: String = str(active_node_data.get("island_name", ""))
		if island_name == "Briss Kingdom":
			combat_scene.combat_background_path = "res://assets/scenarios/briss.png"
		elif island_name in ["Karate Island", "Sorbet Kingdom", "Centaurea Kingdom", "Baterilla Island"]:
			combat_scene.combat_background_path = "res://assets/scenarios/harbor_island.png"
		elif island_name == "Ilha Misteriosa":
			combat_scene.combat_background_path = "res://assets/scenarios/misterious_island.png"

	if combat_scene.has_signal("combat_victory"):
		combat_scene.combat_victory.connect(_on_combat_victory)

	if combat_scene.has_signal("combat_defeat"):
		combat_scene.combat_defeat.connect(_on_combat_defeat)

	switch_to_screen(combat_scene)


func show_city() -> void:
	var city_scene: Node = CITY_SCENE.instantiate()
	if city_scene.has_signal("depart_requested"):
		city_scene.depart_requested.connect(_on_city_depart_requested)

	switch_to_screen(city_scene)


func _on_event_continue_requested() -> void:
	complete_active_node()


func _on_combat_victory() -> void:
	complete_active_node()


func _on_city_depart_requested() -> void:
	complete_active_node()


func _on_combat_defeat() -> void:
	# Converte o Bounty acumulado na expedição em Pontos de Infâmia permanentes e credita maestria
	var bounty_earned: int = GameState.bounty
	var meta_res: Dictionary = MetaProgression.convert_run_end_to_infamy(
		bounty_earned, false, GameState.combat_style, GameState.player_profession
	)
	print("Naufrágio! Bounty: %d -> Infâmia ganha: %d. Saldo total: %d" % [
		bounty_earned,
		meta_res.get("earned_infamy", 0),
		meta_res.get("total_infamy", 0)
	])
	if meta_res.get("profession_promoted", false):
		print("★ Promoção de Carreira! Sua profissão subiu para raridade: %s" % meta_res.get("new_profession_rarity", ""))
	start_run()


func _on_expedition_victory_requested() -> void:
	var bounty_earned: int = GameState.bounty
	var meta_res: Dictionary = MetaProgression.convert_run_end_to_infamy(
		bounty_earned, true, GameState.combat_style, GameState.player_profession
	)
	print("Vitória no Mar! Bounty: %d -> Infâmia ganha: %d (com bônus de vitória!). Saldo total: %d" % [
		bounty_earned,
		meta_res.get("earned_infamy", 0),
		meta_res.get("total_infamy", 0)
	])
	if meta_res.get("profession_promoted", false):
		print("★ Promoção de Carreira! Sua profissão subiu para raridade: %s" % meta_res.get("new_profession_rarity", ""))
	var new_cards: Array = meta_res.get("new_cards_unlocked", [])
	if not new_cards.is_empty():
		print("Novas cartas desbloqueadas por marco de notoriedade ou maestria: %s" % str(new_cards))

	if GameState.current_act == 1:
		# Avança para o Ato 2 (Entrada da Grand Line) mantendo vida, deck, ouro e tripulação!
		advance_to_grand_line()
	else:
		start_run()


func advance_to_grand_line() -> void:
	GameState.current_act = 2
	current_stage = 0
	completed_nodes.clear()
	active_node_data.clear()
	last_selected_node_id = ""
	sector_map = MAP_GENERATOR.generate_sector_map(2)
	save_run()
	show_map()
