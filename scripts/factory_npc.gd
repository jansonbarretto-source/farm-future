extends Area2D

@export var recipe_key: String = "French Fries"

var player_in_range: bool = false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Visual Indicator Node
var indicator_label: Label
@export var indicator_offset_y: float = -32.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_setup_head_indicator()
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

# Creates the floating indicator above the NPC's head
func _setup_head_indicator() -> void:
	indicator_label = Label.new()
	indicator_label.name = "TalkIndicator"
	indicator_label.text = "💬 [E]"
	indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	indicator_label.position = Vector2(-25, indicator_offset_y)
	indicator_label.custom_minimum_size = Vector2(50, 20)
	
	# Styling
	indicator_label.add_theme_font_size_override("font_size", 11)
	indicator_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	indicator_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	indicator_label.add_theme_constant_override("outline_size", 4)
	
	add_child(indicator_label)
	indicator_label.visible = false # Hidden by default until player approaches

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		_show_indicator(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		_show_indicator(false)

func _show_indicator(show: bool) -> void:
	if not indicator_label:
		return
		
	var tween = create_tween()
	if show:
		indicator_label.visible = true
		indicator_label.modulate.a = 0.0
		indicator_label.position.y = indicator_offset_y + 4.0
		
		tween.set_parallel(true)
		tween.tween_property(indicator_label, "modulate:a", 1.0, 0.2)
		tween.tween_property(indicator_label, "position:y", indicator_offset_y, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(indicator_label, "modulate:a", 0.0, 0.15)
		tween.chain().tween_callback(func(): indicator_label.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_toggle_factory_info_panel()

func _toggle_factory_info_panel() -> void:
	var main_node = get_tree().current_scene
	var existing_layer = main_node.get_node_or_null("FactoryUILayer")
	
	if existing_layer:
		existing_layer.queue_free()
	else:
		_show_recipe_popup_panel(main_node)

func _show_recipe_popup_panel(parent_node: Node) -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "FactoryUILayer"
	
	var ui_node = Control.new()
	ui_node.name = "FactoryInfoUI"
	
	var ui_script = load("res://scripts/FactoryInfoUI.gd")
	if ui_script:
		ui_node.set_script(ui_script)
		canvas_layer.add_child(ui_node)
		parent_node.add_child(canvas_layer)
		ui_node.set_recipe(recipe_key)
