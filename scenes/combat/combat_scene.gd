extends Control

@onready var player_hp_label: Label = $TopBar/PlayerHPLabel
@onready var enemy_hp_label: Label = $TopBar/EnemyHPLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var enemy_name_label: Label = $EnemyArea/EnemyNameLabel
@onready var end_turn_button: Button = $EndTurnButton
@onready var strike_button: Button = $HandArea/StrikeButton

var player_hp: int = 70
var player_max_hp: int = 70

var enemy_name: String = "Recruta da Marinha"
var enemy_hp: int = 32
var enemy_max_hp: int = 32

var energy: int = 3
var max_energy: int = 3

func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	strike_button.pressed.connect(_on_strike_pressed)
	update_ui()

func update_ui() -> void:
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	enemy_hp_label.text = "Inimigo: %d/%d" % [enemy_hp, enemy_max_hp]
	energy_label.text = "Energia: %d/%d" % [energy, max_energy]
	enemy_name_label.text = enemy_name
	
	strike_button.disabled = energy < 1 or enemy_hp <= 0
	end_turn_button.disabled = enemy_hp <= 0

func _on_end_turn_pressed() -> void:
	energy = max_energy
	print("Turno encerrado.")
	update_ui()

func _on_strike_pressed() -> void:
	var cost := 1
	var damage := 6
	
	if energy < cost:
		print("Energia insuficiente.")
		return
		
	energy -= cost
	enemy_hp -= damage
	enemy_hp = max(enemy_hp, 0)
	
	print("Golpe Básico causou %d de dano." % damage)
	
	if enemy_hp <= 0:
		print("Inimigo derrotado.")
		
	update_ui()
