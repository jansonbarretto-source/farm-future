extends Area2D

@export var seed_type: String = "Wheat"
@export var time_per_stage: float = 5.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var growth_timer: Timer = $GrowthTimer

enum Stage { SEED, GROWING, HARVESTABLE }
var current_stage: Stage = Stage.SEED
var is_watered: bool = false

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
	if GameData.SEED_DATA.has(seed_type):
		var info = GameData.SEED_DATA[seed_type]
		
		if info.has("growth_time"):
			time_per_stage = info["growth_time"]
			
		if info.has("scale") and animated_sprite:
			animated_sprite.scale = info["scale"]

func water_crop() -> void:
	if not is_watered:
		is_watered = true
		print(seed_type, " is watered! Growth timer started.")
		if growth_timer:
			growth_timer.wait_time = time_per_stage
			growth_timer.one_shot = false
			growth_timer.start()

func update_crop_visual() -> void:
	if not animated_sprite:
		return
		
	var anim_name = seed_type.to_lower()
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		animated_sprite.stop()
		animated_sprite.frame = current_stage

func _on_growth_timer_timeout() -> void:
	# Mag-grow lamang kung nadiligan na
	if is_watered and current_stage < Stage.HARVESTABLE:
		current_stage += 1 as Stage
		update_crop_visual()
		print(seed_type, " grew to stage: ", current_stage)
		
		if current_stage == Stage.HARVESTABLE:
			growth_timer.stop()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_stage == Stage.HARVESTABLE:
			_harvest()

func _harvest() -> void:
	print("Harvested 1 ", seed_type, "!")
	GameData.add_crop(seed_type, 1)
	queue_free()
