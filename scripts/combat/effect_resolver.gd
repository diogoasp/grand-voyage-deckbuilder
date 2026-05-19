class_name EffectResolver
extends RefCounted


func resolve_effects(
	effects: Array,
	player: Combatant,
	enemy: Combatant,
	source: String = ""
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for effect in effects:
		if not effect is Dictionary:
			results.append({
				"type": "invalid",
				"message": "Efeito ignorado: não é Dictionary."
			})
			continue

		var result: Dictionary = resolve_effect(effect, player, enemy, source)
		results.append(result)

	return results


func resolve_effect(
	effect: Dictionary,
	player: Combatant,
	enemy: Combatant,
	source: String = ""
) -> Dictionary:
	var effect_type: String = str(effect.get("type", ""))
	var value: int = int(effect.get("value", 0))
	var target: String = str(effect.get("target", ""))

	match effect_type:
		"damage":
			return resolve_damage(value, target, player, enemy, source)

		"block":
			return resolve_block(value, target, player, enemy, source)

		_:
			return {
				"type": "unknown",
				"effect_type": effect_type,
				"source": source,
				"message": "Tipo de efeito desconhecido: %s" % effect_type
			}


func resolve_damage(
	value: int,
	target: String,
	player: Combatant,
	enemy: Combatant,
	source: String
) -> Dictionary:
	var target_combatant: Combatant = get_target_combatant(target, player, enemy)

	if target_combatant == null:
		return {
			"type": "damage",
			"source": source,
			"target": target,
			"success": false,
			"message": "Alvo inválido para dano: %s" % target
		}

	var damage_result: Dictionary = target_combatant.take_damage(value)

	return {
		"type": "damage",
		"source": source,
		"target": target,
		"success": true,
		"incoming_damage": int(damage_result["incoming_damage"]),
		"blocked_damage": int(damage_result["blocked_damage"]),
		"final_damage": int(damage_result["final_damage"]),
		"remaining_hp": int(damage_result["remaining_hp"]),
		"message": "%s recebeu %d de dano." % [
			target_combatant.display_name,
			int(damage_result["final_damage"])
		]
	}


func resolve_block(
	value: int,
	target: String,
	player: Combatant,
	enemy: Combatant,
	source: String
) -> Dictionary:
	var target_combatant: Combatant = get_target_combatant(target, player, enemy)

	if target_combatant == null:
		return {
			"type": "block",
			"source": source,
			"target": target,
			"success": false,
			"message": "Alvo inválido para bloqueio: %s" % target
		}

	target_combatant.gain_block(value)

	return {
		"type": "block",
		"source": source,
		"target": target,
		"success": true,
		"block_gained": max(value, 0),
		"current_block": target_combatant.block,
		"message": "%s ganhou %d de bloqueio." % [
			target_combatant.display_name,
			max(value, 0)
		]
	}


func get_target_combatant(
	target: String,
	player: Combatant,
	enemy: Combatant
) -> Combatant:
	match target:
		"player":
			return player

		"enemy":
			return enemy

		"self":
			return enemy

		_:
			return null
