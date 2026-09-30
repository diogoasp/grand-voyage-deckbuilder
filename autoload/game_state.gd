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
var current_act: int = 1 # 1 = South Blue, 2 = Grand Line

var combat_style: String = "swordsman"
var player_profession: String = "combatant"
var profession_rarity: String = "common"

func reset_run() -> void:
	current_act = 1
	player_hp = player_max_hp
	gold = 0
	food = 5
	ship_integrity = 100
	bounty = 0
	crew_members.clear()
	eaten_fruit = ""
	combat_style = "swordsman"
	player_profession = "combatant"
	profession_rarity = "common"
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


func setup_custom_run(style_id: String, prof_id: String, prof_rarity: String = "common") -> void:
	reset_run()
	combat_style = style_id
	player_profession = prof_id
	profession_rarity = prof_rarity

	# Aplica atributos do estilo de combate
	if DataLoader.has_combat_style(style_id):
		var style_data: Dictionary = DataLoader.get_combat_style(style_id)
		player_max_hp = int(style_data.get("starting_hp", 70))
		player_hp = player_max_hp
		gold = int(style_data.get("starting_gold", 0))
		food = int(style_data.get("starting_food", 5))

		current_deck.clear()
		for cid in style_data.get("starter_deck", []):
			current_deck.append(str(cid))

	# Adiciona cartas de profissão de acordo com as regras de raridade
	distribute_profession_starter_cards(prof_id, prof_rarity)


func distribute_profession_starter_cards(prof_id: String, rarity: String) -> void:
	if not DataLoader.has_profession(prof_id):
		return

	var prof_data: Dictionary = DataLoader.get_profession(prof_id)
	var card_pool: Dictionary = prof_data.get("card_pool", {})

	var common_pool: Array = card_pool.get("common", [])
	var uncommon_pool: Array = card_pool.get("uncommon", [])
	var rare_pool: Array = card_pool.get("rare", [])
	var legendary_pool: Array = card_pool.get("legendary", [])

	var cards_to_add: Array[String] = []

	if prof_id == "combatant":
		# Regras do Combatente (sempre 5 cartas)
		match rarity:
			"common":
				cards_to_add.append_array(_pick_random_cards(common_pool, 5))
			"uncommon":
				cards_to_add.append_array(_pick_random_cards(common_pool, 3))
				cards_to_add.append_array(_pick_random_cards(uncommon_pool, 2))
			"rare":
				cards_to_add.append_array(_pick_random_cards(uncommon_pool, 3))
				cards_to_add.append_array(_pick_random_cards(rare_pool, 2))
			"legendary":
				cards_to_add.append_array(_pick_random_cards(rare_pool, 3))
				cards_to_add.append_array(_pick_random_cards(legendary_pool, 2))
			_:
				cards_to_add.append_array(_pick_random_cards(common_pool, 5))
	else:
		# Regras das outras profissões (com passiva)
		match rarity:
			"common":
				cards_to_add.append_array(_pick_random_cards(common_pool, 1))
			"uncommon":
				cards_to_add.append_array(_pick_random_cards(common_pool, 1))
				cards_to_add.append_array(_pick_random_cards(uncommon_pool, 1))
			"rare":
				cards_to_add.append_array(_pick_random_cards(uncommon_pool, 2))
				cards_to_add.append_array(_pick_random_cards(rare_pool, 1))
			"legendary":
				cards_to_add.append_array(_pick_random_cards(rare_pool, 2))
				cards_to_add.append_array(_pick_random_cards(legendary_pool, 1))
			_:
				cards_to_add.append_array(_pick_random_cards(common_pool, 1))

	for cid in cards_to_add:
		add_card_to_deck(cid)


func _pick_random_cards(pool: Array, count: int) -> Array[String]:
	var result: Array[String] = []
	if pool.is_empty() or count <= 0:
		return result

	var temp_pool: Array = pool.duplicate()
	for i in range(count):
		if temp_pool.is_empty():
			temp_pool = pool.duplicate()
		var idx := randi() % temp_pool.size()
		result.append(str(temp_pool[idx]))
		temp_pool.remove_at(idx)
	return result


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


func has_role_in_crew(role_or_tag: String) -> bool:
	var target: String = role_or_tag.strip_edges().to_lower()
	if target == "":
		return false

	# Verifica se a profissão do próprio jogador coincide
	if GameState.player_profession.to_lower() == target:
		return true

	# Verifica entre todos os tripulantes recrutados
	for cid in crew_members:
		if not DataLoader.has_crew(cid):
			continue
		var cdata: Dictionary = DataLoader.get_crew(cid)
		var c_role: String = str(cdata.get("role", "")).to_lower()
		var c_tags: Array = cdata.get("tags", [])

		if target in c_role:
			return true

		for t in c_tags:
			if str(t).to_lower() == target:
				return true

	return false


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
		"current_act": current_act,
		"player_max_hp": player_max_hp,
		"player_hp": player_hp,
		"gold": gold,
		"food": food,
		"ship_integrity": ship_integrity,
		"bounty": bounty,
		"combat_style": combat_style,
		"player_profession": player_profession,
		"profession_rarity": profession_rarity,
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




func peek_saved_run_summary() -> Dictionary:
	if not has_saved_run():
		return {}

	var file: FileAccess = null
	for p in get_save_paths():
		if FileAccess.file_exists(p):
			file = FileAccess.open(p, FileAccess.READ)
			if file != null:
				break

	if file == null:
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if not (parsed is Dictionary):
		return {}

	return parsed


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

	current_act = int(data.get("current_act", 1))
	player_max_hp = int(data.get("player_max_hp", 70))
	player_hp = int(data.get("player_hp", 70))
	gold = int(data.get("gold", 0))
	food = int(data.get("food", 5))
	ship_integrity = int(data.get("ship_integrity", 100))
	bounty = int(data.get("bounty", 0))
	combat_style = str(data.get("combat_style", "swordsman"))
	player_profession = str(data.get("player_profession", "combatant"))
	profession_rarity = str(data.get("profession_rarity", "common"))
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



