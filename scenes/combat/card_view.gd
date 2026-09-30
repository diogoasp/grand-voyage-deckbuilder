class_name CardView
extends PanelContainer

signal card_drag_started(card_view: CardView)
signal card_drag_ended(card_view: CardView)
signal card_play_requested(card_view: CardView, drop_position: Vector2)

const CARD_SIZE: Vector2 = Vector2(150, 215)

const BASE_POSITION: Vector2 = Vector2.ZERO
const HOVER_POSITION: Vector2 = Vector2(0, -32)

@onready var cost_crystal: PanelContainer = $Margin/CardVBox/HeaderHBox/CostCrystal
@onready var cost_label: Label = $Margin/CardVBox/HeaderHBox/CostCrystal/CostLabel
@onready var name_label: Label = $Margin/CardVBox/HeaderHBox/NameLabel
@onready var art_container: PanelContainer = $Margin/CardVBox/ArtContainer
@onready var art_texture: TextureRect = $Margin/CardVBox/ArtContainer/ArtTexture
@onready var placeholder_art: CenterContainer = $Margin/CardVBox/ArtContainer/PlaceholderArt
@onready var art_icon_label: Label = $Margin/CardVBox/ArtContainer/PlaceholderArt/ArtIconLabel
@onready var type_badge: Label = $Margin/CardVBox/TypeBadge
@onready var description_label: RichTextLabel = $Margin/CardVBox/DescriptionBox/Margin/DescriptionLabel

var instance_id: int = -1
var card_id: String = ""
var cost: int = 0

var is_dragging: bool = false
var is_hovered: bool = false

var drag_offset: Vector2 = Vector2.ZERO
var return_global_position: Vector2 = Vector2.ZERO
var tween: Tween


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(card_instance: CardInstance, card_data: Dictionary) -> void:
	instance_id = card_instance.instance_id
	card_id = card_instance.card_id
	cost = int(card_data.get("cost", 0))

	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	position = BASE_POSITION

	# 1. Custo e Nome
	name_label.text = str(card_data.get("name", card_id))
	cost_label.text = str(cost)

	# 2. Descrição
	description_label.text = str(card_data.get("description", ""))

	# 3. Tipo e Arte Placeholder
	var card_type: String = str(card_data.get("type", "skill")).to_lower()
	var rarity: String = str(card_data.get("rarity", "common")).to_lower()

	match card_type:
		"attack":
			type_badge.text = "• ATAQUE •"
			type_badge.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
			art_icon_label.text = "⚔"
		"skill":
			type_badge.text = "• HABILIDADE •"
			type_badge.add_theme_color_override("font_color", Color(0.45, 0.75, 0.95))
			art_icon_label.text = "🛡"
		"power":
			type_badge.text = "• PODER •"
			type_badge.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
			art_icon_label.text = "⚡"
		_:
			type_badge.text = "• CARTA •"
			type_badge.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
			art_icon_label.text = "📜"

	# 4. Suporte para imagem de arte se fornecida nos dados
	var art_path: String = str(card_data.get("art_path", ""))
	if art_path != "" and ResourceLoader.exists(art_path):
		var tex: Texture2D = load(art_path)
		if tex != null:
			art_texture.texture = tex
			art_texture.visible = true
			placeholder_art.visible = false
		else:
			art_texture.visible = false
			placeholder_art.visible = true
	else:
		art_texture.visible = false
		placeholder_art.visible = true

	# 5. Borda e Moldura conforme a Raridade
	_apply_rarity_styling(rarity)


func _apply_rarity_styling(rarity: String) -> void:
	var border_color := Color(0.35, 0.42, 0.52) # Comum padrão
	match rarity:
		"uncommon":
			border_color = Color(0.2, 0.7, 0.85) # Azul turquesa
		"rare":
			border_color = Color(0.85, 0.4, 0.95) # Roxo místico
		"legendary":
			border_color = Color(0.95, 0.8, 0.25) # Dourado lendário

	# Clona o StyleBox para não vazar a cor entre todas as cartas
	var panel_sb: StyleBox = get_theme_stylebox("panel")
	if panel_sb is StyleBoxFlat:
		var new_sb: StyleBoxFlat = panel_sb.duplicate()
		new_sb.border_color = border_color
		add_theme_stylebox_override("panel", new_sb)


func _gui_input(event: InputEvent) -> void:
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	if event is InputEventMouseButton:
		handle_mouse_button(event)

	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)


func handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		start_drag(event.global_position)
	else:
		end_drag(event.global_position)


func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not is_dragging:
		return

	global_position = event.global_position - drag_offset


func start_drag(mouse_global_position: Vector2) -> void:
	stop_current_tween()

	is_dragging = true
	return_global_position = global_position
	drag_offset = mouse_global_position - global_position
	z_index = 100

	card_drag_started.emit(self)


func end_drag(mouse_global_position: Vector2) -> void:
	if not is_dragging:
		return

	is_dragging = false
	z_index = 0

	card_drag_ended.emit(self)
	card_play_requested.emit(self, mouse_global_position)


func return_to_original_position() -> void:
	stop_current_tween()

	tween = create_tween()
	tween.tween_property(
		self,
		"global_position",
		return_global_position,
		0.15
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_mouse_entered() -> void:
	if is_dragging:
		return

	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	is_hovered = true
	z_index = 10
	animate_to_local_position(HOVER_POSITION)


func _on_mouse_exited() -> void:
	if is_dragging:
		return

	is_hovered = false
	z_index = 0
	animate_to_local_position(BASE_POSITION)


func animate_to_local_position(target_position: Vector2) -> void:
	stop_current_tween()

	tween = create_tween()
	tween.tween_property(
		self,
		"position",
		target_position,
		0.12
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func reset_visual_state() -> void:
	stop_current_tween()
	is_dragging = false
	is_hovered = false
	z_index = 0
	position = BASE_POSITION


func stop_current_tween() -> void:
	if tween != null and tween.is_valid():
		tween.kill()
