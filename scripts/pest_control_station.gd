extends StaticBody2D

@export var craft_cost: Dictionary = {"Tomato": 2, "Potato": 1}
@export var craft_duration: float = 5.0

enum State { WAITING_FOR_INGREDIENTS, PROCESSING, READY_TO_COLLECT }
var current_state: State = State.WAITING_FOR_INGREDIENTS

var player_in_range: bool = false
var craft_timer: float = 0.0

var status_panel: PanelContainer
var status_label: Label
var active_label_tween: Tween

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Dahil StaticBody2D ito, ikinakabit natin ang signals sa Area2D child node para sa range detection
	if has_node("Area2D"):
		$Area2D.body_entered.connect(_on_body_entered)
		$Area2D.body_exited.connect(_on_body_exited)
	
	_setup_status_ui()
	update_status_display()

func _process(delta: float) -> void:
	if current_state == State.PROCESSING:
		craft_timer -= delta
		if status_label:
			status_label.text = "⏳ PROCESSING... (" + str(snapped(craft_timer, 0.1)) + "s)"
			
		if craft_timer <= 0.0:
			current_state = State.READY_TO_COLLECT
			update_status_display()
			_play_bounce_effect() # <--- Bounce kapag tapos na ang processing!

func _setup_status_ui() -> void:
	if has_node("StatusPanel"):
		status_panel = $StatusPanel
		status_label = status_panel.get_node("StatusLabel")
		return

	status_panel = PanelContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.position = Vector2(-45, -45)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.85)
	style.border_color = Color(0.58, 0.40, 0.22, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	status_panel.add_theme_stylebox_override("panel", style)
	
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	status_label.add_theme_constant_override("outline_size", 4)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	status_panel.add_child(status_label)
	add_child(status_panel)
	status_panel.visible = false

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		if status_panel:
			status_panel.visible = true
		update_status_display()

func _on_body_exited(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		if status_panel:
			status_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		handle_station_interaction()

func handle_station_interaction() -> void:
	match current_state:
		State.WAITING_FOR_INGREDIENTS:
			try_start_crafting()
		State.READY_TO_COLLECT:
			collect_pesticide()

func try_start_crafting() -> void:
	# 1. Thoroughly verify if there are enough ingredients before processing
	var has_ingredients = true
	for item in craft_cost.keys():
		var required = craft_cost[item]
		if not GameData.has_item(item, required):
			has_ingredients = false
			break
			
	# 2. If available, consume ingredients and start timer. If not, show warning.
	if has_ingredients:
		for item in craft_cost.keys():
			GameData.remove_item(item, craft_cost[item])
			
		current_state = State.PROCESSING
		craft_timer = craft_duration
		print("[PEST CONTROL] Processing started...")
		update_status_display()
		_play_bounce_effect() # <--- Bounce kapag pinindot ang [E] para mag-start!
	else:
		print("[PEST CONTROL] Not enough ingredients! Cannot process.")
		_show_warning_text("⚠️ INGREDIENTS LACKING")

func _show_warning_text(warn_text: String) -> void:
	if not status_label:
		return
	status_label.text = warn_text
	status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	
	if active_label_tween and active_label_tween.is_valid():
		active_label_tween.kill()
		
	active_label_tween = create_tween()
	active_label_tween.tween_property(status_label, "scale", Vector2(1.15, 1.15), 0.08)
	active_label_tween.tween_property(status_label, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Revert text back to normal after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(func():
		if current_state == State.WAITING_FOR_INGREDIENTS:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
			update_status_display()
	)

func collect_pesticide() -> void:
	GameData.add_crop("Pesticide", 1)
	print("[PEST CONTROL] Collected 1 Pesticide!")
	current_state = State.WAITING_FOR_INGREDIENTS
	update_status_display()
	_play_bounce_effect() # <--- Bounce kapag kinolekta ang pesticide gamit ang [E]!

func update_status_display() -> void:
	if not status_label:
		return
		
	match current_state:
		State.WAITING_FOR_INGREDIENTS:
			status_label.text = "🧪 NEED POTATO & TOMATO [E]"
		State.PROCESSING:
			status_label.text = "⏳ PROCESSING..."
		State.READY_TO_COLLECT:
			status_label.text = "✨ COLLECT PESTICIDE [E]"

func _play_bounce_effect() -> void:
	# Sinisiguro natin na mahahanap nito ang AnimatedSprite2D node nang ligtas
	var sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else find_child("AnimatedSprite2D", true, false)
	if not sprite:
		print("[WARNING] AnimatedSprite2D not found for bounce effect!")
		return

	var orig_scale: Vector2 = sprite.scale
	var tween: Tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		orig_scale * Vector2(1.25, 0.75),
		0.08
	)

	tween.tween_property(
		sprite,
		"scale",
		orig_scale * Vector2(0.85, 1.2),
		0.08
	)

	tween.tween_property(
		sprite,
		"scale",
		orig_scale,
		0.1
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
