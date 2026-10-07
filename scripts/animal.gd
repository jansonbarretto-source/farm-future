@tool
extends CharacterBody2D

# 1. Define animal options (Chicken & Cow)
enum AnimalType { CHICKEN, COW }
enum State { IDLE, EATING, WALKING }

# 2. Export variable for Inspector dropdown
@export var animal_type: AnimalType = AnimalType.CHICKEN:
	set(value):
		animal_type = value
		if is_node_ready():
			_update_editor_preview()

@export var move_speed: float = 20.0

var current_state: State = State.IDLE
var walk_direction: Vector2 = Vector2.DOWN
var facing_direction: String = "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_editor_preview()
		return

	timer.timeout.connect(_on_timer_timeout)
	randomize()
	
	# Adjust movement speed based on animal type
	if animal_type == AnimalType.COW:
		move_speed = 18.0
	else:
		move_speed = 30.0

	_switch_state(State.EATING)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if current_state == State.WALKING:
		velocity = walk_direction * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

# Helper function to get animation prefix
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
