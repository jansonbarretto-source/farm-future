extends Area2D
class_name CompostingStation

@export var manure_required: int = 2          # Ilang manure ang kailangan para mag-compost
@export var process_time: float = 10.0         # Seconds bago matapos ang composting
@export var result_item: String = "Organic Fertilizer"

var is_processing: bool = false
var is_ready_to_collect: bool = false

# Variables para sa pagkontrol ng Tweens at Base Scale
var base_sprite_scale: Vector2 = Vector2.ONE
var active_bounce_tween: Tween
var active_label_tween: Tween

@onready var process_timer: Timer = $ProcessTimer
@onready var status_label: Label = $StatusLabel
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	
	process_timer.one_shot = true
	if process_timer.timeout.is_connected(_on_process_complete):
		process_timer.timeout.disconnect(_on_process_complete)
	process_timer.timeout.connect(_on_process_complete)
	
	# I-save ang baseline scale ng sprite pagka-start ng game
	if sprite:
		base_sprite_scale = sprite.scale
		
	_style_status_label()
	_update_station_state()

func _style_status_label() -> void:
	if not status_label:
		return
		
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02, 1.0))
	status_label.add_theme_constant_override("outline_size", 5)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_interaction()

func _handle_interaction() -> void:
	if is_ready_to_collect:
		_collect_fertilizer()
		return

	if not is_processing:
		_try_deposit_manure()
	else:
		print("[COMPOST] Composting in progress... Time remaining: ", int(process_timer.time_left), "s")

func _try_deposit_manure() -> void:
	var owned_manure = GameData.crop_inventory.get("Manure", 0) if "crop_inventory" in GameData else 0
	
	if owned_manure >= manure_required:
		GameData.crop_inventory["Manure"] -= manure_required
		GameData.data_changed.emit()
		
		is_processing = true
		is_ready_to_collect = false
		
		process_timer.wait_time = process_time
		process_timer.start()
		
		_play_bounce_animation()
		print("[COMPOST] Deposited ", manure_required, "x Manure. Composting started!")
		_update_station_state()
	else:
		_show_insufficient_manure_disclaimer(owned_manure)

func _show_insufficient_manure_disclaimer(current_amount: int) -> void:
	print("[COMPOST WARNING] Need 2x Manure! You currently have ", current_amount, "x.")
	
	if not status_label:
		return
		
	status_label.text = "⚠️ NEED 2 MANURE (" + str(current_amount) + "/2)"
	status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	status_label.add_theme_color_override("font_outline_color", Color(0.25, 0.05, 0.02, 1.0))
	
	if active_label_tween and active_label_tween.is_valid():
		active_label_tween.kill()
		
	active_label_tween = create_tween().set_parallel(false)
	active_label_tween.tween_property(status_label, "scale", Vector2(1.2, 0.8), 0.08)
	active_label_tween.tween_property(status_label, "scale", Vector2(0.9, 1.1), 0.08)
	active_label_tween.tween_property(status_label, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2.2).timeout
	if not is_processing and not is_ready_to_collect:
		_update_station_state()

func _on_process_complete() -> void:
	is_processing = false
	is_ready_to_collect = true
	_play_bounce_animation()
	_update_station_state()
	print("[COMPOST] Organic Fertilizer is ready to harvest!")

func _collect_fertilizer() -> void:
	is_ready_to_collect = false
	is_processing = false
	process_timer.stop()
	
	if GameData.has_method("add_crop"):
		GameData.add_crop(result_item, 1)
	
	# Patakbuhin ang bounce at tiyaking babalik sa tamang state
	_play_bounce_animation()
	
	print("[COMPOST] Harvested 1x ", result_item, "!")
	_update_station_state()

# --- BOUNCE ANIMATION EFFECT WITH GUARANTEED RESET ---
func _play_bounce_animation() -> void:
	if not sprite:
		return
		
	# Patayin ang anumang tumatakbong bounce tween para hindi mag-conflict
	if active_bounce_tween and active_bounce_tween.is_valid():
		active_bounce_tween.kill()
		
	active_bounce_tween = create_tween().set_parallel(false)
	
	# 1. Squash
	active_bounce_tween.tween_property(sprite, "scale", base_sprite_scale * Vector2(1.22, 0.78), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 2. Stretch
	active_bounce_tween.tween_property(sprite, "scale", base_sprite_scale * Vector2(0.82, 1.25), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 3. Tiyak na babalik sa base_sprite_scale
	active_bounce_tween.tween_property(sprite, "scale", base_sprite_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_station_state() -> void:
	# I-stop muna ang anumang umiikot na label animation
	if active_label_tween and active_label_tween.is_valid():
		active_label_tween.kill()

	# I-reset ang scale ng sprite at status label
	if sprite:
		sprite.scale = base_sprite_scale
	if status_label:
		status_label.scale = Vector2.ONE

	if is_ready_to_collect:
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("ready"):
			sprite.play("ready")
		
		if status_label:
			status_label.text = "🌱 READY TO HARVEST!"
			status_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.35))
			status_label.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.05, 1.0))
			
			active_label_tween = create_tween().set_loops()
			active_label_tween.tween_property(status_label, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_SINE)
			active_label_tween.tween_property(status_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)

	elif is_processing:
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("processing"):
			sprite.play("processing")
		
		if status_label:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
			status_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02, 1.0))

	else:
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		
		if status_label:
			status_label.text = "💩 DEPOSIT MANURE"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.8))
			status_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.03, 1.0))

func _process(_delta: float) -> void:
	if is_processing and not is_ready_to_collect and status_label:
		status_label.text = "⏳ COMPOSTING... (" + str(int(process_timer.time_left)) + "s)"
