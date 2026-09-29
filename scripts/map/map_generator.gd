class_name MapGenerator
extends RefCounted

## Gerador procedural da carta náutica (Slay the Spire-style).
## Cria uma estrutura em estágios/colunas com ramificações balanceadas.

const COMMON_COMBAT_ENEMIES: Array[Dictionary] = [
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

const ROUTE_EVENTS: Array[Dictionary] = [
	{
		"target_id": "mysterious_chest",
		"title": "Baú Naufragado",
		"desc": "Fruta da Névoa"
	},
	{
		"target_id": "old_port_trainer",
		"title": "Mestre Errante",
		"desc": "Treinamento Marcial"
	},
	{
		"target_id": "wandering_doctor",
		"title": "Médico do Mar",
		"desc": "Recrutar Tripulação"
	}
]

const SECTOR_BOSSES: Array[Dictionary] = [
	{
		"target_id": "marine_captain_morgan",
		"title": "Capitão Morgan",
		"desc": "Base da Marinha"
	}
]


static func generate_sector_map(sector_index: int = 1) -> Array[Array]:
	var stages: Array[Array] = []

	# Estágio 0: Ponto de partida (Escolha inicial: Mentor marcial OU Médico no cais)
	var stage_0: Array = [
		{
			"id": "node_0_0",
			"stage": 0,
			"type": "event",
			"target_id": "old_port_trainer",
			"title": "Velho Lutador",
			"desc": "Treino de Postura ou Haki"
		},
		{
			"id": "node_0_1",
			"stage": 0,
			"type": "event",
			"target_id": "wandering_doctor",
			"title": "Médico do Cais",
			"desc": "Recrutar Dr. Lin"
		}
	]
	stages.append(stage_0)

	# Estágio 1: Águas costeiras (2 combates procedurais + 1 evento misterioso)
	var stage_1: Array = []
	var combat_a: Dictionary = COMMON_COMBAT_ENEMIES[randi() % COMMON_COMBAT_ENEMIES.size()]
	var combat_b: Dictionary = COMMON_COMBAT_ENEMIES[randi() % COMMON_COMBAT_ENEMIES.size()]

	stage_1.append({
		"id": "node_1_0",
		"stage": 1,
		"type": "combat",
		"target_id": combat_a["target_id"],
		"title": combat_a["title"],
		"desc": combat_a["desc"]
	})
	stage_1.append({
		"id": "node_1_1",
		"stage": 1,
		"type": "combat",
		"target_id": combat_b["target_id"],
		"title": combat_b["title"],
		"desc": combat_b["desc"]
	})
	stage_1.append({
		"id": "node_1_2",
		"stage": 1,
		"type": "event",
		"target_id": "mysterious_chest",
		"title": "Baú Naufragado",
		"desc": "Fruta da Névoa"
	})
	stages.append(stage_1)

	# Estágio 2: Parada portuária (Porto Seguro / Cidade)
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

	# Estágio 3: Batalha de Chefe do Setor
	var boss: Dictionary = SECTOR_BOSSES[randi() % SECTOR_BOSSES.size()]
	var stage_3: Array = [
		{
			"id": "node_3_0",
			"stage": 3,
			"type": "boss",
			"target_id": boss["target_id"],
			"title": boss["title"],
			"desc": boss["desc"]
		}
	]
	stages.append(stage_3)

	return stages
