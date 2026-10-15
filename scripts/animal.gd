@tool
extends CharacterBody2D

# 1. Define animal options (Chicken & Cow)
enum AnimalType { CHICKEN, COW }
enum State { IDLE, EATING, WALKING }

# 2. Export variables for Inspector & Feeding/Harvesting
@export var animal_type: AnimalType = AnimalType.CHICKEN:
	set(value):
		animal_type = value
		if is_node_ready():
			_update_editor_preview()

@export var move_speed: float = 20.0
@export var feed_required: String = "Wheat" # What food item this animal eats

var current_state: State = State.IDLE
var walk_direction: Vector2 = Vector2.DOWN
var facing_direction: String = "down"

# Production & Harvesting State
var is_fed: bool = false
var is_ready_for_harvest: bool = false
var harvest_item: String = "Egg"
var harvest_timer: Timer

# UI Status Label Node & Animation Tweens
var status_label: Label
var float_tween: Tween
var pulse_tween: Tween
var base_label_y: float = -28.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_editor_preview()
		return

	input_pickable = true

	# Connect hover signals for hand cursor feedback
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	timer.timeout.connect(_on_timer_timeout)
	randomize()
	
	# Adjust stats based on animal type
	if animal_type == AnimalType.COW:
		move_speed = 18.0
		harvest_item = "Milk"
		base_label_y = -42.0
		feed_required = "Wheat"
	else:
		move_speed = 30.0
		harvest_item = "Egg"
		base_label_y = -28.0
		feed_required = "Wheat"

	_setup_harvest_timer()
	_setup_status_label()
	_switch_state(State.EATING)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if current_state == State.WALKING:
		velocity = walk_direction * move_speed
		
		var collided = move_and_slide()
		
		# Stop and switch to IDLE if hitting fences or objects
		if collided or get_slide_collision_count() > 0:
			velocity = Vector2.ZERO
			_switch_state(State.IDLE)
	else:
		velocity = Vector2.ZERO

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# --- HARVEST TIMER SETUP ---

func _setup_harvest_timer() -> void:
	harvest_timer = Timer.new()
	harvest_timer.one_shot = true
	harvest_timer.wait_time = 15.0 # Wait time in seconds after feeding
	harvest_timer.timeout.connect(_on_harvest_ready)
	add_child(harvest_timer)

func _on_harvest_ready() -> void:
	is_ready_for_harvest = true
	
	var produce_text = "🥚 EGG!" if harvest_item == "Egg" else "🥛 MILK!"
	_set_status_text(produce_text, Color(1.0, 0.9, 0.3))
	_start_ready_animations()
	
	print(AnimalType.keys()[animal_type], " has produced a ", harvest_item, "!")

# --- STATUS LABEL SETUP (HUNGRY / FED / READY) ---

func _setup_status_label() -> void:
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	status_label.position = Vector2(-20, base_label_y)
	status_label.custom_minimum_size = Vector2(40, 16)
	
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	status_label.add_theme_constant_override("outline_size", 5)
	
	add_child(status_label)
	
	# Default to Hungry state at start
	_set_status_text("❗", Color(1.0, 0.2, 0.2))

func _stop_label_animations() -> void:
	if float_tween and float_tween.is_running():
		float_tween.kill()
	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()
	
	if status_label:
		status_label.position.y = base_label_y
		status_label.scale = Vector2.ONE

func _start_ready_animations() -> void:
	_stop_label_animations()
	if not status_label:
		return
		
	status_label.pivot_offset = Vector2(20, 8)
	
	# 1. Gentle Floating (Bobbing Up & Down)
	float_tween = create_tween().set_loops()
	float_tween.tween_property(status_label, "position:y", base_label_y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(status_label, "position:y", base_label_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 2. Pulsing Glow Effect
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(status_label, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(status_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _set_status_text(text_string: String, text_color: Color) -> void:
	if not status_label:
		return
		
	_stop_label_animations()
	
	status_label.text = text_string
	status_label.add_theme_color_override("font_color", text_color)
	status_label.visible = true
	status_label.pivot_offset = Vector2(20, 8)
	status_label.scale = Vector2(0.4, 0.4)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(status_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(status_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- INTERACTION, FEEDING & HARVESTING LOGIC ---

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_interaction()
		get_viewport().set_input_as_handled()

func _handle_interaction() -> void:
	# 1. HARVEST PRODUCE IF READY
	if is_ready_for_harvest:
		_harvest_produce()
		return

	# 2. FEED ANIMAL IF NOT FED YET
	if not is_fed:
		_try_feed_animal()
	else:
		print("[LIVESTOCK] ", AnimalType.keys()[animal_type], " is already fed! Wait for produce to spawn.")

func _try_feed_animal() -> void:
	var food_name = feed_required.capitalize()
	
	# STRICT CHECK: Look ONLY at harvested crop_inventory (Bypasses seed inventory completely)
	if "crop_inventory" in GameData and GameData.crop_inventory.get(food_name, 0) > 0:
		GameData.crop_inventory[food_name] -= 1
		GameData.data_changed.emit()
		_feed_success()
		return

	print("[LIVESTOCK WARNING] You must harvest fully-grown ", food_name, " crops from your farm to feed this animal! Seed packs cannot be used.")

func _feed_success() -> void:
	is_fed = true
	print("[LIVESTOCK] Successfully fed ", AnimalType.keys()[animal_type], "!")
	
	_play_happy_animation()
	_set_status_text("❤️ FED", Color(1.0, 0.85, 0.85))
	
	# Start production timer
	harvest_timer.start()
	_switch_state(State.EATING)

func _harvest_produce() -> void:
	is_ready_for_harvest = false
	_stop_label_animations()
	
	if GameData.has_method("add_crop"):
		GameData.add_crop(harvest_item, 1)
	print("[LIVESTOCK] Successfully harvested 1x ", harvest_item, "!")
	
	_play_happy_animation()
	
	# Smoothly fade out status label until daily reset
	var tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func(): status_label.visible = false)

func _play_happy_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Call this when a new day starts to reset status back to Hungry
func reset_daily_fed_status() -> void:
	is_fed = false
	is_ready_for_harvest = false
	_stop_label_animations()
	_set_status_text("❗", Color(1.0, 0.2, 0.2))

# --- AI MOVEMENT & STATES ---

func _get_prefix() -> String:
	match animal_type:
		AnimalType.CHICKEN:
			return "chicken_"
		AnimalType.COW:
			return "cow_"
	return "chicken_"

func _update_editor_preview() -> void:
	if sprite and sprite.sprite_frames:
		var prefix = _get_prefix()
		var anim = prefix + "eat_down"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)

func _switch_state(new_state: State) -> void:
	current_state = new_state
	var prefix: String = _get_prefix()

	match current_state:
		State.IDLE:
			if sprite.sprite_frames.has_animation(prefix + "idle"):
				sprite.play(prefix + "idle")
			else:
				sprite.play(prefix + "walk_" + facing_direction)
				sprite.pause()
				sprite.frame = 0

			timer.start(randf_range(2.0, 4.0))

		State.EATING:
			sprite.play(prefix + "eat_" + facing_direction)
			timer.start(randf_range(3.0, 6.0))

		State.WALKING:
			var directions = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
			walk_direction = directions.pick_random()
			_update_facing_direction(walk_direction)

			sprite.play(prefix + "walk_" + facing_direction)
			timer.start(randf_range(2.0, 4.0))

func _update_facing_direction(dir: Vector2) -> void:
	if dir == Vector2.DOWN:
		facing_direction = "down"
	elif dir == Vector2.UP:
		facing_direction = "up"
	elif dir == Vector2.LEFT:
		facing_direction = "left"
	elif dir == Vector2.RIGHT:
		facing_direction = "right"

func _on_timer_timeout() -> void:
	var roll = randf()
	if roll < 0.45:
		_switch_state(State.EATING)
	elif roll < 0.75:
		_switch_state(State.IDLE)
	else:
		_switch_state(State.WALKING)
