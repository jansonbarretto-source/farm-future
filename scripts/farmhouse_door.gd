extends Area2D

# Preload your Sleep Summary UI scene
@export var sleep_ui_scene: PackedScene = preload("res://scenes/SleepSummaryUI.tscn")

var hint_container: PanelContainer = null
var hint_label: Label = null
var player_inside: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	_setup_hint_label()

func _setup_hint_label() -> void:
	hint_container = PanelContainer.new()
	hint_container.visible = false
	hint_container.z_index = 10 # Renders cleanly on top of the house
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.03, 0.95)
	style.border_color = Color(0.85, 0.65, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	hint_container.add_theme_stylebox_override("panel", style)
	
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	hint_container.add_child(hint_label)
	
	# Positioned above the farmhouse doorway
	hint_container.position = Vector2(100, 100)
	add_child(hint_container)

func _unhandled_input(event: InputEvent) -> void:
	# Listen for 'E' key press when the player is standing inside the door zone after 8 PM
	if player_inside and event.is_action_pressed("interact"): # Or use event.is_keycode_pressed(KEY_E)
		_try_to_sleep()

func _on_body_entered(body: Node2D) -> void:
	print("🚨 SOMETHING TOUCHED THE DOOR! Node Name: ", body.name)
	player_inside = true
	_update_hint_text()
	if hint_container:
		hint_container.visible = true

func _on_body_exited(body: Node2D) -> void:
	print("🚪 Body exited door zone: ", body.name)
	player_inside = false
	if hint_container:
		hint_container.visible = false

func _update_hint_text() -> void:
	if not GameData or not hint_label:
		return
		
	if GameData.has_method("can_sleep") and GameData.can_sleep():
		hint_label.text = "🌙 Press [E] to Sleep"
	else:
		hint_label.text = "🔒 Too early! (Sleeps at 8:00 PM)"

func _try_to_sleep() -> void:
	if not GameData:
		return
		
	# Strict 8:00 PM (20:00) check
	if GameData.has_method("can_sleep") and GameData.can_sleep():
		print("[DOOR] Opening sleep summary UI...")
		_open_sleep_transition()
	else:
		print("[DOOR] Too early to sleep. Current game hour is: ", GameData.current_hour)
		_update_hint_text() # Refresh text in case time changed while standing there

func _open_sleep_transition() -> void:
	if hint_container:
		hint_container.visible = false
		
	if sleep_ui_scene:
		var sleep_ui = sleep_ui_scene.instantiate()
		get_tree().root.add_child(sleep_ui)
	else:
		print("[DOOR ERROR] SleepSummaryUI scene is not assigned in Inspector! Calling sleep directly.")
		GameData.sleep_to_next_day()
