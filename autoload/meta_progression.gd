extends Node

## Gerenciador Central de Metaprogressão e Notoriedade Náutica
## Controla o saldo de Pontos de Infâmia, desbloqueios de Tripulantes, Akuma no Mi e Marcos de Cartas.

signal infamy_changed(new_amount: int)
signal crew_unlocked(crew_id: String)
signal fruit_unlocked(fruit_id: String)
signal card_unlocked(card_id: String)
signal milestone_claimed(milestone_id: String)
signal profession_promoted(prof_id: String, new_rarity: String)
signal style_mastery_upgraded(style_id: String, new_level: int, unlocked_card: String)

var infamy_points: int = 0
var total_infamy_earned: int = 0
var highest_bounty: int = 0
var total_runs_completed: int = 0

var unlocked_crew: Array[String] = ["sora"]
var unlocked_fruits: Array[String] = ["kiri_kiri_no_mi"]
var unlocked_cards: Array[String] = []
var claimed_milestones: Array[String] = []

# Maestria de Profissões: { "prof_id": infamy_pts }
var profession_infamy: Dictionary = {
	"combatant": 0,
	"navigator": 0,
	"doctor": 0
}

# Maestria de Estilos de Combate: { "style_id": infamy_pts }
var style_infamy: Dictionary = {
	"swordsman": 0,
	"brawler": 0,
	"sniper": 0
}

# Limiares de Infâmia para Evolução de Raridade da Profissão
const PROFESSION_RARITY_THRESHOLDS: Array[Dictionary] = [
	{ "rarity": "common", "threshold": 0, "name": "Comum" },
	{ "rarity": "uncommon", "threshold": 300, "name": "Incomum" },
	{ "rarity": "rare", "threshold": 900, "name": "Raro" },
	{ "rarity": "legendary", "threshold": 2000, "name": "Lendário" }
]

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
	for c in data.get("unlocked_crew", ["sora"]):
		unlocked_crew.append(str(c))
	if not unlocked_crew.has("sora"):
		unlocked_crew.append("sora")

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

	var raw_prof_infamy = data.get("profession_infamy", {})
	if raw_prof_infamy is Dictionary:
		for pid in raw_prof_infamy.keys():
			profession_infamy[str(pid)] = int(raw_prof_infamy[pid])

	var raw_style_infamy = data.get("style_infamy", {})
	if raw_style_infamy is Dictionary:
		for sid in raw_style_infamy.keys():
			style_infamy[str(sid)] = int(raw_style_infamy[sid])

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
		"claimed_milestones": claimed_milestones,
		"profession_infamy": profession_infamy,
		"style_infamy": style_infamy
	}

	var json_str: String = JSON.stringify(dict, "\t")
	for p in get_meta_save_paths():
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f != null:
			f.store_string(json_str)
			f.close()
			break


func convert_run_end_to_infamy(run_bounty: int, run_won: bool, run_style_id: String = "", run_prof_id: String = "") -> Dictionary:
	# Conversão: 1 Ponto de Infâmia a cada 2 de Bounty + bônus de 20 se concluiu a run derrotando o chefe
	var base_pts: int = int(floor(float(run_bounty) / 2.0))
	var win_bonus: int = 20 if run_won else 0
	var earned: int = maxi(base_pts + win_bonus, 5 if run_won else 0)

	infamy_points += earned
	total_infamy_earned += earned
	highest_bounty = maxi(highest_bounty, run_bounty)
	if run_won:
		total_runs_completed += 1

	# Crédito de Infâmia na Profissão
	var prof_promoted := false
	var new_rarity := ""
	if run_prof_id != "":
		var old_rarity := get_profession_rarity(run_prof_id)
		var current_p_pts: int = int(profession_infamy.get(run_prof_id, 0)) + earned
		profession_infamy[run_prof_id] = current_p_pts
		new_rarity = get_profession_rarity(run_prof_id)
		if new_rarity != old_rarity:
			prof_promoted = true
			profession_promoted.emit(run_prof_id, new_rarity)

	# Crédito de Infâmia no Estilo de Combate
	var style_upgraded := false
	var newly_unlocked_style_cards: Array[String] = []
	if run_style_id != "":
		var current_s_pts: int = int(style_infamy.get(run_style_id, 0)) + earned
		style_infamy[run_style_id] = current_s_pts

		# Checa se subiu nível de maestria do estilo e destrava cartas
		newly_unlocked_style_cards = check_style_mastery_unlocks(run_style_id)

	infamy_changed.emit(infamy_points)
	save_meta_state()

	var new_cards: Array[String] = check_and_trigger_milestones()
	for sc in newly_unlocked_style_cards:
		if not new_cards.has(sc):
			new_cards.append(sc)

	return {
		"earned_infamy": earned,
		"total_infamy": infamy_points,
		"new_cards_unlocked": new_cards,
		"profession_promoted": prof_promoted,
		"new_profession_rarity": new_rarity
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


## ============================================================================
## HELPERS DE MAESTRIA: PROFISSÕES & ESTILOS DE COMBATE
## ============================================================================

func get_profession_infamy(prof_id: String) -> int:
	return int(profession_infamy.get(prof_id, 0))


func get_profession_rarity(prof_id: String) -> String:
	var pts: int = get_profession_infamy(prof_id)
	var current_rarity: String = "common"
	for t in PROFESSION_RARITY_THRESHOLDS:
		if pts >= int(t["threshold"]):
			current_rarity = str(t["rarity"])
	return current_rarity


func get_next_profession_rarity_info(prof_id: String) -> Dictionary:
	var pts: int = get_profession_infamy(prof_id)
	for i in range(PROFESSION_RARITY_THRESHOLDS.size()):
		var t: Dictionary = PROFESSION_RARITY_THRESHOLDS[i]
		if pts < int(t["threshold"]):
			return {
				"next_rarity": str(t["rarity"]),
				"next_name": str(t["name"]),
				"required_infamy": int(t["threshold"]),
				"current_infamy": pts,
				"is_max": false
			}
	return {
		"next_rarity": "legendary",
		"next_name": "Lendário (Máximo)",
		"required_infamy": 2000,
		"current_infamy": pts,
		"is_max": true
	}


func get_style_infamy(style_id: String) -> int:
	return int(style_infamy.get(style_id, 0))


func get_style_mastery_level(style_id: String) -> int:
	var pts: int = get_style_infamy(style_id)
	if not DataLoader.has_combat_style(style_id):
		return 1

	var data: Dictionary = DataLoader.get_combat_style(style_id)
	var levels: Array = data.get("mastery_levels", [])
	var lvl: int = 1
	for ml in levels:
		if pts >= int(ml.get("infamy_required", 0)):
			lvl = maxi(lvl, int(ml.get("level", 1)))
	return lvl


func get_next_style_level_info(style_id: String) -> Dictionary:
	var pts: int = get_style_infamy(style_id)
	if not DataLoader.has_combat_style(style_id):
		return { "is_max": true, "current_infamy": pts, "required_infamy": 0, "next_level": 1 }

	var data: Dictionary = DataLoader.get_combat_style(style_id)
	var levels: Array = data.get("mastery_levels", [])
	for ml in levels:
		var req: int = int(ml.get("infamy_required", 0))
		if pts < req:
			return {
				"is_max": false,
				"current_infamy": pts,
				"required_infamy": req,
				"next_level": int(ml.get("level", 2)),
				"unlocked_card_id": str(ml.get("unlocked_card_id", "")),
				"desc": str(ml.get("description", ""))
			}

	return {
		"is_max": true,
		"current_infamy": pts,
		"required_infamy": 1500,
		"next_level": 4,
		"desc": "Nível Máximo de Maestria alcançado!"
	}


func check_style_mastery_unlocks(style_id: String) -> Array[String]:
	var newly_unlocked: Array[String] = []
	if not DataLoader.has_combat_style(style_id):
		return newly_unlocked

	var pts: int = get_style_infamy(style_id)
	var data: Dictionary = DataLoader.get_combat_style(style_id)
	var levels: Array = data.get("mastery_levels", [])

	for ml in levels:
		var req: int = int(ml.get("infamy_required", 0))
		if pts >= req:
			var card_id: String = str(ml.get("unlocked_card_id", ""))
			if card_id != "" and not unlocked_cards.has(card_id):
				unlocked_cards.append(card_id)
				newly_unlocked.append(card_id)
				card_unlocked.emit(card_id)
				style_mastery_upgraded.emit(style_id, int(ml.get("level", 2)), card_id)

	return newly_unlocked
