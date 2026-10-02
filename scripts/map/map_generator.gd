class_name MapGenerator
extends RefCounted

## Gerador procedural da carta náutica (Slay the Spire-style).
## Suporta múltiplos Atos/Fases:
##   - Ato 1: South Blue (Ilhota Desconhecida -> Karate / Sorbet / Ilha Misteriosa -> Centaurea / Judo / Torino -> Ilha Misteriosa / Baterilla -> Briss Kingdom -> Chefe)
##   - Ato 2: Entrada da Grand Line (Reverse Mountain / Cabos Gêmeos)

const COMMON_COMBAT_FALLBACKS: Array[Dictionary] = [
	{
		"target_id": "marine_recruit",
		"title": "Recruta da Marinha",
		"desc": "Patrulha costeira"
	},
	{
		"target_id": "bandit_sailor",
		"title": "Saqueador do Mar",
		"desc": "Pirataria rival"
	}
]

const SECTOR_BOSS_FALLBACK: Dictionary = {
	"target_id": "boss_harrison",
	"title": "Harrison, Líder dos Rebeldes de Briss",
	"desc": "Confronto com os Rebeldes de Briss"
}


static func generate_sector_map(act: int = 1) -> Array[Array]:
	if act == 1:
		return generate_south_blue_map()
	else:
		return generate_grand_line_map()


## ============================================================================
## ATO 1: SOUTH BLUE
## Partida: Ilhota Desconhecida
## Setor 1: Karate Island, Sorbet Kingdom, Ilha Misteriosa
## Setor 2: Centaurea Kingdom, Judo Island, Torino Kingdom
## Setor 3: Ilha Misteriosa, Baterilla Island
## Setor 4: Briss Kingdom (Grande Porto Seguro antes da Grande Travessia)
## Setor 5: Batalha de Chefe do South Blue
## ============================================================================
static func generate_south_blue_map() -> Array[Array]:
	var stages: Array[Array] = []

	# -------------------------------------------------------------------------
	# Setor 1: Karate Island, Sorbet Kingdom, Ilha Misteriosa
	# -------------------------------------------------------------------------
	var stage_0: Array = [
		create_island_node("node_0_0", 0, "Karate Island", ["event", "combat", "city"], "Dojô & Cais de Luta"),
		create_island_node("node_0_1", 0, "Sorbet Kingdom", ["event", "city", "combat"], "Monarquia do Sul"),
		create_island_node("node_0_2", 0, "Ilha Misteriosa", ["event"], "Encontro Enigmático")
	]
	stages.append(stage_0)

	# -------------------------------------------------------------------------
	# Setor 2: Centaurea Kingdom, Judo Island, Torino Kingdom
	# -------------------------------------------------------------------------
	var stage_1: Array = [
		create_island_node("node_1_0", 1, "Centaurea Kingdom", ["combat", "city", "event"], "Terras Revolucionárias"),
		create_island_node("node_1_1", 1, "Judo Island", ["combat", "event"], "Guerreiros da Agarrada"),
		create_island_node("node_1_2", 1, "Torino Kingdom", ["event", "combat"], "Ervas e Pássaros Gigantes")
	]
	stages.append(stage_1)

	# -------------------------------------------------------------------------
	# Setor 3: Ilha Misteriosa, Baterilla Island
	# -------------------------------------------------------------------------
	var stage_2: Array = [
		create_island_node("node_2_0", 2, "Ilha Misteriosa", ["event"], "Brumas do Mar Aberto"),
		create_island_node("node_2_1", 2, "Baterilla Island", ["event", "city", "combat"], "Pequeno Paraíso do Sul")
	]
	stages.append(stage_2)

	# -------------------------------------------------------------------------
	# Setor 4: Briss Kingdom (Última ilha do South Blue antes do confronto)
	# -------------------------------------------------------------------------
	var stage_3: Array = [
		{
			"id": "node_3_0",
			"stage": 3,
			"island_name": "Briss Kingdom",
			"type": "city",
			"target_id": "port",
			"title": "Briss Kingdom",
			"desc": "Grande Porto de Embarque Final",
			"next_nodes": []
		}
	]
	stages.append(stage_3)

	# -------------------------------------------------------------------------
	# Setor 5: Batalha de Chefe do South Blue (Harrison - Briss)
	# -------------------------------------------------------------------------
	var boss_info: Dictionary = get_sector_boss(1)
	var stage_4: Array = [
		{
			"id": "node_4_0",
			"stage": 4,
			"island_name": "Águas do Estreito Final",
			"type": "boss",
			"target_id": boss_info["target_id"],
			"title": boss_info["title"],
			"desc": boss_info["desc"],
			"next_nodes": []
		}
	]
	stages.append(stage_4)

	# Conexões ramificadas estilo Slay the Spire
	build_stage_connections(stage_0, stage_1)
	build_stage_connections(stage_1, stage_2)
	build_stage_connections(stage_2, stage_3)
	build_stage_connections(stage_3, stage_4)

	return stages


## ============================================================================
## ATO 2: ENTRADA DA GRAND LINE (Reverse Mountain / Cabos Gêmeos)
## ============================================================================
static func generate_grand_line_map() -> Array[Array]:
	var stages: Array[Array] = []

	var stage_0: Array = [
		create_island_node("node_0_0", 0, "Canais da Reverse Mountain", ["event", "combat"], "Correnteza Ascendente"),
		create_island_node("node_0_1", 0, "Farol dos Cabos Gêmeos", ["city", "event"], "Refúgio do Guardião Crocus")
	]
	stages.append(stage_0)

	var stage_1: Array = [
		create_island_node("node_1_0", 1, "Mar de Névoa da Grand Line", ["event"], "Baú Místico de Akuma no Mi"),
		create_island_node("node_1_1", 1, "Águas do Primeiro Log Pose", ["combat"], "Piratas da Nova Rota")
	]
	stages.append(stage_1)

	var stage_2: Array = [
		{
			"id": "node_2_0",
			"stage": 2,
			"island_name": "Cactus Island",
			"type": "city",
			"target_id": "port",
			"title": "Whiskey Peak",
			"desc": "Taverna dos Caçadores de Recompensa",
			"next_nodes": []
		}
	]
	stages.append(stage_2)

	var boss_info: Dictionary = get_sector_boss(2)
	var stage_3: Array = [
		{
			"id": "node_3_0",
			"stage": 3,
			"island_name": "Águas de Whiskey Peak",
			"type": "boss",
			"target_id": boss_info["target_id"],
			"title": boss_info["title"],
			"desc": boss_info["desc"],
			"next_nodes": []
		}
	]
	stages.append(stage_3)

	build_stage_connections(stage_0, stage_1)
	build_stage_connections(stage_1, stage_2)
	build_stage_connections(stage_2, stage_3)

	return stages


## Cria um nó de ilha sorteando seu papel entre os tipos permitidos
static func create_island_node(node_id: String, stage_idx: int, island: String, allowed_types: Array[String], theme_desc: String) -> Dictionary:
	var chosen_type: String = allowed_types[randi() % allowed_types.size()]
	var target_id := ""
	var node_title := island
	var node_desc := theme_desc

	match chosen_type:
		"combat":
			var combat_pool: Array[Dictionary] = get_enemy_pool_for_stage(stage_idx)
			if not combat_pool.is_empty():
				var picked: Dictionary = combat_pool[randi() % combat_pool.size()]
				target_id = picked["target_id"]
				node_title = "%s: %s" % [island, picked["title"]]
				node_desc = picked["desc"]
			else:
				target_id = "marine_recruit"
				node_title = "%s: Patrulha" % island

		"city":
			target_id = "port"
			node_title = "%s: Pousada & Porto" % island
			node_desc = "Taverna, Mercado e Treinamento"

		"event":
			# Sorteia eventos válidos para a fase atual (sem Akuma no Mi no South Blue!)
			var act: int = 1 if stage_idx <= 4 else 2
			var ev_pool: Array[Dictionary] = DataLoader.get_events_for_stage(stage_idx, act)
			if not ev_pool.is_empty():
				var picked_ev: Dictionary = ev_pool[randi() % ev_pool.size()]
				target_id = picked_ev.get("id", "")
				var ev_short: String = str(picked_ev.get("short_title", picked_ev.get("title", "Evento")))
				node_title = "%s (%s)" % [island, ev_short]
				node_desc = str(picked_ev.get("desc", theme_desc))
			else:
				target_id = "old_port_trainer"
				node_title = "%s: Encontro" % island

	return {
		"id": node_id,
		"stage": stage_idx,
		"island_name": island,
		"type": chosen_type,
		"target_id": target_id,
		"title": node_title,
		"desc": node_desc,
		"next_nodes": []
	}


static func build_stage_connections(current_stage_nodes: Array, next_stage_nodes: Array) -> void:
	if current_stage_nodes.is_empty() or next_stage_nodes.is_empty():
		return

	var num_curr: int = current_stage_nodes.size()
	var num_next: int = next_stage_nodes.size()

	# Caso especial: convergência para nó único (ex: Briss Kingdom ou Chefe)
	if num_next == 1:
		var target_id: String = next_stage_nodes[0].get("id", "")
		for node in current_stage_nodes:
			node["next_nodes"] = [target_id]
		return

	# Caso de ramificação procedural
	for i in range(num_curr):
		var node: Dictionary = current_stage_nodes[i]
		var connections: Array[String] = []

		var min_target_idx: int = int(floor(float(i) / float(num_curr) * float(num_next)))
		var max_target_idx: int = mini(min_target_idx + 1, num_next - 1)

		connections.append(next_stage_nodes[min_target_idx].get("id", ""))
		if max_target_idx != min_target_idx and randf() < 0.75:
			connections.append(next_stage_nodes[max_target_idx].get("id", ""))

		node["next_nodes"] = connections

	# Garantia de sem nós órfãos
	for next_node in next_stage_nodes:
		var next_id: String = next_node.get("id", "")
		var has_incoming := false
		for curr_node in current_stage_nodes:
			var next_list: Array = curr_node.get("next_nodes", [])
			if next_list.has(next_id):
				has_incoming = true
				break
		if not has_incoming:
			var random_curr: Dictionary = current_stage_nodes[randi() % current_stage_nodes.size()]
			var cur_list: Array = random_curr.get("next_nodes", [])
			cur_list.append(next_id)
			random_curr["next_nodes"] = cur_list


static func get_enemy_pool_for_stage(_stage_index: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for enemy_id in DataLoader.enemies.keys():
		var edata: Dictionary = DataLoader.get_enemy(enemy_id)
		var cat: String = str(edata.get("category", "common"))
		if cat != "boss":
			pool.append({
				"target_id": enemy_id,
				"title": str(edata.get("name", enemy_id)),
				"desc": "Confronto marítimo"
			})

	if pool.is_empty():
		return COMMON_COMBAT_FALLBACKS.duplicate()

	return pool


static func get_sector_boss(act: int = 1) -> Dictionary:
	var eligible_bosses: Array[Dictionary] = []
	for enemy_id in DataLoader.enemies.keys():
		var edata: Dictionary = DataLoader.get_enemy(enemy_id)
		if str(edata.get("category", "")) == "boss":
			var acts: Array = edata.get("allowed_acts", [])
			if acts.is_empty() or acts.has(act):
				eligible_bosses.append({
					"target_id": enemy_id,
					"title": str(edata.get("name", enemy_id)),
					"desc": str(edata.get("story_intro", "Chefe do Mar"))
				})

	if not eligible_bosses.is_empty():
		eligible_bosses.shuffle()
		return eligible_bosses[0]

	return SECTOR_BOSS_FALLBACK.duplicate()
