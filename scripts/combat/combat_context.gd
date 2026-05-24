class_name CombatContext
extends RefCounted

var player: Combatant
var enemy: Combatant
var deck_manager: DeckManager

var energy: int = 0
var max_energy: int = 3


func setup(
	new_player: Combatant,
	new_enemy: Combatant,
	new_deck_manager: DeckManager,
	new_max_energy: int
) -> void:
	player = new_player
	enemy = new_enemy
	deck_manager = new_deck_manager
	max_energy = max(new_max_energy, 0)
	energy = max_energy


func reset_energy() -> void:
	energy = max_energy


func spend_energy(amount: int) -> bool:
	var cost: int = max(amount, 0)

	if energy < cost:
		return false

	energy -= cost
	return true


func gain_energy(amount: int) -> void:
	energy += max(amount, 0)


func can_spend_energy(amount: int) -> bool:
	return energy >= max(amount, 0)
