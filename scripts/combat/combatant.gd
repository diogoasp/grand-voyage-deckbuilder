class_name Combatant
extends RefCounted

signal damage_taken(result: Dictionary)
signal block_gained(amount: int)

var id: String = ""
var display_name: String = ""
var max_hp: int = 1
var hp: int = 1
var block: int = 0
var intangible: int = 0
var weakness: int = 0


func setup(new_id: String, new_display_name: String, new_max_hp: int) -> void:
	id = new_id
	display_name = new_display_name
	max_hp = max(new_max_hp, 1)
	hp = max_hp
	block = 0
	intangible = 0
	weakness = 0


func take_damage(amount: int, ignore_block: bool = false) -> Dictionary:
	var incoming_damage: int = max(amount, 0)
	var blocked_damage: int = 0
	var final_damage: int = incoming_damage

	# Intangibilidade reduz todo dano recebido a no máximo 1 (mecânica canônica de intangibilidade/logia)
	if intangible > 0 and incoming_damage > 0:
		incoming_damage = 1
		final_damage = 1

	if not ignore_block:
		blocked_damage = min(block, incoming_damage)
		final_damage = incoming_damage - blocked_damage
		block -= blocked_damage

	hp -= final_damage
	hp = max(hp, 0)

	var res := {
		"incoming_damage": incoming_damage,
		"blocked_damage": blocked_damage,
		"final_damage": final_damage,
		"remaining_hp": hp,
		"was_intangible": intangible > 0
	}
	damage_taken.emit(res)
	return res


func calculate_outgoing_damage(base_amount: int) -> int:
	var dmg: float = float(max(base_amount, 0))
	if weakness > 0:
		# Fraqueza reduz o dano causado em 25%
		dmg = dmg * 0.75
	return int(round(dmg))


func gain_block(amount: int) -> void:
	var val: int = maxi(amount, 0)
	block += val
	if val > 0:
		block_gained.emit(val)


func clear_block() -> void:
	block = 0


func gain_intangible(turns: int) -> void:
	intangible += max(turns, 0)


func gain_weakness(turns: int) -> void:
	weakness += max(turns, 0)


func tick_turn_statuses() -> void:
	if intangible > 0:
		intangible -= 1
	if weakness > 0:
		weakness -= 1


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
