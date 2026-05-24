extends Node

var cards: Dictionary = {}
var enemies: Dictionary = {}

var events: Dictionary = {}

func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	cards = load_json_dictionary("res://data/cards/cards.json")
	enemies = load_json_dictionary("res://data/enemies/enemies.json")
	events = load_json_dictionary("res://data/events/events.json")

	print("DataLoader: %d cartas carregadas." % cards.size())
	print("DataLoader: %d inimigos carregados." % enemies.size())
	print("DataLoader: %d eventos carregados." % events.size())


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
