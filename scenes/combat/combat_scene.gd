extends Control

# Player Labels
@onready var player_hp_label: Label = $TopBar/PlayerHPLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var block_label: Label = $TopBar/BlockLabel

# Cards
@onready var strike_button: Button = $HandArea/StrikeButton
@onready var block_button: Button = $HandArea/BlockButton

# Enemy Labels
@onready var enemy_hp_label: Label = $TopBar/EnemyHPLabel
@onready var enemy_name_label: Label = $EnemyArea/EnemyNameLabel
@onready var enemy_intent_label: Label = $EnemyArea/EnemyIntentLabel

# Action elements
@onready var end_turn_button: Button = $EndTurnButton

var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0

var enemy_name: String = "Recruta da Marinha"
var enemy_hp: int = 32
var enemy_max_hp: int = 32
var enemy_damage: int = 6

var energy: int = 3
var max_energy: int = 3

var combat_finished: bool = false

func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	strike_button.pressed.connect(_on_strike_pressed)
	block_button.pressed.connect(_on_block_pressed)
	update_ui()

func update_ui() -> void:
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	enemy_hp_label.text = "Inimigo: %d/%d" % [enemy_hp, enemy_max_hp]
	energy_label.text = "Energia: %d/%d" % [energy, max_energy]
	block_label.text = "Bloqueio: %d" % player_block
	
	enemy_name_label.text = enemy_name
	# Sobre as intenções, como base podemos ver a intenção atual. 
	# Com Haki da observação, podemos ver o dano que será causado. 
	# Com Haki avançado podemos ver, além do dano, a ação seguinte planejada
	enemy_intent_label.text = "Intenção: Atacar causando %d de dano" % enemy_damage
	
	strike_button.disabled = energy < 1 or combat_finished
	block_button.disabled = energy < 1 or combat_finished
	end_turn_button.disabled = combat_finished

func _on_end_turn_pressed() -> void:
	if combat_finished: return
	
	resolve_enemy_turn()
	
	if combat_finished:
		update_ui()
		return
		
	start_player_turn()
	update_ui()

func _on_strike_pressed() -> void:
	var cost := 1
	var damage := 6
	
	if not can_play_card(cost):
		return
		
	energy -= cost
	enemy_hp -= damage
	enemy_hp = max(enemy_hp, 0)
	
	print("Golpe Básico causou %d de dano." % damage)
	
	if enemy_hp <= 0:
		end_combat_with_victory()
		
	update_ui()

func _on_block_pressed() -> void:
	var cost := 1
	var block_gain := 5
	
	if not can_play_card(cost):
		return
	
	energy -= cost
	player_block += block_gain
	
	print("Defesa Básica concedeu %d de bloqueio." % block_gain)
	
	update_ui()

# TODO: Refatorar
func can_play_card(cost: int) -> bool:
	if combat_finished:
		return false

	if energy < cost:
		print("Energia insuficiente.")
		return false

	return true

func start_player_turn() -> void:
	print("Novo turno do jogador.")
	energy = max_energy
	player_block = 0

func resolve_enemy_turn() -> void:
	print("Turno inimigo!")
	
	var incoming_damage := enemy_damage
	var blocked_damage = min (player_block, incoming_damage)
	var final_damage = incoming_damage - blocked_damage
	
	player_block -= blocked_damage
	player_hp -= final_damage
	player_hp = max(player_hp, 0)
	
	print("Bloqueado: %d. Dano recebido: %d." % [blocked_damage, final_damage])
	
	if player_hp <= 0:
		end_combat_with_defeat()

func end_combat_with_victory() -> void:
	combat_finished = true
	print("Vitória!")

func end_combat_with_defeat() -> void:
	combat_finished = true
	print("Derrota! O capitão caiu.")
	
	
	
	
	
	
