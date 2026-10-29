extends Area2D

@export var seed_type: String = "Wheat"
@export var time_per_stage: float = 5.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var growth_timer: Timer = $GrowthTimer

enum Stage { SEED, GROWING, HARVESTABLE }

var current_stage: Stage = Stage.SEED
var is_watered: bool = false
var is_fertilized: bool = false

var harvest_particles: Node2D


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
	if growth_timer and not growth_timer.timeout.is_connected(
		_on_growth_timer_timeout
	):
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
	var formatted_type: String = seed_type.capitalize()

	if GameData.SEED_DATA.has(formatted_type):
		var info: Dictionary = GameData.SEED_DATA[formatted_type]

		if info.has("growth_time"):
			time_per_stage = info["growth_time"]


# --------------------------------------------------
# WATERING
# --------------------------------------------------
func water_crop() -> void:
	if not is_watered:
		is_watered = true
		print(seed_type, " is watered! Growth timer started.")

		_update_modulate_color()

		if growth_timer:
			growth_timer.wait_time = time_per_stage
			growth_timer.one_shot = false
			growth_timer.start()


# --------------------------------------------------
# FERTILIZER LOGIC
# --------------------------------------------------
func apply_fertilizer() -> bool:
	if is_fertilized:
		print("[CROP] Crop is already fertilized!")
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

		print(
			"[CROP] Successfully applied Organic Fertilizer to ",
			seed_type,
			"! Harvest yield will multiply by 2x!"
		)

		return true

	print("[CROP WARNING] You need Organic Fertilizer in your inventory!")
	return false


func _play_fertilizer_juice_effects() -> void:
	if not animated_sprite:
		return

	var orig_scale: Vector2 = animated_sprite.scale
	var tween: Tween = create_tween()

	tween.tween_property(
		animated_sprite,
		"scale",
		orig_scale * Vector2(1.25, 0.75),
		0.08
	)

	tween.tween_property(
		animated_sprite,
		"scale",
		orig_scale * Vector2(0.85, 1.2),
		0.08
	)

	tween.tween_property(
		animated_sprite,
		"scale",
		orig_scale,
		0.1
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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

	if is_watered and is_fertilized:
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

		if GameData.SEED_DATA.has(formatted_type):
			var info: Dictionary = GameData.SEED_DATA[formatted_type]

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
	else:
		print("Warning: Walang animation na nagngangalang ", anim_name)


func _on_growth_timer_timeout() -> void:
	if is_watered and current_stage < Stage.HARVESTABLE:
		current_stage = (current_stage + 1) as Stage

		update_crop_visual()

		print(seed_type, " grew to stage: ", current_stage)

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
		var active_item = (
			GameData.selected_item
			if "selected_item" in GameData
			else null
		)

		var selected_seed: String = (
			GameData.selected_seed_type
			if "selected_seed_type" in GameData
			else ""
		)

		if (
			selected_seed == "Organic Fertilizer"
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
	if "current_stage" in self and "Stage" in self:
		if current_stage != Stage.HARVESTABLE:
			return

	# Suriin kung mayroon na ang item na ito sa imbentaryo o kung may count na greater than 0
	var already_owned: bool = false
	if GameData:
		var crop_count = GameData.crop_inventory.get(seed_type, 0)
		var animal_count = GameData.animal_inventory.get(seed_type, 0)
		if crop_count > 0 or animal_count > 0:
			already_owned = true
			
		# Kunin ang dinamikong limitasyon mula sa GameData.unlocked_slots
		var current_limit: int = GameData.unlocked_slots if "unlocked_slots" in GameData else 6
			
		# Kung WALA PA sa imbentaryo at puno na ang mga na-unlock na slots, huwag ituloy ang harvest
		if not already_owned and GameData.has_method("get_unique_item_count") and GameData.get_unique_item_count() >= current_limit:
			print("[HARVEST] Puno na ang imbentaryo! Hindi ma-harvest ang: ", seed_type)
			
			# Ipakita ang pinagandang UI warning box sa gitna ng screen
			var inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
			if inventory_ui and inventory_ui.has_method("show_inventory_full_popup"):
				inventory_ui.show_inventory_full_popup()
			else:
				_trigger_fallback_inventory_full_popup()
				
			return # Hihinto dito at hindi mabubura ang pananim

	# Base yield
	var yield_amount: int = 1
	if GameData and "SEED_DATA" in GameData and GameData.SEED_DATA.has(seed_type):
		yield_amount = GameData.SEED_DATA[seed_type].get("harvest_yield", 1)
	
	# Fertilizer multiplier
	if "is_fertilized" in self and is_fertilized:
		yield_amount *= 2

	# Idagdag sa inventory
	if GameData and GameData.has_method("add_crop"):
		GameData.add_crop(seed_type, yield_amount)

	print("[HARVEST] Harvested ", seed_type, " x", yield_amount)
	queue_free()

func _trigger_fallback_inventory_full_popup() -> void:
	# Lumikha ng PanelContainer para sa magandang background box (Stardew Valley style)
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.z_index = 1000
	
	# Estilo ng panel: Dark brown background na may golden/bronze border at rounded corners
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(0.95, 0.75, 0.35, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_expand_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Lumikha ng Label para sa Text
	var label = Label.new()
	label.text = "⚠️ INVENTORY IS FULL\nBuy more slots to harvest!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	
	panel.add_child(label)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	canvas.add_child(panel)
	get_tree().current_scene.add_child(canvas)
	
	# Smooth Tween Animation (Pop-up effect na may scale at fade out sa panel sa halip na canvas)
	panel.scale = Vector2(0.6, 0.6)
	panel.pivot_offset = Vector2(150, 30)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25)
	
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		var fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_tween.tween_property(panel, "modulate:a", 0.0, 0.4)
		fade_tween.chain().tween_callback(canvas.queue_free)
	)
