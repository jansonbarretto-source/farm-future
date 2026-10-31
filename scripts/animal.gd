@tool
extends CharacterBody2D

# 1. Explicit integer assignment para hindi mag-shift ang indices sa Inspector
enum AnimalType { 
	CHICKEN = 0, 
	COW = 1, 
	PIG = 2, 
	SHEEP = 3 
}
enum State { IDLE, EATING, WALKING }

# 2. Export variables for Inspector & Feeding/Harvesting
@export var animal_type: AnimalType = AnimalType.CHICKEN:
	set(value):
		animal_type = value
		if is_node_ready():
			_update_editor_preview()

@export var move_speed: float = 20.0
@export var feed_required: String = "Wheat" # What food item this animal eats
@export var hunger_cooldown: float = 30.0    # Specific hunger time per animal (seconds)

var current_state: State = State.IDLE
var walk_direction: Vector2 = Vector2.DOWN
var facing_direction: String = "down"

# Production & Harvesting State
var is_fed: bool = false
var is_ready_for_harvest: bool = false
var harvest_item: String = "Egg"
var harvest_timer: Timer
var hunger_timer: Timer                    # Timer para sa muling pagkagutom

# Sheep Specific Wool Logic (Magsisimula na FALSE / WALANG BALAHIBO sa start!)
var has_wool: bool = false 

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
	
	# SPECIFIC STATS & HUNGER TIME PER ANIMAL TYPE
	if animal_type == AnimalType.COW:
		move_speed = 18.0
		harvest_item = "Milk"
		base_label_y = -42.0
		feed_required = "Wheat"
		hunger_cooldown = 60.0 # Baka: 60 seconds bago magutom uli
	elif animal_type == AnimalType.PIG:
		move_speed = 22.0
		harvest_item = "Manure"
		base_label_y = -32.0
		feed_required = "Carrot"
		hunger_cooldown = 45.0 # Baboy: 45 seconds bago magutom uli
	elif animal_type == AnimalType.SHEEP:
		move_speed = 20.0
		harvest_item = "Wool"
		base_label_y = -35.0
		feed_required = "Wheat"
		has_wool = false
		hunger_cooldown = 50.0 # Tupa: 50 seconds bago magutom uli
	else: # CHICKEN
		move_speed = 30.0
		harvest_item = "Egg"
		base_label_y = -28.0
		feed_required = "Wheat"
		hunger_cooldown = 25.0 # Manok: 25 seconds lang magugutom na uli

	_setup_harvest_timer()
	_setup_hunger_timer()
	_setup_status_label()
	_switch_state(State.EATING)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if current_state == State.WALKING:
		velocity = walk_direction * move_speed
		
		var collided = move_and_slide()
		
		if collided or get_slide_collision_count() > 0:
			velocity = Vector2.ZERO
			_switch_state(State.IDLE)
	else:
		velocity = Vector2.ZERO

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# --- HARVEST & HUNGER TIMERS SETUP ---

func _setup_harvest_timer() -> void:
	harvest_timer = Timer.new()
	harvest_timer.one_shot = true
	harvest_timer.wait_time = 15.0 # Wait time in seconds after feeding
	harvest_timer.timeout.connect(_on_harvest_ready)
	add_child(harvest_timer)

func _setup_hunger_timer() -> void:
	hunger_timer = Timer.new()
	hunger_timer.one_shot = true
	hunger_timer.timeout.connect(_on_became_hungry)
	add_child(hunger_timer)

func _on_harvest_ready() -> void:
	is_ready_for_harvest = true
	
	var produce_text = "🥚 EGG!"
	if harvest_item == "Milk":
		produce_text = "🥛 MILK!"
	elif harvest_item == "Manure":
		produce_text = "💩 MANURE!"
	elif harvest_item == "Wool":
		produce_text = "🧶 WOOL!"
		has_wool = true
		_switch_state(current_state)
		
	_set_status_text(produce_text, Color(1.0, 0.9, 0.3))
	_start_ready_animations()
	
	# --- TUGTUGIN ANG ANIMAL O PRODUCE SOUND KAPAG HANDA NA ANG ANI ---
	if has_node("/root/AudioManager"):
		if animal_type == AnimalType.CHICKEN:
			AudioManager.play_sfx("chicken")
		elif animal_type == AnimalType.COW:
			AudioManager.play_sfx("cow")
		elif animal_type == AnimalType.PIG:
			AudioManager.play_sfx("pig")
		elif animal_type == AnimalType.SHEEP:
			AudioManager.play_sfx("sheep")
	
	print(AnimalType.keys()[animal_type], " has produced a ", harvest_item, "!")

func _on_became_hungry() -> void:
	is_fed = false
	_set_status_text("❗", Color(1.0, 0.2, 0.2)) # Magpapakita uli ang Red Exclamation Sign!
	print("[LIVESTOCK] ", AnimalType.keys()[animal_type], " is hungry again!")

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
	
	float_tween = create_tween().set_loops()
	float_tween.tween_property(status_label, "position:y", base_label_y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(status_label, "position:y", base_label_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
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

func _handle_interaction() -> void:
	if is_ready_for_harvest:
		_harvest_produce()
		return

	if not is_fed:
		_try_feed_animal()
	else:
		print("[LIVESTOCK] ", AnimalType.keys()[animal_type], " is already fed! Wait for produce to spawn.")
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")

func _try_feed_animal() -> void:
	var required_food = feed_required.capitalize()
	var currently_selected_food = GameData.selected_seed_type.capitalize() if "selected_seed_type" in GameData else ""

	# 1. CHECK KUNG ANG NAKATUTOK/SELECTED ITEM SA UI AY TUGMA SA KAILANGAN NG HAYOP
	if currently_selected_food != required_food:
		print("[LIVESTOCK] Wrong food selected! Selected: ", currently_selected_food, " | Needs: ", required_food)
		_show_wrong_food_warning(required_food)
		return

	# 2. CHECK KUNG MAY SAPAT NA PAGKAIN SA INVENTORY
	if "crop_inventory" in GameData and GameData.crop_inventory.get(required_food, 0) > 0:
		GameData.crop_inventory[required_food] -= 1
		GameData.data_changed.emit()
		_feed_success()
	else:
		_show_wrong_food_warning(required_food)

func _show_wrong_food_warning(required_food: String) -> void:
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", 8.0, 0.05)
	tween.tween_property(self, "rotation_degrees", -8.0, 0.05)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.05)
	
	var warning_text = "NEED " + required_food.to_upper() + "!"
	_set_status_text(warning_text, Color(1.0, 0.5, 0.2))
	
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("error")
		
	print("[LIVESTOCK WARNING] ", AnimalType.keys()[animal_type], " needs 1x ", required_food, "!")
	
	get_tree().create_timer(1.8).timeout.connect(func():
		if not is_fed and not is_ready_for_harvest:
			_set_status_text("❗", Color(1.0, 0.2, 0.2))
	)

func _feed_success() -> void:
	is_fed = true
	print("[LIVESTOCK] Successfully fed ", AnimalType.keys()[animal_type], "!")
	
	# --- TUGTUGIN ANG ANIMAL SOUND KAPAG PINAKAIN ---
	if has_node("/root/AudioManager"):
		if animal_type == AnimalType.CHICKEN:
			AudioManager.play_sfx("chicken")
		elif animal_type == AnimalType.COW:
			AudioManager.play_sfx("cow")
		elif animal_type == AnimalType.PIG:
			AudioManager.play_sfx("pig")
		elif animal_type == AnimalType.SHEEP:
			AudioManager.play_sfx("sheep")

	_play_happy_animation()
	_set_status_text("❤️ FED", Color(1.0, 0.85, 0.85))
	
	harvest_timer.start()
	_switch_state(State.EATING)

func _harvest_produce() -> void:
	is_ready_for_harvest = false
	_stop_label_animations()
	
	if GameData.has_method("add_crop"):
		GameData.add_crop(harvest_item, 1)
		
		if animal_type == AnimalType.SHEEP:
			has_wool = false
			_switch_state(current_state)
			
	# --- TUGTUGIN ANG MANURE SOUND O HARVEST SOUND KAPAG KINUHA ANG PRODUKTO ---
	if has_node("/root/AudioManager"):
		if harvest_item == "Manure":
			AudioManager.play_sfx("manure")
		else:
			AudioManager.play_sfx("coin")
			
	print("[LIVESTOCK] Successfully harvested 1x ", harvest_item, "!")
	
	_play_happy_animation()
	
	var tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func(): status_label.visible = false)
	
	# SIMULAN ANG SPECIFIC HUNGER TIME NG ANIMAL
	hunger_timer.start(hunger_cooldown)

func _play_happy_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func reset_daily_fed_status() -> void:
	is_fed = false
	is_ready_for_harvest = false
	_stop_label_animations()
	_set_status_text("❗", Color(1.0, 0.2, 0.2))

# --- AI MOVEMENT & ANIMATION PREFIXES ---

func _get_prefix() -> String:
	match animal_type:
		AnimalType.CHICKEN:
			return "chicken_"
		AnimalType.COW:
			return "cow_"
		AnimalType.PIG:
			return "pig_"
		AnimalType.SHEEP:
			var wool_state = "wool_" if has_wool else "shorn_"
			return "sheep_" + wool_state
	return "chicken_"

func _update_editor_preview() -> void:
	if sprite and sprite.sprite_frames:
		var prefix = _get_prefix()
		var anim = prefix + "eat_down"
		
		if not sprite.sprite_frames.has_animation(anim):
			anim = prefix + "idle" if sprite.sprite_frames.has_animation(prefix + "idle") else prefix + "eat"
			
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)

func _switch_state(new_state: State) -> void:
	current_state = new_state
	var prefix: String = _get_prefix()

	match current_state:
		State.IDLE:
			if sprite.sprite_frames.has_animation(prefix + "idle"):
				sprite.play(prefix + "idle")
			elif sprite.sprite_frames.has_animation(prefix + "walk_" + facing_direction):
				sprite.play(prefix + "walk_" + facing_direction)
				sprite.pause()
				sprite.frame = 0

			timer.start(randf_range(2.0, 4.0))

		State.EATING:
			if sprite.sprite_frames.has_animation(prefix + "eat_" + facing_direction):
				sprite.play(prefix + "eat_" + facing_direction)
			elif sprite.sprite_frames.has_animation(prefix + "eat"):
				sprite.play(prefix + "eat")
			else:
				if sprite.sprite_frames.has_animation(prefix + "idle"):
					sprite.play(prefix + "idle")

			timer.start(randf_range(3.0, 6.0))

		State.WALKING:
			var directions = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
			walk_direction = directions.pick_random()
			_update_facing_direction(walk_direction)

			if sprite.sprite_frames.has_animation(prefix + "walk_" + facing_direction):
				sprite.play(prefix + "walk_" + facing_direction)
			elif sprite.sprite_frames.has_animation(prefix + "walk"):
				sprite.play(prefix + "walk")
				
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
