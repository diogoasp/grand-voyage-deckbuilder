class_name Combatant
extends RefCounted

var id: String = ""
var display_name: String = ""
var max_hp: int = 1
var hp: int = 1
var block: int = 0


func setup(new_id: String, new_display_name: String, new_max_hp: int) -> void:
	id = new_id
	display_name = new_display_name
	max_hp = max(new_max_hp, 1)
	hp = max_hp
	block = 0


func take_damage(amount: int) -> Dictionary:
	var incoming_damage: int = max(amount, 0)
	var blocked_damage: int = min(block, incoming_damage)
	var final_damage: int = incoming_damage - blocked_damage

	block -= blocked_damage
	hp -= final_damage
	hp = max(hp, 0)

	return {
		"incoming_damage": incoming_damage,
		"blocked_damage": blocked_damage,
		"final_damage": final_damage,
		"remaining_hp": hp
	}


func gain_block(amount: int) -> void:
	block += max(amount, 0)


func clear_block() -> void:
	block = 0


func is_defeated() -> bool:
	return hp <= 0


func get_hp_text() -> String:
	return "%d/%d" % [hp, max_hp]

func heal(amount: int) -> Dictionary:
	var heal_amount: int = max(amount, 0)
	var hp_before: int = hp

	hp += heal_amount
	hp = min(hp, max_hp)

	var effective_heal: int = hp - hp_before

	return {
		"requested_heal": heal_amount,
		"effective_heal": effective_heal,
		"current_hp": hp,
		"max_hp": max_hp
	}
