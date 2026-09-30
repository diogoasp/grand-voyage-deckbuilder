extends Control

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu/MainMenuScene.tscn")
const RUN_SCENE: PackedScene = preload("res://scenes/run/RunScene.tscn")
const RECORDS_SCENE: PackedScene = preload("res://scenes/menu/RecordsScene.tscn")

var current_child: Node = null


func _ready() -> void:
	show_main_menu()


func clear_current_child() -> void:
	if current_child != null and is_instance_valid(current_child):
		if current_child.get_parent() == self:
			remove_child(current_child)
		current_child.queue_free()
		current_child = null


func show_main_menu() -> void:
	clear_current_child()
	var menu: Node = MAIN_MENU_SCENE.instantiate()
	current_child = menu
	add_child(menu)

	if menu.has_signal("new_run_selected"):
		menu.new_run_selected.connect(_on_new_run_selected)
	if menu.has_signal("continue_run_selected"):
		menu.continue_run_selected.connect(_on_continue_run_selected)
	if menu.has_signal("records_selected"):
		menu.records_selected.connect(_on_records_selected)


func _on_records_selected() -> void:
	clear_current_child()
	var records: Node = RECORDS_SCENE.instantiate()
	current_child = records
	add_child(records)
	if records.has_signal("back_requested"):
		records.back_requested.connect(show_main_menu)


func _on_new_run_selected() -> void:
	clear_current_child()
	var run: Node = RUN_SCENE.instantiate()
	current_child = run
	add_child(run)
	if run.has_signal("back_to_menu_requested"):
		run.back_to_menu_requested.connect(show_main_menu)
	if run.has_method("start_run"):
		run.start_run()


func _on_continue_run_selected() -> void:
	clear_current_child()
	var run: Node = RUN_SCENE.instantiate()
	current_child = run
	add_child(run)
	if run.has_signal("back_to_menu_requested"):
		run.back_to_menu_requested.connect(show_main_menu)
	if run.has_method("load_saved_run"):
		run.load_saved_run()
