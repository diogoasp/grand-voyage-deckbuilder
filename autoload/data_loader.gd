extends Node

var cards: Dictionary = {}
var enemies: Dictionary = {}
var events: Dictionary = {}
var crew: Dictionary = {}
var fruits: Dictionary = {}

func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	cards = load_json_dictionary("res://data/cards/cards.json")
	enemies = load_json_dictionary("res://data/enemies/enemies.json")
	events = load_json_dictionary("res://data/events/events.json")
	crew = load_json_dictionary("res://data/crew/crew.json")
	fruits = load_json_dictionary("res://data/fruits/fruits.json")

	print("DataLoader: %d cartas carregadas." % cards.size())
	print("DataLoader: %d inimigos carregados." % enemies.size())
	print("DataLoader: %d eventos carregados." % events.size())
	print("DataLoader: %d tripulantes carregados." % crew.size())
	print("DataLoader: %d frutas carregadas." % fruits.size())


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


func get_events_for_stage(stage_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id in events.keys():
		var ev: Dictionary = events[event_id]
		var allowed_stages: Array = ev.get("allowed_stages", [])
		if not (allowed_stages.is_empty() or allowed_stages.has(stage_index)):
			continue

		# Filtra eventos que concedem tripulantes ou frutas ainda não desbloqueados na metaprogressão
		var is_available := true
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
					if cid != "" and not MetaProgression.is_crew_unlocked(cid):
						is_available = false
						break
				elif eff_type == "consume_fruit":
					var fid: String = str(eff.get("fruit_id", ""))
					if fid != "" and not MetaProgression.is_fruit_unlocked(fid):
						is_available = false
						break
			if not is_available:
				break

		if is_available:
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
