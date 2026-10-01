extends Node

var cards: Dictionary = {}
var enemies: Dictionary = {}
var events: Dictionary = {}
var crew: Dictionary = {}
var fruits: Dictionary = {}
var combat_styles: Dictionary = {}
var professions: Dictionary = {}

func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	cards = load_json_dictionary("res://data/cards/cards.json")
	enemies = load_json_dictionary("res://data/enemies/enemies.json")
	events = load_json_dictionary("res://data/events/events.json")
	crew = load_json_dictionary("res://data/crew/crew.json")
	fruits = load_json_dictionary("res://data/fruits/fruits.json")
	combat_styles = load_json_dictionary("res://data/combat_styles/combat_styles.json")
	professions = load_json_dictionary("res://data/professions/professions.json")

	print("DataLoader: %d cartas carregadas." % cards.size())
	print("DataLoader: %d inimigos carregados." % enemies.size())
	print("DataLoader: %d eventos carregados." % events.size())
	print("DataLoader: %d tripulantes carregados." % crew.size())
	print("DataLoader: %d frutas carregadas." % fruits.size())
	print("DataLoader: %d estilos de combate carregados." % combat_styles.size())
	print("DataLoader: %d profissões carregadas." % professions.size())


func load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Arquivo JSON não encontrado: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Não foi possível abrir o arquivo JSON: %s" % path)
		return {}

	var json_text := file.get_as_text()
	var parsed_data: Variant = JSON.parse_string(json_text)

	if parsed_data == null:
		push_error("JSON inválido em: %s" % path)
		return {}

	if not parsed_data is Dictionary:
		push_error("JSON não é um Dictionary: %s" % path)
		return {}

	return parsed_data


func get_card(card_id: String) -> Dictionary:
	if not cards.has(card_id):
		push_warning("Carta não encontrada: %s" % card_id)
		return {}

	return cards[card_id]


func has_card(card_id: String) -> bool:
	return cards.has(card_id)


func get_all_card_ids() -> Array[String]:
	var result: Array[String] = []
	for cid in cards.keys():
		result.append(str(cid))
	return result

func get_enemy(enemy_id: String) -> Dictionary:
	if not enemies.has(enemy_id):
		push_warning("Inimigo não encontrado: %s" % enemy_id)
		return {}

	return enemies[enemy_id]


func has_enemy(enemy_id: String) -> bool:
	return enemies.has(enemy_id)

func get_event(event_id: String) -> Dictionary:
	if not events.has(event_id):
		push_warning("Evento não encontrado: %s" % event_id)
		return {}

	return events[event_id]


func has_event(event_id: String) -> bool:
	return events.has(event_id)


func get_all_events() -> Dictionary:
	return events


func is_event_available(ev: Dictionary, stage_index: int = -1, act: int = -1) -> bool:
	# Filtra por ato/fase (ex: South Blue = 1, Grand Line = 2)
	if act != -1:
		var allowed_acts: Array = ev.get("allowed_acts", [])
		if not allowed_acts.is_empty():
			var has_act := false
			for a in allowed_acts:
				if int(a) == act:
					has_act = true
					break
			if not has_act:
				return false

	if stage_index != -1:
		var allowed_stages: Array = ev.get("allowed_stages", [])
		if not allowed_stages.is_empty():
			var has_stage := false
			for s in allowed_stages:
				if int(s) == stage_index:
					has_stage = true
					break
			if not has_stage:
				return false

	# Filtra eventos que concedem tripulantes ou frutas ainda não desbloqueados ou já recrutados
	var choices: Array = ev.get("choices", [])
	for ch in choices:
		if not (ch is Dictionary):
			continue
		var effects: Array = ch.get("effects", [])
		for eff in effects:
			if not (eff is Dictionary):
				continue
			var eff_type: String = str(eff.get("type", ""))
			if eff_type == "recruit_crew":
				var cid: String = str(eff.get("crew_id", ""))
				if cid != "":
					# Não oferece se não estiver desbloqueado na metaprogressão
					if not MetaProgression.is_crew_unlocked(cid):
						return false
					# Não oferece se o membro específico já estiver na tripulação
					if GameState.has_crew_member(cid):
						return false
					# Não oferece se a tripulação já possuir a profissão ou tags do tripulante
					if has_crew(cid):
						var cdata: Dictionary = get_crew(cid)
						var role_str: String = str(cdata.get("role", "")).to_lower()
						var tags: Array = cdata.get("tags", [])
						# Verifica por médico/doctor
						if ("médic" in role_str or "doctor" in role_str or tags.has("doctor")) and (GameState.has_role_in_crew("doctor") or GameState.has_role_in_crew("médico")):
							return false
						# Verifica por cozinheiro/chef
						if ("cozinh" in role_str or "chef" in role_str or tags.has("chef")) and (GameState.has_role_in_crew("chef") or GameState.has_role_in_crew("cozinheiro")):
							return false
						# Verifica por navegador/navigator
						if ("navegad" in role_str or "navigator" in role_str or tags.has("navigator")) and (GameState.has_role_in_crew("navigator") or GameState.has_role_in_crew("navegador")):
							return false
			elif eff_type == "consume_fruit":
				var fid: String = str(eff.get("fruit_id", ""))
				if fid != "" and not MetaProgression.is_fruit_unlocked(fid):
					return false
				# Não oferece se já comeu fruta
				if GameState.has_eaten_fruit():
					return false

	return true


func get_events_for_stage(stage_index: int, act: int = 1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id in events.keys():
		var ev: Dictionary = events[event_id]
		if is_event_available(ev, stage_index, act):
			result.append(ev)

	return result



func get_crew(crew_id: String) -> Dictionary:
	if not crew.has(crew_id):
		push_warning("Tripulante não encontrado: %s" % crew_id)
		return {}

	return crew[crew_id]


func has_crew(crew_id: String) -> bool:
	return crew.has(crew_id)


func get_fruit(fruit_id: String) -> Dictionary:
	if not fruits.has(fruit_id):
		push_warning("Fruta não encontrada: %s" % fruit_id)
		return {}

	return fruits[fruit_id]


func has_fruit(fruit_id: String) -> bool:
	return fruits.has(fruit_id)


func get_combat_style(style_id: String) -> Dictionary:
	if not combat_styles.has(style_id):
		push_warning("Estilo de combate não encontrado: %s" % style_id)
		return {}
	return combat_styles[style_id]


func has_combat_style(style_id: String) -> bool:
	return combat_styles.has(style_id)


func get_all_combat_styles() -> Dictionary:
	return combat_styles


func get_profession(prof_id: String) -> Dictionary:
	if not professions.has(prof_id):
		push_warning("Profissão não encontrada: %s" % prof_id)
		return {}
	return professions[prof_id]


func has_profession(prof_id: String) -> bool:
	return professions.has(prof_id)


func get_all_professions() -> Dictionary:
	return professions
