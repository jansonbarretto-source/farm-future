extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_acting: bool = false
var walk_sound_timer: float = 0.0
@export var walk_sound_interval: float = 0.4 # Bilis ng pagitan ng mga tunog habang naglalakad

func _ready() -> void:
	# Ligtas na pag-connect ng signal kung hindi pa nakakonekta
	if sprite and sprite.has_signal("animation_finished"):
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
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
		
		# --- TUGTUGIN ANG WALKING SOUND KUNG GUMAGALAW ---
		walk_sound_timer -= delta
		if walk_sound_timer <= 0.0:
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("walking")
			walk_sound_timer = walk_sound_interval
	else:
		velocity = Vector2.ZERO
		update_idle_animation()
		# Agad na i-reset ang timer para hinto ang tunog pagka-release ng keys
		walk_sound_timer = 0.0

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
