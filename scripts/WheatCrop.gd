extends Area2D

enum Stage { SEED, GROWING, HARVESTABLE }

@export var current_stage: Stage = Stage.SEED
@export var is_watered: bool = false
@export var time_per_stage: float = 5.0 # Seconds per growth stage

@export var custom_scale: Vector2 = Vector2(0.3, 0.3)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var growth_timer: Timer = $GrowthTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if animated_sprite:
		animated_sprite.scale = custom_scale
	
	# Configure Growth Timer
	growth_timer.wait_time = time_per_stage
	growth_timer.one_shot = false
	growth_timer.timeout.connect(_on_growth_timer_timeout)
	
	# Connect Interaction Signal
	input_event.connect(_on_input_event)
	
	_update_crop_visuals()
	# Growth timer starts only after being watered

func _on_growth_timer_timeout() -> void:
	if current_stage == Stage.SEED:
		current_stage = Stage.GROWING
		_update_crop_visuals()
	elif current_stage == Stage.GROWING:
		current_stage = Stage.HARVESTABLE
		_update_crop_visuals()
		growth_timer.stop() # Stop timer once fully grown

func _update_crop_visuals() -> void:
	if not animated_sprite:
		return
		
	match current_stage:
		Stage.SEED:
			animated_sprite.frame = 0
		Stage.GROWING:
			animated_sprite.frame = 1
		Stage.HARVESTABLE:
			animated_sprite.frame = 2

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_player_interaction()

func _handle_player_interaction() -> void:
	var active_item = GameData.selected_item
	
	# Water the unwatered seed to start growth timer
	if active_item == GameData.ActiveItem.WATERING_CAN and not is_watered and current_stage == Stage.SEED:
		water_crop()
		
	# Harvest crop when ready
	elif current_stage == Stage.HARVESTABLE:
		harvest_crop()

func water_crop() -> void:
	is_watered = true
	# Visual feedback: blue tint indicates wet soil/plant
	animated_sprite.modulate = Color(0.7, 0.85, 1.0, 1.0) 
	
	# Start growth countdown now that crop is watered
	growth_timer.start()

func harvest_crop() -> void:
	if "wheat" in GameData:
		GameData.wheat += 1
		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()
			
	queue_free()
