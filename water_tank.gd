# WaterTank.gd (I-attach sa Water Tank Area2D)
extends Area2D

@export var tank_name: String = "Water Tank"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var max_water: float = 100.0
var current_water: float = 0.0
var player_in_range: bool = false
var is_animating: bool = false

var indicator_label: Label
@export var indicator_offset_y: float = -32.0

# Bilis ng pagpuno ng tangke kapag umuulan (bawat segundo)
@export var rain_refill_speed: float = 5.0 

func _ready() -> void:
	input_pickable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_setup_head_indicator()
	_update_tank_animation()

func _setup_head_indicator() -> void:
	indicator_label = Label.new()
	indicator_label.name = "WaterIndicator"
	indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	indicator_label.position = Vector2(-40, indicator_offset_y)
	indicator_label.custom_minimum_size = Vector2(80, 20)
	
	indicator_label.add_theme_font_size_override("font_size", 11)
	indicator_label.add_theme_color_override("font_color", Color.WHITE)
	indicator_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	indicator_label.add_theme_constant_override("outline_size", 4)
	
	add_child(indicator_label)
	indicator_label.visible = false

# --- Kusang mapupuno at mag-a-update ang animation habang umuulan ---
func _process(delta: float) -> void:
	if GameData and GameData.current_weather == "Rainy":
		if current_water < max_water:
			current_water = min(max_water, current_water + rain_refill_speed * delta)
			_update_tank_animation()
			if player_in_range:
				_update_indicator_text()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		_update_indicator_text()
		_show_indicator(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		_show_indicator(false)

func _show_indicator(show: bool) -> void:
	if indicator_label:
		indicator_label.visible = show

func _update_indicator_text() -> void:
	if not indicator_label:
		return
		
	var can_has_water = GameData.watering_can_water > 0 if GameData else false
	
	if current_water < max_water:
		if GameData and GameData.current_weather == "Rainy":
			indicator_label.text = "🌧️ Filling from Rain..."
		elif can_has_water:
			indicator_label.text = "🪣 [E] Pour Water"
		else:
			indicator_label.text = "⚠️ Get Water from River!"
	else:
		indicator_label.text = "💧 [E] Farm Auto-Water!"

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_interact_with_tank()
			get_viewport().set_input_as_handled()

func _interact_with_tank() -> void:
	if is_animating:
		return

	# 1. KAPAG NAGBUHOS NG TUBIG MULA SA ILOG PATUNGO SA TANK
	if current_water < max_water:
		if GameData and GameData.watering_can_water > 0 and not GameData.water_source_is_tank:
			GameData.watering_can_water = max(0.0, GameData.watering_can_water - 8.34)
			current_water = min(max_water, current_water + 33.3)
			
			if GameData.watering_can_water <= 0.0:
				GameData.water_source_is_tank = false
			
			# --- TUGTUGIN ANG WATER TANK FILL SOUND ---
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("water_tank_fill")
			
			is_animating = true
			_update_tank_animation() # Awtomatikong pipili ng filling animation base sa level
			
			# Maghintay sandali o hayaang mag-play ang frame
			await get_tree().create_timer(0.3).timeout
				
			is_animating = false
			_update_indicator_text()
			_update_tank_animation()
		else:
			print("[WATER TANK] Kailangan ng tubig mula sa ilog!")
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("error")
			
	# 2. KAPAG PUNO NA ANG TANKE: Pindutin ang 'E' para i-auto water ang buong farm
	else:
		if current_water > 0:
			current_water = 0.0 # Nakonsumo na ang tubig para sa buong farm
			
			# --- TUGTUGIN ANG WATER TANK FILL O UNLOCK SOUND SA AUTO-WATER ---
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("water_tank_fill")
			
			# --- AUTO-WATERING LOGIC PARA SA LAHAT NG CROPS SA FARM ---
			_trigger_auto_water_all_crops()
			
			is_animating = true
			var drain_anim = "drainig_1" if sprite.sprite_frames.has_animation("drainig_1") else "draining_1"
			if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(drain_anim):
				sprite.play(drain_anim)
				await sprite.animation_finished
				
			is_animating = false
			_update_indicator_text()
			_update_tank_animation()
			print("[WATER TANK] Awtomatikong nadiligan ang buong farm gamit ang tangke!")
		else:
			print("[WATER TANK] Walang laman ang Water Tank!")
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("error")

# --- Awtomatikong didiligan ang lahat ng nakatanim sa farm nang sabay-sabay ---
func _trigger_auto_water_all_crops() -> void:
	var crops = get_tree().get_nodes_in_group("crops")
	for crop in crops:
		if crop.has_method("water_crop") and not crop.is_watered:
			crop.water_crop()

# --- DYNAMIC ANIMATION SELECTION BASE SA DAMI NG TUBIG ---
func _update_tank_animation() -> void:
	if is_animating or not sprite or not sprite.sprite_frames:
		return
		
	if current_water <= 5.0:
		if sprite.sprite_frames.has_animation("idle_empty"):
			sprite.play("idle_empty")
	elif current_water <= 35.0:
		if sprite.sprite_frames.has_animation("Filling_1"):
			sprite.play("Filling_1")
	elif current_water <= 70.0:
		if sprite.sprite_frames.has_animation("Filling_2"):
			sprite.play("Filling_2")
	elif current_water < max_water:
		if sprite.sprite_frames.has_animation("Filling_3"):
			sprite.play("Filling_3")
	else:
		if sprite.sprite_frames.has_animation("idle_full"):
			sprite.play("idle_full") 
