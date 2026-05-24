class_name EffectResolver
extends RefCounted


func resolve_effects(
	effects: Array,
	context: CombatContext,
	source: String = ""
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for effect in effects:
		if not effect is Dictionary:
			results.append({
				"type": "invalid",
				"success": false,
				"message": "Efeito ignorado: não é Dictionary."
			})
			continue

		var result: Dictionary = resolve_effect(effect, context, source)
		results.append(result)

	return results


func resolve_effect(
	effect: Dictionary,
	context: CombatContext,
	source: String = ""
) -> Dictionary:
	var effect_type: String = str(effect.get("type", ""))
	var value: int = int(effect.get("value", 0))
	var target: String = str(effect.get("target", ""))

	match effect_type:
		"damage":
			return resolve_damage(value, target, context, source)

		"block":
			return resolve_block(value, target, context, source)

		"draw":
			return resolve_draw(value, target, context, source)

		"gain_energy":
			return resolve_gain_energy(value, target, context, source)

		"heal":
			return resolve_heal(value, target, context, source)

		_:
			return {
				"type": "unknown",
				"success": false,
				"effect_type": effect_type,
				"source": source,
				"message": "Tipo de efeito desconhecido: %s" % effect_type
			}


func resolve_damage(
	value: int,
	target: String,
	context: CombatContext,
	source: String
) -> Dictionary:
	var target_combatant: Combatant = get_target_combatant(target, context, source)

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
	context: CombatContext,
	source: String
) -> Dictionary:
	var target_combatant: Combatant = get_target_combatant(target, context, source)

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


func resolve_draw(
	value: int,
	target: String,
	context: CombatContext,
	source: String
) -> Dictionary:
	if target != "player":
		return {
			"type": "draw",
			"source": source,
			"target": target,
			"success": false,
			"message": "Alvo inválido para compra de cartas: %s" % target
		}

	var amount: int = max(value, 0)
	context.deck_manager.draw_cards(amount)

	return {
		"type": "draw",
		"source": source,
		"target": target,
		"success": true,
		"amount": amount,
		"message": "Comprou %d carta(s)." % amount
	}


func resolve_gain_energy(
	value: int,
	target: String,
	context: CombatContext,
	source: String
) -> Dictionary:
	if target != "player":
		return {
			"type": "gain_energy",
			"source": source,
			"target": target,
			"success": false,
			"message": "Alvo inválido para ganho de energia: %s" % target
		}

	var amount: int = max(value, 0)
	context.gain_energy(amount)

	return {
		"type": "gain_energy",
		"source": source,
		"target": target,
		"success": true,
		"amount": amount,
		"message": "Ganhou %d de energia." % amount
	}

func resolve_heal(
	value: int,
	target: String,
	context: CombatContext,
	source: String
) -> Dictionary:
	var target_combatant: Combatant = get_target_combatant(target, context, source)

	if target_combatant == null:
		return {
			"type": "heal",
			"source": source,
			"target": target,
			"success": false,
			"message": "Alvo inválido para cura: %s" % target
		}

	var heal_result: Dictionary = target_combatant.heal(value)
	var effective_heal: int = int(heal_result["effective_heal"])

	return {
		"type": "heal",
		"source": source,
		"target": target,
		"success": true,
		"requested_heal": int(heal_result["requested_heal"]),
		"effective_heal": effective_heal,
		"current_hp": int(heal_result["current_hp"]),
		"max_hp": int(heal_result["max_hp"]),
		"message": "%s recuperou %d de HP." % [
			target_combatant.display_name,
			effective_heal
		]
	}

func get_target_combatant(
	target: String,
	context: CombatContext,
	source: String
) -> Combatant:
	match target:
		"player":
			return context.player

		"enemy":
			return context.enemy

		"self":
			if source == "enemy_intent":
				return context.enemy

			return context.player

		_:
			return null
