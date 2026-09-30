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
	# Estágio 0: Cais Inicial (3 ilhas/opções de partida)
	# =========================================================================
	var stage_0: Array = []
	var stage_0_events: Array[Dictionary] = DataLoader.get_events_for_stage(0)
	stage_0_events.shuffle()

	# Gera até 3 opções iniciais (ou 2 se a pool for menor)
	if stage_0_events.is_empty():
		stage_0.append({
			"id": "node_0_0",
			"stage": 0,
			"type": "event",
			"target_id": "old_port_trainer",
			"title": "Velho Lutador",
			"desc": "Treino de Postura",
			"next_nodes": []
		})
	else:
		var num_stage_0: int = clampi(stage_0_events.size(), 1, 3)
		for i in range(num_stage_0):
			var ev: Dictionary = stage_0_events[i % stage_0_events.size()]
			stage_0.append({
				"id": "node_0_%d" % i,
				"stage": 0,
				"type": "event",
				"target_id": ev.get("id", ""),
				"title": ev.get("short_title", ev.get("title", "Evento")),
				"desc": ev.get("desc", "Cais de partida"),
				"next_nodes": [] # preenchido após gerar estágio 1
			})
	stages.append(stage_0)

	# =========================================================================
	# Estágio 1: Águas de Mar Aberto (3 ilhas/opções: Combates + Eventos de exploração)
	# =========================================================================
	var stage_1: Array = []
	var combat_pool: Array[Dictionary] = get_enemy_pool_for_stage(1)
	combat_pool.shuffle()

	# Gera 2 opções de combate com inimigos variados
	for i in range(mini(2, combat_pool.size())):
		var enemy_info: Dictionary = combat_pool[i]
		stage_1.append({
			"id": "node_1_%d" % i,
			"stage": 1,
			"type": "combat",
			"target_id": enemy_info["target_id"],
			"title": enemy_info["title"],
			"desc": enemy_info["desc"],
			"next_nodes": []
		})

	# Adiciona 1 evento marítimo elegível
	var stage_1_events: Array[Dictionary] = DataLoader.get_events_for_stage(1)
	stage_1_events.shuffle()
	if not stage_1_events.is_empty():
		var ev1: Dictionary = stage_1_events[0]
		stage_1.append({
			"id": "node_1_%d" % stage_1.size(),
			"stage": 1,
			"type": "event",
			"target_id": ev1.get("id", ""),
			"title": ev1.get("short_title", ev1.get("title", "Evento")),
			"desc": ev1.get("desc", "Águas misteriosas"),
			"next_nodes": []
		})
	stages.append(stage_1)

	# =========================================================================
	# Estágio 2: Parada Portuária (1 Porto Seguro central)
	# =========================================================================
	var stage_2: Array = [
		{
			"id": "node_2_0",
			"stage": 2,
			"type": "city",
			"target_id": "port",
			"title": "Porto Seguro",
			"desc": "Taverna & Mercado",
			"next_nodes": []
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
			"desc": boss_info["desc"],
			"next_nodes": []
		}
	]
	stages.append(stage_3)

	# =========================================================================
	# Conexões Procedurais de Rotas (Slay the Spire-style branching)
	# =========================================================================
	build_stage_connections(stage_0, stage_1)
	build_stage_connections(stage_1, stage_2)
	build_stage_connections(stage_2, stage_3)

	return stages


static func build_stage_connections(current_stage_nodes: Array, next_stage_nodes: Array) -> void:
	if current_stage_nodes.is_empty() or next_stage_nodes.is_empty():
		return

	var num_curr: int = current_stage_nodes.size()
	var num_next: int = next_stage_nodes.size()

	# Caso especial: convergência para nó único (ex: Porto Seguro ou Chefe)
	if num_next == 1:
		var target_id: String = next_stage_nodes[0].get("id", "")
		for node in current_stage_nodes:
			node["next_nodes"] = [target_id]
		return

	# Caso de ramificação procedural com 2 ou 3 nós para 2 ou 3 nós
	# Ex: node_0_0 acessa node_1_0 e node_1_1, mas NÃO node_1_2
	# Garante que cada nó tenha 1 ou 2 conexões e que todo nó do próximo estágio seja alcançável
	for i in range(num_curr):
		var node: Dictionary = current_stage_nodes[i]
		var connections: Array[String] = []

		# Mapeamento proporcional em leque:
		# Nós superiores conectam aos superiores/médios, nós inferiores aos médios/inferiores
		var min_target_idx: int = int(floor(float(i) / float(num_curr) * float(num_next)))
		var max_target_idx: int = mini(min_target_idx + 1, num_next - 1)

		# Adiciona o destino principal
		connections.append(next_stage_nodes[min_target_idx].get("id", ""))
		# Com 60% de chance, adiciona uma bifurcação alternativa adjacente
		if max_target_idx != min_target_idx and randf() < 0.75:
			connections.append(next_stage_nodes[max_target_idx].get("id", ""))

		node["next_nodes"] = connections

	# Verificação de segurança: garantir que nenhum nó de destino fique órfão (sem entrada)
	for next_node in next_stage_nodes:
		var next_id: String = next_node.get("id", "")
		var has_incoming := false
		for curr_node in current_stage_nodes:
			var next_list: Array = curr_node.get("next_nodes", [])
			if next_list.has(next_id):
				has_incoming = true
				break
		if not has_incoming:
			# Conecta ao nó atual mais próximo
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

