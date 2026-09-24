extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO

	# Check WASD and Arrow Keys directly
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		# Normalize vector so diagonal movement isn't faster
		velocity = input_dir.normalized() * speed
		update_walk_animation(input_dir)
	else:
		velocity = Vector2.ZERO
		update_idle_animation()

	move_and_slide()

func update_walk_animation(dir: Vector2) -> void:
	# Prioritize horizontal or vertical movement
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right")
		sprite.flip_h = dir.x < 0  # Flip left if moving left
	else:
		sprite.flip_h = false
		if dir.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

func update_idle_animation() -> void:
	sprite.flip_h = false
	sprite.play("idle")
