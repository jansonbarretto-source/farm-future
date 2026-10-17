extends Area2D

@export var seed_type: String = "Wheat"
@export var time_per_stage: float = 5.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var growth_timer: Timer = $GrowthTimer

enum Stage { SEED, GROWING, HARVESTABLE }
var current_stage: Stage = Stage.SEED
var is_watered: bool = false
var is_fertilized: bool = false # Double Yield State

func _ready() -> void:
	if growth_timer and not growth_timer.timeout.is_connected(_on_growth_timer_timeout):
		growth_timer.timeout.connect(_on_growth_timer_timeout)
		
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	
	_apply_seed_data()
	update_crop_visual()

func setup_crop(type: String, start_watered: bool = false) -> void:
	seed_type = type
	_apply_seed_data()
	update_crop_visual()
	
	if start_watered:
		water_crop()

func _apply_seed_data() -> void:
	# Ensure title case lookup in GameData
	var formatted_type = seed_type.capitalize()
	if GameData.SEED_DATA.has(formatted_type):
		var info = GameData.SEED_DATA[formatted_type]
		
		if info.has("growth_time"):
			time_per_stage = info["growth_time"]

func water_crop() -> void:
	if not is_watered:
		is_watered = true
		print(seed_type, " is watered! Growth timer started.")
		
		_update_modulate_color()
			
		if growth_timer:
			growth_timer.wait_time = time_per_stage
			growth_timer.one_shot = false
			growth_timer.start()

# --- FERTILIZER LOGIC WITH VFX ---
func apply_fertilizer() -> bool:
	if is_fertilized:
		print("[CROP] Crop is already fertilized!")
		return false
		
	# Check if player has Organic Fertilizer in inventory
	var owned_fertilizer = GameData.crop_inventory.get("Organic Fertilizer", 0) if "crop_inventory" in GameData else 0
	
	if owned_fertilizer > 0:
		GameData.crop_inventory["Organic Fertilizer"] -= 1
		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()
			
		is_fertilized = true
		_update_modulate_color()
		
		# Patakbuhin ang visual at physical juices para sa laro
		_play_fertilizer_juice_effects()
		_spawn_sparkle_particles()
		
		print("[CROP] Successfully applied Organic Fertilizer to ", seed_type, "! Harvest yield will double (2x)!")
		return true
	else:
		print("[CROP WARNING] You need Organic Fertilizer in your inventory!")
		return false

# 1. Panginginig at Paglaki-maliit ng Sprite (Juice Animation)
func _play_fertilizer_juice_effects() -> void:
	if not animated_sprite:
		return
		
	var orig_scale = animated_sprite.scale
	var tween = create_tween().set_parallel(false)
	
	# Mabilis na talbog at shake para maramdamang may "impact" ang pagbudbod
	tween.tween_property(animated_sprite, "scale", orig_scale * Vector2(1.25, 0.75), 0.08) # Mapipe
	tween.tween_property(animated_sprite, "scale", orig_scale * Vector2(0.85, 1.2), 0.08) # Statayog
	tween.tween_property(animated_sprite, "scale", orig_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# 2. Paglikha ng Sparkle Particles para sa Mahiwagang Epekto ng Fertilizer
func _spawn_sparkle_particles() -> void:
	# Gagawa tayo ng CPUParticles2D sa code para walang kailangang bagong eksena/asset
	var particles = CPUParticles2D.new()
	add_child(particles)
	
	particles.position = Vector2(0, 4) # Itapat sa tapat ng lupa
	particles.emitting = true
	particles.amount = 18
	particles.one_shot = true
	particles.explosiveness = 0.5
	particles.lifetime = 1.2
	
	# Setting Particle Physics
	particles.direction = Vector2(0, -1) # Paitaas
	particles.spread = 75.0
	particles.gravity = Vector2(0, -5) # Tila bula o sparkle na dahan-dahans umaakyat
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 35.0
	
	# Aesthetic Settings (Organic Magic Green & Gold)
	particles.color_ramp = Gradient.new()
	particles.color_ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	particles.color_ramp.colors = PackedColorArray([
		Color(0.8, 1.0, 0.3, 1.0), # Bright Yellow-Green
		Color(0.2, 0.9, 0.4, 1.0), # Magic green
		Color(0.1, 0.6, 0.2, 0.7), # Organic Green fade
		Color(0.1, 0.4, 0.2, 0.0)  # Fade to zero
	])
	
	# Random Sizes para sa pixel feeling
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	
	# Burahin ang Particle Node pagkatapos ng 2 segundo
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func _update_modulate_color() -> void:
	if not animated_sprite:
		return
		
	# Kulay ng "May Pataba at Tubig"
	# Madilim at mayabong na organic brown-green tint (Isang rich at maputik na overlay)
	if is_watered and is_fertilized:
		animated_sprite.modulate = Color(0.48, 0.72, 0.42, 1.0) # Madilim na Lush/Muddy Green-Blue tint
	elif is_fertilized:
		animated_sprite.modulate = Color(0.65, 0.55, 0.45, 1.0) # Mayaman/Madilim na Organic Earth Soil brown-yellow tint
	elif is_watered:
		animated_sprite.modulate = Color(0.7, 0.85, 1.0, 1.0) # Normal na basang kulay
	else:
		animated_sprite.modulate = Color.WHITE

func update_crop_visual() -> void:
	if not animated_sprite:
		return
		
	var anim_name = seed_type.to_lower()
	var formatted_type = seed_type.capitalize()
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		animated_sprite.stop()
		animated_sprite.frame = current_stage
		
		if GameData.SEED_DATA.has(formatted_type):
			var info = GameData.SEED_DATA[formatted_type]
			
			# 1. Dynamic Scale per Stage
			if info.has("stage_scales") and current_stage < info["stage_scales"].size():
				animated_sprite.scale = info["stage_scales"][current_stage]
			elif info.has("scale"):
				animated_sprite.scale = info["scale"]
				
			# 2. Dynamic Position Offset per Stage
			if info.has("stage_offsets") and current_stage < info["stage_offsets"].size():
				animated_sprite.position = info["stage_offsets"][current_stage]
			elif info.has("offset"):
				animated_sprite.position = info["offset"]
			else:
				animated_sprite.position = Vector2.ZERO
	else:
		print("Warning: Walang animation na nagngangalang ", anim_name)

func _on_growth_timer_timeout() -> void:
	if is_watered and current_stage < Stage.HARVESTABLE:
		current_stage = (current_stage + 1) as Stage
		update_crop_visual()
		print(seed_type, " grew to stage: ", current_stage)
		
		# Kung nag-grow pero may fertilizer pa rin, magpakita uli ng kaunting sparkles
		if is_fertilized and current_stage != Stage.HARVESTABLE:
			_spawn_sparkle_particles()
		
		if current_stage == Stage.HARVESTABLE:
			growth_timer.stop()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var active_item = GameData.selected_item if "selected_item" in GameData else null
		var selected_seed = GameData.selected_seed_type if "selected_seed_type" in GameData else ""
		
		# 1. Apply Organic Fertilizer if selected in Inventory/Hotbar and crop is not yet harvestable
		if selected_seed == "Organic Fertilizer" and current_stage != Stage.HARVESTABLE:
			apply_fertilizer()
		# 2. Water crop if watering can is selected and plant is not watered yet
		elif active_item == GameData.ActiveItem.WATERING_CAN and not is_watered and current_stage == Stage.SEED:
			water_crop()
		# 3. Harvest crop if ready
		elif current_stage == Stage.HARVESTABLE:
			_harvest()

func _harvest() -> void:
	var formatted_type = seed_type.capitalize()
	
	# DOUBLE YIELD LOGIC: 2x crops if fertilized, otherwise 1x
	var yield_amount: int = 2 if is_fertilized else 1
	
	if is_fertilized:
		print("⭐ HARVEST BONUS! Harvested ", yield_amount, "x ", formatted_type, " (Double Yield)!")
	else:
		print("Harvested ", yield_amount, "x ", formatted_type, "!")
	
	if GameData.has_method("add_crop"):
		GameData.add_crop(formatted_type, yield_amount)
	else:
		if formatted_type in GameData.crop_inventory:
			GameData.crop_inventory[formatted_type] += yield_amount
		else:
			GameData.crop_inventory[formatted_type] = yield_amount
			
		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()
			
	queue_free()
