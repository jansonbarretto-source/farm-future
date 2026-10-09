extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_acting: bool = false

func _ready() -> void:
	# Connect signal to unlock movement after action animations complete
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float) -> void:
	# Lock player in place while performing an action
	if is_acting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * speed
		update_walk_animation(input_dir)
	else:
		velocity = Vector2.ZERO
		update_idle_animation()

	move_and_slide()

func update_walk_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right")
		sprite.flip_h = dir.x < 0
	else:
		sprite.flip_h = false
		if dir.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

func update_idle_animation() -> void:
	sprite.flip_h = false
	sprite.play("idle")

# Trigger Hoe animation
func use_hoe() -> void:
	is_acting = true
	sprite.play("hoe")

# Trigger Watering animation
func use_watering_can() -> void:
	is_acting = true
	sprite.play("watering")

func _on_animation_finished() -> void:
	if sprite.animation == "hoe" or sprite.animation == "watering":
		is_acting = false
