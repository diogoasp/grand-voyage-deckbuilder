class_name MapGenerator
extends RefCounted

## Gerador procedural da carta náutica (Slay the Spire-style).
## Cria uma estrutura em estágios/colunas com ramificações balanceadas e agrupadas por fase.

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
	"target_id": "marine_captain_morgan",
	"title": "Capitão Morgan",
	"desc": "Base da Marinha"
}


static func generate_sector_map(sector_index: int = 1) -> Array[Array]:
	var stages: Array[Array] = []

	# =========================================================================
	# Estágio 0: Ponto de partida (Cais Inicial / Eventos introdutórios de Fase 0)
	# =========================================================================
	var stage_0: Array = []
	var stage_0_events: Array[Dictionary] = DataLoader.get_events_for_stage(0)
	stage_0_events.shuffle()

	var num_initial_choices: int = mini(2, stage_0_events.size())
	for i in range(num_initial_choices):
		var ev: Dictionary = stage_0_events[i]
		stage_0.append({
			"id": "node_0_%d" % i,
			"stage": 0,
			"type": "event",
			"target_id": ev.get("id", ""),
			"title": ev.get("short_title", ev.get("title", "Evento")),
			"desc": ev.get("desc", "Acontecimentos no cais")
		})

	# Fallback de segurança se nenhum evento de estágio 0 for retornado
	if stage_0.is_empty():
		stage_0.append({
			"id": "node_0_0",
			"stage": 0,
			"type": "event",
			"target_id": "old_port_trainer",
			"title": "Velho Lutador",
			"desc": "Treino de Postura ou Haki"
		})
	stages.append(stage_0)

	# =========================================================================
	# Estágio 1: Águas de Mar Aberto (Bifurcação: Combates procedurais + Eventos agrupados)
	# =========================================================================
	var stage_1: Array = []
	var combat_pool: Array[Dictionary] = get_enemy_pool_for_stage(1)
	combat_pool.shuffle()

	# Gera 2 rotas de combate distintas se houver inimigos suficientes
	for i in range(mini(2, combat_pool.size())):
		var enemy_info: Dictionary = combat_pool[i]
		stage_1.append({
			"id": "node_1_%d" % i,
			"stage": 1,
			"type": "combat",
			"target_id": enemy_info["target_id"],
			"title": enemy_info["title"],
			"desc": enemy_info["desc"]
		})

	# Seleciona evento procedural elegível para o estágio 1
	var stage_1_events: Array[Dictionary] = DataLoader.get_events_for_stage(1)
	if not stage_1_events.is_empty():
		var chosen_ev: Dictionary = stage_1_events[randi() % stage_1_events.size()]
		stage_1.append({
			"id": "node_1_%d" % stage_1.size(),
			"stage": 1,
			"type": "event",
			"target_id": chosen_ev.get("id", ""),
			"title": chosen_ev.get("short_title", chosen_ev.get("title", "Evento")),
			"desc": chosen_ev.get("desc", "Mistérios marítimos")
		})
	stages.append(stage_1)

	# =========================================================================
	# Estágio 2: Parada Estratégica (Porto Seguro / Cidade de Reabastecimento)
	# =========================================================================
	var stage_2: Array = [
		{
			"id": "node_2_0",
			"stage": 2,
			"type": "city",
			"target_id": "port",
			"title": "Porto Seguro",
			"desc": "Taverna & Mercado"
		}
	]
	stages.append(stage_2)

	# =========================================================================
	# Estágio 3: Batalha de Chefe do Setor
	# =========================================================================
	var boss_info: Dictionary = get_sector_boss(sector_index)
	var stage_3: Array = [
		{
			"id": "node_3_0",
			"stage": 3,
			"type": "boss",
			"target_id": boss_info["target_id"],
			"title": boss_info["title"],
			"desc": boss_info["desc"]
		}
	]
	stages.append(stage_3)

	return stages


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


static func get_sector_boss(_sector_index: int) -> Dictionary:
	for enemy_id in DataLoader.enemies.keys():
		var edata: Dictionary = DataLoader.get_enemy(enemy_id)
		if str(edata.get("category", "")) == "boss":
			return {
				"target_id": enemy_id,
				"title": str(edata.get("name", enemy_id)),
				"desc": "Base da Marinha"
			}

	return SECTOR_BOSS_FALLBACK.duplicate()

