extends Node

var player_max_hp: int = 70
var player_hp: int = 70
var gold: int = 0
var food: int = 5
var ship_integrity: int = 100

var current_deck: Array[String] = [
	"strike_basic",
	"strike_basic",
	"defend_basic",
	"defend_basic"
]

func reset_run() -> void:
	player_hp = player_max_hp
	gold = 0
	food = 5
	ship_integrity = 100
	current_deck = [
		"strike_basic",
		"strike_basic",
		"defend_basic",
		"defend_basic"
	]
