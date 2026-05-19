extends Node

var cards: Dictionary = {}


func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	cards = load_json_dictionary("res://data/cards/cards.json")
	print("DataLoader: %d cartas carregadas." % cards.size())


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
