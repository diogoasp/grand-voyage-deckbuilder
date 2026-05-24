class_name DeckManager
extends RefCounted

var draw_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []

var next_card_instance_id: int = 1


func setup_from_deck_ids(deck_ids: Array[String]) -> void:
	clear_all()
	next_card_instance_id = 1

	for card_id in deck_ids:
		var card_instance := create_card_instance(card_id)

		if card_instance != null:
			draw_pile.append(card_instance)

	draw_pile.shuffle()


func clear_all() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()


func create_card_instance(card_id: String) -> CardInstance:
	if not DataLoader.has_card(card_id):
		push_error("Carta não encontrada no banco: %s" % card_id)
		return null

	var card_instance := CardInstance.new()
	card_instance.setup(next_card_instance_id, card_id)

	next_card_instance_id += 1

	return card_instance


func draw_cards(amount: int) -> void:
	for i in range(amount):
		if draw_pile.is_empty():
			reshuffle_discard_into_draw_pile()

		if draw_pile.is_empty():
			return

		var card_instance: CardInstance = draw_pile.pop_back()

		if card_instance == null:
			push_warning("Instância nula encontrada no deck.")
			continue

		hand.append(card_instance)


func reshuffle_discard_into_draw_pile() -> void:
	if discard_pile.is_empty():
		return

	print("Embaralhando descarte no deck de compra.")

	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()


func discard_hand() -> void:
	for card_instance in hand:
		if card_instance != null:
			discard_pile.append(card_instance)

	hand.clear()


func move_card_from_hand_to_discard(instance_id: int) -> void:
	for i in range(hand.size()):
		var card_instance: CardInstance = hand[i]

		if card_instance != null and card_instance.instance_id == instance_id:
			var removed_card: CardInstance = hand.pop_at(i)
			discard_pile.append(removed_card)
			return

	push_warning("Não foi possível mover carta para descarte: %d" % instance_id)


func find_card_in_hand(instance_id: int) -> CardInstance:
	for card_instance in hand:
		if card_instance != null and card_instance.instance_id == instance_id:
			return card_instance

	return null


func get_draw_count() -> int:
	return draw_pile.size()


func get_hand_count() -> int:
	return hand.size()


func get_discard_count() -> int:
	return discard_pile.size()
