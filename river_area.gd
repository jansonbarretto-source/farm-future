# RiverArea.gd (I-attach sa Area2D sa tabi ng ilog)
extends Area2D

var player_in_range: bool = false
var indicator_label: Label
var feedback_label: Label
var feedback_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_indicators()

func _setup_indicators() -> void:
	# Main prompt label ([E] Fill Can)
	indicator_label = Label.new()
	indicator_label.text = "💧 [E] Fill Can from River"
	indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator_label.position = Vector2(-70, -30)
	indicator_label.add_theme_font_size_override("font_size", 11)
	indicator_label.add_theme_color_override("font_color", Color.WHITE)
	indicator_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	indicator_label.add_theme_constant_override("outline_size", 4)
	add_child(indicator_label)
	indicator_label.visible = false

	# Green feedback label para sa "Watering Can is Full"
	feedback_label = Label.new()
	feedback_label.text = "Watering Can is Full!"
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(-70, -55)
	feedback_label.add_theme_font_size_override("font_size", 10)
	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	feedback_label.add_theme_constant_override("outline_size", 3)
	add_child(feedback_label)
	feedback_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		indicator_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		indicator_label.visible = false
		feedback_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			if GameData:
				GameData.watering_can_water = GameData.max_watering_can_cap
				GameData.water_source_is_tank = false # Galing ilog, kaya bawal pang-dilig direkta
				print("[RIVER] Puno na ang Watering Can mula sa ilog! Kailangan itong ilipat muna sa Water Tank.")
				_show_green_feedback()
			get_viewport().set_input_as_handled()

func _show_green_feedback() -> void:
	if not feedback_label:
		return
		
	feedback_label.visible = true
	feedback_label.modulate = Color(1, 1, 1, 1)
	feedback_label.position = Vector2(-70, -45)
	
	if feedback_tween and feedback_tween.is_running():
		feedback_tween.kill()
		
	feedback_tween = create_tween().set_parallel(true)
	feedback_tween.tween_property(feedback_label, "position:y", feedback_label.position.y - 20, 0.8)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.8)
	
	await feedback_tween.finished
	feedback_label.visible = false
