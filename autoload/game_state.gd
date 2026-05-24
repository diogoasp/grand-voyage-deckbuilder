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

func reset_run() -> void:
	player_hp = player_max_hp
	gold = 0
	food = 5
	ship_integrity = 100
	bounty = 0
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


func gain_gold(amount: int) -> void:
	gold += max(amount, 0)


func gain_bounty(amount: int) -> void:
	bounty += max(amount, 0)


func set_player_hp(value: int) -> void:
	player_hp = clamp(value, 0, player_max_hp)
