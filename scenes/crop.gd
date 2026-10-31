extends Area2D

@export var seed_type: String = "Wheat"
@export var time_per_stage: float = 5.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var growth_timer: Timer = null

enum Stage { SEED, GROWING, HARVESTABLE }

var current_stage: Stage = Stage.SEED
var is_watered: bool = false
var is_fertilized: bool = false

# --- PEST & PROTECTION SYSTEM VARIABLES ---
var is_infected: bool = false
var is_protected: bool = false
var player_in_range: bool = false
var pest_indicator_node: Control = null

var harvest_particles: Node2D

# --- WEATHER HAZARDS (FLOOD & WITHER MECHANICS) ---
var harvestable_time_elapsed: float = 0.0
@export var max_harvestable_leeway: float = 20.0 

var continuous_rain_time: float = 0.0
@export var max_rain_leeway: float = 15.0 # Para sa GROWING stage

# --- BAGONG LEWAY PARA SA HARVESTABLE NA NABABA SA ULAN (1 MINUTO / 60 SEGUNDO) ---
var harvestable_rain_time: float = 0.0
@export var max_harvestable_rain_leeway: float = 60.0 


# --------------------------------------------------
# PIXEL SPARKLE EFFECT
# --------------------------------------------------
class PixelSparkleEffect extends Node2D:
	var ambient: bool = false
	var elapsed: float = 0.0
	var duration: float = 1.8
	var sparkle_count: int = 4

	var sparkles: Array[Dictionary] = []

	func _ready() -> void:
		z_index = 10

		for i in range(sparkle_count):
			var angle: float = randf_range(0.0, TAU)
			var radius_x: float = randf_range(24.0, 50.0)
			var radius_y: float = randf_range(20.0, 42.0)

			sparkles.append({
				"position": Vector2(
					cos(angle) * radius_x,
					sin(angle) * radius_y - 6.0
				),
				"phase": randf_range(0.0, TAU),
				"speed": randf_range(4.5, 8.0),
				"size": randi_range(5, 8)
			})

	func _process(delta: float) -> void:
		elapsed += delta

		if not ambient and elapsed >= duration:
			queue_free()
			return

		queue_redraw()

	func _draw() -> void:
		for sparkle in sparkles:
			var phase: float = (
				sparkle["phase"] + elapsed * sparkle["speed"]
			)

			var twinkle: float = (sin(phase) + 1.0) * 0.5
			var alpha: float = 0.35 + twinkle * 0.65

			if not ambient:
				var fade: float = minf(
					elapsed / 0.2,
					(duration - elapsed) / 0.3
				)
				alpha *= clampf(fade, 0.0, 1.0)

			if alpha <= 0.05:
				continue

			var pos: Vector2 = sparkle["position"]
			var size: float = float(sparkle["size"])

			var silver := Color(0.88, 0.94, 1.0, alpha)

			draw_rect(
				Rect2(
					pos.x - 2.2,
					pos.y - size * 2.8,
					4.4,
					size * 5.6
				),
				silver
			)

			draw_rect(
				Rect2(
					pos.x - size * 2.8,
					pos.y - 2.2,
					size * 5.6,
					4.4
				),
				silver
			)

			draw_rect(
				Rect2(
					pos.x - 3.0,
					pos.y - 3.0,
					6.0,
					6.0
				),
				Color(1.0, 1.0, 1.0, alpha)
			)

			if size >= 6.0:
				draw_rect(
					Rect2(
						pos.x + size * 2.8,
						pos.y - 1.5,
						4.2,
						4.2
					),
					Color(0.92, 0.96, 1.0, alpha)
				)

				draw_rect(
					Rect2(
						pos.x - size * 2.8,
						pos.y + size * 1.8,
						3.2,
						3.2
					),
					Color(0.82, 0.90, 1.0, alpha * 0.85)
				)


# --------------------------------------------------
# INITIALIZATION
# --------------------------------------------------
func _ready() -> void:
	if not is_in_group("crops"):
		add_to_group("crops")
		
	growth_timer = get_node_or_null("GrowthTimer")
	if not growth_timer:
		growth_timer = get_node_or_null("growthTimer")
	
	if not growth_timer:
		growth_timer = Timer.new()
		growth_timer.name = "GrowthTimer"
		add_child(growth_timer)

	if growth_timer and not growth_timer.timeout.is_connected(
		_on_growth_timer_timeout
	):
		growth_timer.timeout.connect(_on_growth_timer_timeout)

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
		
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	_apply_seed_data()
	
	var should_water = is_watered or (GameData and GameData.current_weather == "Rainy")
	is_watered = false 
	if should_water:
		water_crop()

	update_crop_visual()


func setup_crop(type: String, start_watered: bool = false) -> void:
	seed_type = type
	_apply_seed_data()
	update_crop_visual()

	if start_watered or (GameData and GameData.current_weather == "Rainy"):
		water_crop()


func _apply_seed_data() -> void:
	var target_key = seed_type
	
	if GameData and "SEED_DATA" in GameData:
		for key in GameData.SEED_DATA.keys():
			if key.to_lower() == seed_type.to_lower():
				target_key = key
				break

		if GameData.SEED_DATA.has(target_key):
			var info: Dictionary = GameData.SEED_DATA[target_key]
			if info.has("growth_time"):
				time_per_stage = info["growth_time"]
				return

	time_per_stage = 5.0


# --------------------------------------------------
# PROCESS (WEATHER HAZARDS MONITORING)
# --------------------------------------------------
func _process(delta: float) -> void:
	if not GameData:
		return
		
	if GameData.current_weather == "Rainy":
		if current_stage == Stage.GROWING:
			continuous_rain_time += delta
			if continuous_rain_time >= max_rain_leeway:
				_flood_destroy_crop()
		
		elif current_stage == Stage.HARVESTABLE:
			harvestable_rain_time += delta
			if harvestable_rain_time >= max_harvestable_rain_leeway:
				_flood_destroy_crop()
	else:
		continuous_rain_time = max(0.0, continuous_rain_time - delta * 0.5)
		harvestable_rain_time = max(0.0, harvestable_rain_time - delta * 0.5)

	if current_stage == Stage.HARVESTABLE and GameData.current_weather == "Dry":
		harvestable_time_elapsed += delta
		if harvestable_time_elapsed >= max_harvestable_leeway:
			_wither_crop_due_to_heat()


# --------------------------------------------------
# WATERING
# --------------------------------------------------
func water_crop() -> void:
	if not is_watered:
		is_watered = true
		
		if not growth_timer:
			growth_timer = get_node_or_null("GrowthTimer")
			if not growth_timer:
				growth_timer = Timer.new()
				growth_timer.name = "GrowthTimer"
				add_child(growth_timer)
			if not growth_timer.timeout.is_connected(_on_growth_timer_timeout):
				growth_timer.timeout.connect(_on_growth_timer_timeout)

		if growth_timer:
			growth_timer.wait_time = time_per_stage
			growth_timer.one_shot = false
			growth_timer.start()

		_update_modulate_color()
# --------------------------------------------------
# FERTILIZER LOGIC
# --------------------------------------------------
func apply_fertilizer() -> bool:
	if is_fertilized:
		return false

	var owned_fertilizer: int = (
		GameData.crop_inventory.get("Organic Fertilizer", 0)
		if "crop_inventory" in GameData
		else 0
	)

	if owned_fertilizer > 0:
		GameData.crop_inventory["Organic Fertilizer"] -= 1

		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()

		is_fertilized = true
		_update_modulate_color()

		_play_fertilizer_juice_effects()
		_spawn_sparkle_particles()
		return true

	return false


# --------------------------------------------------
# PEST CONTROL / PESTICIDE LOGIC (VIA 'E' KEY)
# --------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and is_infected and event.is_action_pressed("interact"):
		apply_pesticide()


func apply_pesticide() -> bool:
	if not is_infected:
		return false

	var owned_pesticide: int = (
		GameData.crop_inventory.get("Pesticide", 0)
		if "crop_inventory" in GameData
		else 0
	)

	if owned_pesticide > 0:
		GameData.crop_inventory["Pesticide"] -= 1

		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()

		is_infected = false
		is_protected = true
		
		if is_instance_valid(pest_indicator_node):
			pest_indicator_node.queue_free()

		_update_modulate_color()
		_play_fertilizer_juice_effects()
		_spawn_sparkle_particles()
		return true

	return false


func _trigger_pest_infection() -> void:
	if is_protected or is_infected:
		return

	if randf() <= 0.25:
		is_infected = true
		_update_modulate_color()
		_spawn_pest_indicator()


func _spawn_pest_indicator() -> void:
	if is_instance_valid(pest_indicator_node):
		return

	var bug_label = Label.new()
	bug_label.name = "PestBugIndicator"
	bug_label.text = "🐛"
	bug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bug_label.add_theme_font_size_override("font_size", 42)
	bug_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	bug_label.add_theme_constant_override("outline_size", 6)
	
	bug_label.position = Vector2(-16, -55)
	bug_label.z_index = 50

	pest_indicator_node = bug_label
	add_child(pest_indicator_node)


func _play_fertilizer_juice_effects() -> void:
	if not animated_sprite:
		return

	var orig_scale: Vector2 = animated_sprite.scale
	var tween: Tween = create_tween()

	tween.tween_property(animated_sprite, "scale", orig_scale * Vector2(1.25, 0.75), 0.08)
	tween.tween_property(animated_sprite, "scale", orig_scale * Vector2(0.85, 1.2), 0.08)
	tween.tween_property(animated_sprite, "scale", orig_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_sparkle_particles() -> void:
	var sparkles := PixelSparkleEffect.new()
	sparkles.name = "FertilizerSparkles"
	sparkles.ambient = false
	sparkles.duration = 1.8
	sparkles.sparkle_count = 4
	add_child(sparkles)


func _spawn_harvestable_sparkles() -> void:
	if is_instance_valid(harvest_particles):
		harvest_particles.queue_free()

	harvest_particles = PixelSparkleEffect.new()
	harvest_particles.name = "HarvestableSparkles"
	harvest_particles.ambient = true
	harvest_particles.sparkle_count = 5
	add_child(harvest_particles)


func _update_modulate_color() -> void:
	if not animated_sprite:
		return

	if is_infected:
		animated_sprite.modulate = Color(0.55, 0.45, 0.30, 1.0)
	elif is_protected and is_fertilized:
		animated_sprite.modulate = Color(0.40, 0.75, 0.50, 1.0)
	elif is_protected:
		animated_sprite.modulate = Color(0.60, 0.85, 0.70, 1.0)
	elif is_watered and is_fertilized:
		animated_sprite.modulate = Color(0.48, 0.72, 0.42, 1.0)
	elif is_fertilized:
		animated_sprite.modulate = Color(0.65, 0.55, 0.45, 1.0)
	elif is_watered:
		animated_sprite.modulate = Color(0.7, 0.85, 1.0, 1.0)
	else:
		animated_sprite.modulate = Color.WHITE


func update_crop_visual() -> void:
	if not animated_sprite:
		return

	var anim_name: String = seed_type.to_lower()
	var formatted_type: String = seed_type.capitalize()

	if (
		animated_sprite.sprite_frames
		and animated_sprite.sprite_frames.has_animation(anim_name)
	):
		animated_sprite.play(anim_name)
		animated_sprite.stop()
		animated_sprite.frame = current_stage

		if GameData and "SEED_DATA" in GameData:
			var target_key = formatted_type
			for key in GameData.SEED_DATA.keys():
				if key.to_lower() == seed_type.to_lower():
					target_key = key
					break

			if GameData.SEED_DATA.has(target_key):
				var info: Dictionary = GameData.SEED_DATA[target_key]

				if (
					info.has("stage_scales")
					and current_stage < info["stage_scales"].size()
				):
					animated_sprite.scale = info["stage_scales"][current_stage]
				elif info.has("scale"):
					animated_sprite.scale = info["scale"]

				if (
					info.has("stage_offsets")
					and current_stage < info["stage_offsets"].size()
				):
					animated_sprite.position = info["stage_offsets"][current_stage]
				elif info.has("offset"):
					animated_sprite.position = info["offset"]
				else:
					animated_sprite.position = Vector2.ZERO

		_update_modulate_color()


func _on_growth_timer_timeout() -> void:
	if is_watered and current_stage < Stage.HARVESTABLE:
		current_stage = (current_stage + 1) as Stage

		if current_stage > Stage.SEED:
			_trigger_pest_infection()

		update_crop_visual()

		if is_fertilized and current_stage != Stage.HARVESTABLE:
			_spawn_sparkle_particles()

		if current_stage == Stage.HARVESTABLE:
			growth_timer.stop()
			_spawn_harvestable_sparkles()


func _on_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		var selected_seed: String = (
			GameData.selected_seed_type
			if GameData and "selected_seed_type" in GameData
			else ""
		)

		var selected_inv_item: String = (
			GameData.selected_inventory_item
			if GameData and "selected_inventory_item" in GameData
			else ""
		)

		var active_item = null
		if GameData and "selected_item" in GameData:
			active_item = GameData.selected_item

		if (
			(selected_seed == "Organic Fertilizer" or selected_inv_item == "Organic Fertilizer")
			and current_stage != Stage.HARVESTABLE
		):
			apply_fertilizer()

		elif (
			active_item == GameData.ActiveItem.WATERING_CAN
			and not is_watered
			and current_stage == Stage.SEED
		):
			water_crop()

		elif current_stage == Stage.HARVESTABLE:
			_harvest()


# --------------------------------------------------
# HARVEST & INVENTORY FULL CHECK
# --------------------------------------------------
func _harvest() -> void:
	if current_stage != Stage.HARVESTABLE:
		return

	if is_infected:
		_show_infected_flash_text()
		queue_free()
		return

	var already_owned: bool = false
	if GameData:
		var crop_count = GameData.crop_inventory.get(seed_type, 0)
		var animal_count = GameData.animal_inventory.get(seed_type, 0)
		if crop_count > 0 or animal_count > 0:
			already_owned = true
			
		var current_limit: int = GameData.unlocked_slots if "unlocked_slots" in GameData else 6
			
		if not already_owned and GameData.has_method("get_unique_item_count") and GameData.get_unique_item_count() >= current_limit:
			var inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
			if inventory_ui and inventory_ui.has_method("show_inventory_full_popup"):
				inventory_ui.show_inventory_full_popup()
			else:
				_trigger_fallback_inventory_full_popup()
			return

	var yield_amount: int = 1
	if GameData and "SEED_DATA" in GameData:
		for key in GameData.SEED_DATA.keys():
			if key.to_lower() == seed_type.to_lower():
				yield_amount = GameData.SEED_DATA[key].get("harvest_yield", 1)
				break
	
	if is_fertilized:
		yield_amount *= 2

	if GameData and GameData.has_method("add_crop"):
		GameData.add_crop(seed_type, yield_amount)

	queue_free()


# --------------------------------------------------
# HAZARD POPUPS & DESTRUCTION HANDLERS
# --------------------------------------------------
func _flood_destroy_crop() -> void:
	# --- TUGTUGIN ANG CROP FLOODED SOUND ---
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("crop_flooded")
		
	_show_flooded_flash_text()
	queue_free()


func _wither_crop_due_to_heat() -> void:
	# --- TUGTUGIN ANG CROP WITHER SOUND ---
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("crop_wither")
		
	_show_withered_flash_text()
	queue_free()


func _show_flooded_flash_text() -> void:
	var panel = PanelContainer.new()
	panel.name = "FloodedPopup"
	panel.z_index = 1000
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(0.2, 0.5, 0.9, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "🌊 FLOODED!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	panel.add_child(label)
	
	panel.global_position = global_position + Vector2(-40, -50)
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(panel)
		
	var timer = current_scene.get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if is_instance_valid(panel):
			panel.queue_free()
	)


func _show_withered_flash_text() -> void:
	var panel = PanelContainer.new()
	panel.name = "WitheredPopup"
	panel.z_index = 1000
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(0.9, 0.4, 0.1, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "🔥 WITHERED!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	panel.add_child(label)
	
	panel.global_position = global_position + Vector2(-40, -50)
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(panel)
		
	var timer = current_scene.get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if is_instance_valid(panel):
			panel.queue_free()
	)


func _show_infected_flash_text() -> void:
	var panel = PanelContainer.new()
	panel.name = "InfectedPopup"
	panel.z_index = 1000
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(1.0, 0.3, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "⚠️ INFECTED!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	panel.add_child(label)
	
	panel.global_position = global_position + Vector2(-40, -50)
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(panel)
		
	var timer = current_scene.get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if is_instance_valid(panel):
			panel.queue_free()
	)


func _trigger_fallback_inventory_full_popup() -> void:
	var panel = PanelContainer.new()
	panel.z_index = 1000
	var label = Label.new()
	label.text = "⚠️ INVENTORY IS FULL!"
	panel.add_child(label)
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	canvas.add_child(panel)
	get_tree().current_scene.add_child(canvas)
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		canvas.queue_free()
	)
