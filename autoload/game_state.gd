extends Node

var player_max_hp: int = 70
var player_hp: int = 70

var gold: int = 0
var food: int = 5
var ship_integrity: int = 100
var bounty: int = 0

var current_deck: Array[String] = [
	"strike_basic",
	"strike_basic",
	"strike_basic",
	"defend_basic",
	"defend_basic",
	"defend_basic",
	"quick_thinking",
	"second_wind"
]

var crew_members: Array[String] = []
var eaten_fruit: String = ""

func reset_run() -> void:
	player_hp = player_max_hp
	gold = 0
	food = 5
	ship_integrity = 100
	bounty = 0
	crew_members.clear()
	eaten_fruit = ""
	current_deck = [
		"strike_basic",
		"strike_basic",
		"strike_basic",
		"defend_basic",
		"defend_basic",
		"defend_basic",
		"quick_thinking",
		"second_wind"
	]


func gain_gold(amount: int) -> void:
	gold += max(amount, 0)


func gain_bounty(amount: int) -> void:
	bounty += max(amount, 0)


func set_player_hp(value: int) -> void:
	player_hp = clamp(value, 0, player_max_hp)


func heal_player(amount: int) -> void:
	set_player_hp(player_hp + max(amount, 0))


func spend_gold(amount: int) -> bool:
	if amount < 0:
		return false
	if gold < amount:
		return false
	gold -= amount
	return true


func spend_food(amount: int) -> bool:
	if amount < 0:
		return false
	if food < amount:
		return false
	food -= amount
	return true


func add_card_to_deck(card_id: String) -> void:
	if not DataLoader.has_card(card_id):
		push_warning("Tentativa de adicionar carta inexistente ao deck: %s" % card_id)
		return

	current_deck.append(card_id)
	print("Carta adicionada ao deck: %s" % card_id)


func has_crew_member(crew_id: String) -> bool:
	return crew_members.has(crew_id)


func recruit_crew(crew_id: String) -> bool:
	if has_crew_member(crew_id):
		push_warning("Tripulante já faz parte da tripulação: %s" % crew_id)
		return false

	if not DataLoader.has_crew(crew_id):
		push_warning("Tripulante não encontrado no banco de dados: %s" % crew_id)
		return false

	var crew_data: Dictionary = DataLoader.get_crew(crew_id)
	crew_members.append(crew_id)

	# Adiciona cartas associadas ao deck
	var associated_cards: Array = crew_data.get("associated_cards", [])
	for card_id in associated_cards:
		add_card_to_deck(str(card_id))

	print("Tripulante recrutado: %s (%s)" % [crew_data.get("name", crew_id), crew_data.get("role", "")])
	return true


func has_eaten_fruit() -> bool:
	return eaten_fruit != ""


func consume_fruit(fruit_id: String) -> bool:
	if has_eaten_fruit():
		push_warning("O capitão já consumiu uma fruta: %s. Uma segunda fruta seria fatal!" % eaten_fruit)
		return false

	if not DataLoader.has_fruit(fruit_id):
		push_warning("Fruta não encontrada no DataLoader: %s" % fruit_id)
		return false

	var fruit_data: Dictionary = DataLoader.get_fruit(fruit_id)
	eaten_fruit = fruit_id

	# Adiciona cartas de poder da fruta ao deck
	var associated_cards: Array = fruit_data.get("associated_cards", [])
	for card_id in associated_cards:
		add_card_to_deck(str(card_id))

	print("Fruta consumida: %s! Cartas de poder adicionadas ao deck." % fruit_data.get("name", fruit_id))
	return true


const SAVE_FILE_PATH: String = "user://saved_run.json"


func get_save_paths() -> Array[String]:
	var paths: Array[String] = [SAVE_FILE_PATH]
	var project_path: String = ProjectSettings.globalize_path("res://saved_run.json")
	if project_path != "":
		paths.append(project_path)
	return paths


func has_saved_run() -> bool:
	for p in get_save_paths():
		if FileAccess.file_exists(p):
			return true
	return false


func save_run_state(extra_data: Dictionary = {}) -> bool:
	var state_dict: Dictionary = {
		"player_max_hp": player_max_hp,
		"player_hp": player_hp,
		"gold": gold,
		"food": food,
		"ship_integrity": ship_integrity,
		"bounty": bounty,
		"current_deck": current_deck,
		"crew_members": crew_members,
		"eaten_fruit": eaten_fruit,
		"extra": extra_data
	}

	var json_string: String = JSON.stringify(state_dict, "\t")
	var saved := false

	for p in get_save_paths():
		var file := FileAccess.open(p, FileAccess.WRITE)
		if file != null:
			file.store_string(json_string)
			file.close()
			saved = true
			break

	if not saved:
		push_warning("Não foi possível salvar em disco no ambiente atual.")
		return false

	print("Progresso da run salvo com sucesso!")
	return true




func load_run_state() -> Dictionary:
	if not has_saved_run():
		push_warning("Nenhum arquivo de save encontrado.")
		return {}

	var file: FileAccess = null
	for p in get_save_paths():
		if FileAccess.file_exists(p):
			file = FileAccess.open(p, FileAccess.READ)
			if file != null:
				break

	if file == null:
		push_error("Falha ao abrir arquivo de save.")
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Dictionary:
		push_error("Arquivo de save corrompido ou formato inválido.")
		return {}

	var data: Dictionary = parsed

	player_max_hp = int(data.get("player_max_hp", 70))
	player_hp = int(data.get("player_hp", 70))
	gold = int(data.get("gold", 0))
	food = int(data.get("food", 5))
	ship_integrity = int(data.get("ship_integrity", 100))
	bounty = int(data.get("bounty", 0))
	eaten_fruit = str(data.get("eaten_fruit", ""))

	current_deck.clear()
	for cid in data.get("current_deck", []):
		current_deck.append(str(cid))

	crew_members.clear()
	for cm in data.get("crew_members", []):
		crew_members.append(str(cm))

	print("Save da run carregado com sucesso!")
	return data.get("extra", {})


func delete_saved_run() -> void:
	for p in get_save_paths():
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	print("Save da run anterior removido.")



