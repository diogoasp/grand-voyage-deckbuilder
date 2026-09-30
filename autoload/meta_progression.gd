extends Node

## Gerenciador Central de Metaprogressão e Notoriedade Náutica
## Controla o saldo de Pontos de Infâmia, desbloqueios de Tripulantes, Akuma no Mi e Marcos de Cartas.

signal infamy_changed(new_amount: int)
signal crew_unlocked(crew_id: String)
signal fruit_unlocked(fruit_id: String)
signal card_unlocked(card_id: String)
signal milestone_claimed(milestone_id: String)

var infamy_points: int = 0
var total_infamy_earned: int = 0
var highest_bounty: int = 0
var total_runs_completed: int = 0

var unlocked_crew: Array[String] = ["doctor_lin"]
var unlocked_fruits: Array[String] = ["kiri_kiri_no_mi"]
var unlocked_cards: Array[String] = []
var claimed_milestones: Array[String] = []

# Catálogo de Itens da Loja de Infâmia
const CREW_SHOP_CATALOG: Dictionary = {
	"chef_tora": {
		"id": "chef_tora",
		"cost": 50,
		"name": "Tora, o Cozinheiro dos Mares",
		"role": "Cozinheiro",
		"desc": "Concede provisões extras e a carta Refeição Revigorante.",
		"type": "crew"
	}
}

const FRUIT_SHOP_CATALOG: Dictionary = {
	"goro_goro_no_mi": {
		"id": "goro_goro_no_mi",
		"cost": 80,
		"name": "Goro Goro no Mi (Fruta do Trovão)",
		"type_desc": "Logia Elemental",
		"desc": "Descarga Estática inicial de 4 dano em todos os combates + Cartas de Choque e Raio.",
		"type": "fruit"
	}
}

# Marcos de Conquista por Notoriedade / Acontecimentos
const MILESTONES_CATALOG: Array[Dictionary] = [
	{
		"id": "ms_infamy_30",
		"title": "Pirata em Ascensão",
		"desc": "Acumule 30 ou mais de Infâmia Total na carreira.",
		"reward_card_id": "tactical_feint",
		"reward_card_name": "Finta Tática",
		"condition_type": "total_infamy",
		"threshold": 30
	},
	{
		"id": "ms_defeat_morgan",
		"title": "Queda do Carrasco",
		"desc": "Conclua o primeiro setor derrotando o Capitão Morgan.",
		"reward_card_id": "axe_breaker",
		"reward_card_name": "Quebra-Defesas",
		"condition_type": "runs_completed",
		"threshold": 1
	}
]


func _ready() -> void:
	load_meta_state()


func get_meta_save_paths() -> Array[String]:
	var paths: Array[String] = ["user://meta_progression.json"]
	var project_path: String = ProjectSettings.globalize_path("res://saved_meta_progression.json")
	if OS.has_feature("editor") or not OS.has_feature("standalone"):
		paths.append(project_path)
	return paths


func load_meta_state() -> void:
	var file: FileAccess = null
	for p in get_meta_save_paths():
		if FileAccess.file_exists(p):
			file = FileAccess.open(p, FileAccess.READ)
			if file != null:
				break

	if file == null:
		# Inicialização padrão para novos jogadores
		save_meta_state()
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		save_meta_state()
		return

	var data: Dictionary = parsed
	infamy_points = int(data.get("infamy_points", 0))
	total_infamy_earned = int(data.get("total_infamy_earned", 0))
	highest_bounty = int(data.get("highest_bounty", 0))
	total_runs_completed = int(data.get("total_runs_completed", 0))

	unlocked_crew.clear()
	for c in data.get("unlocked_crew", ["doctor_lin"]):
		unlocked_crew.append(str(c))
	if not unlocked_crew.has("doctor_lin"):
		unlocked_crew.append("doctor_lin")

	unlocked_fruits.clear()
	for f in data.get("unlocked_fruits", ["kiri_kiri_no_mi"]):
		unlocked_fruits.append(str(f))
	if not unlocked_fruits.has("kiri_kiri_no_mi"):
		unlocked_fruits.append("kiri_kiri_no_mi")

	unlocked_cards.clear()
	for crd in data.get("unlocked_cards", []):
		unlocked_cards.append(str(crd))

	claimed_milestones.clear()
	for ms in data.get("claimed_milestones", []):
		claimed_milestones.append(str(ms))

	print("MetaProgression carregada: %d Pontos de Infâmia | %d Tripulantes | %d Frutas | %d Cartas Desbloqueadas." % [
		infamy_points, unlocked_crew.size(), unlocked_fruits.size(), unlocked_cards.size()
	])


func save_meta_state() -> void:
	var dict: Dictionary = {
		"infamy_points": infamy_points,
		"total_infamy_earned": total_infamy_earned,
		"highest_bounty": highest_bounty,
		"total_runs_completed": total_runs_completed,
		"unlocked_crew": unlocked_crew,
		"unlocked_fruits": unlocked_fruits,
		"unlocked_cards": unlocked_cards,
		"claimed_milestones": claimed_milestones
	}

	var json_str: String = JSON.stringify(dict, "\t")
	for p in get_meta_save_paths():
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f != null:
			f.store_string(json_str)
			f.close()
			break


func convert_run_end_to_infamy(run_bounty: int, run_won: bool) -> Dictionary:
	# Conversão: 1 Ponto de Infâmia a cada 2 de Bounty + bônus de 20 se concluiu a run derrotando o chefe
	var base_pts: int = int(floor(float(run_bounty) / 2.0))
	var win_bonus: int = 20 if run_won else 0
	var earned: int = maxi(base_pts + win_bonus, 5 if run_won else 0)

	infamy_points += earned
	total_infamy_earned += earned
	highest_bounty = maxi(highest_bounty, run_bounty)
	if run_won:
		total_runs_completed += 1

	infamy_changed.emit(infamy_points)
	save_meta_state()

	var new_cards: Array[String] = check_and_trigger_milestones()

	return {
		"earned_infamy": earned,
		"total_infamy": infamy_points,
		"new_cards_unlocked": new_cards
	}


func check_and_trigger_milestones() -> Array[String]:
	var newly_unlocked_cards: Array[String] = []

	for ms in MILESTONES_CATALOG:
		var ms_id: String = str(ms.get("id", ""))
		if claimed_milestones.has(ms_id):
			continue

		var c_type: String = str(ms.get("condition_type", ""))
		var threshold: int = int(ms.get("threshold", 0))
		var fulfilled := false

		match c_type:
			"total_infamy":
				fulfilled = (total_infamy_earned >= threshold)
			"runs_completed":
				fulfilled = (total_runs_completed >= threshold)
			"highest_bounty":
				fulfilled = (highest_bounty >= threshold)

		if fulfilled:
			claimed_milestones.append(ms_id)
			var card_id: String = str(ms.get("reward_card_id", ""))
			if card_id != "" and not unlocked_cards.has(card_id):
				unlocked_cards.append(card_id)
				newly_unlocked_cards.append(card_id)
				card_unlocked.emit(card_id)
			milestone_claimed.emit(ms_id)

	if not newly_unlocked_cards.is_empty():
		save_meta_state()

	return newly_unlocked_cards


func can_unlock_crew(crew_id: String) -> bool:
	if unlocked_crew.has(crew_id):
		return false
	if not CREW_SHOP_CATALOG.has(crew_id):
		return false
	var cost: int = int(CREW_SHOP_CATALOG[crew_id]["cost"])
	return infamy_points >= cost


func unlock_crew(crew_id: String) -> bool:
	if not can_unlock_crew(crew_id):
		return false
	var cost: int = int(CREW_SHOP_CATALOG[crew_id]["cost"])
	infamy_points -= cost
	unlocked_crew.append(crew_id)
	infamy_changed.emit(infamy_points)
	crew_unlocked.emit(crew_id)
	save_meta_state()
	return true


func can_unlock_fruit(fruit_id: String) -> bool:
	if unlocked_fruits.has(fruit_id):
		return false
	if not FRUIT_SHOP_CATALOG.has(fruit_id):
		return false
	var cost: int = int(FRUIT_SHOP_CATALOG[fruit_id]["cost"])
	return infamy_points >= cost


func unlock_fruit(fruit_id: String) -> bool:
	if not can_unlock_fruit(fruit_id):
		return false
	var cost: int = int(FRUIT_SHOP_CATALOG[fruit_id]["cost"])
	infamy_points -= cost
	unlocked_fruits.append(fruit_id)
	infamy_changed.emit(infamy_points)
	fruit_unlocked.emit(fruit_id)
	save_meta_state()
	return true


func is_crew_unlocked(crew_id: String) -> bool:
	return unlocked_crew.has(crew_id)


func is_fruit_unlocked(fruit_id: String) -> bool:
	return unlocked_fruits.has(fruit_id)


func is_card_unlocked(card_id: String) -> bool:
	return unlocked_cards.has(card_id)
