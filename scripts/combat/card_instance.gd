class_name CardInstance
extends RefCounted

var instance_id: int = -1
var card_id: String = ""


func setup(new_instance_id: int, new_card_id: String) -> void:
	instance_id = new_instance_id
	card_id = new_card_id


func is_valid() -> bool:
	return instance_id >= 0 and card_id != ""
