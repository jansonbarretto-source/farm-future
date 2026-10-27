extends CharacterBody2D

@export var speed: float = 60.0
var target_stall: Node2D = null
var target_position: Vector2 = Vector2.ZERO

@export var buyer_type: int = 1 :
	set(value):
		buyer_type = value
		if is_node_ready():
			_play_idle_animation()

var is_purchasing: bool = false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("customer")
	buyer_type = randi_range(1, 4)
	_play_idle_animation()
	
	if target_stall and target_stall.has_method("register_customer"):
		target_position = target_stall.register_customer(self)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_stall) or is_purchasing:
		return

	# Awtomatikong aalis kapag naubusan ng stock ang stall
	if target_stall.has_method("get") or "stock_count" in target_stall:
		var current_stock = target_stall.get("stock_count")
		if current_stock != null and current_stock <= 0:
			is_purchasing = true
			_leave_due_to_empty_stock()
			return

	var distance = global_position.distance_to(target_position)

	if distance > 12.0:
		var direction = global_position.direction_to(target_position)
		# Smooth movement gamit ang velocity interpolation kung kinakailangan
		velocity = velocity.move_toward(direction * speed, speed * 10.0 * delta)
		_update_walking_animation(direction)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()
		
		if not is_purchasing and target_stall.has_method("is_first_in_line"):
			if target_stall.is_first_in_line(self):
				is_purchasing = true
				_perform_purchase()

func update_target_position(new_pos: Vector2) -> void:
	target_position = new_pos

func _perform_purchase() -> void:
	_play_idle_animation()
	await get_tree().create_timer(1.0).timeout
	
	if is_instance_valid(target_stall) and target_stall.has_method("buy_item"):
		var earned_price = target_stall.get_item_price()
		var success = target_stall.buy_item()
		
		if success:
			target_stall.unregister_customer(self)
			
			# Ipapakita ang green floating text sa mismong kinaroroonan ng Player
			_spawn_player_floating_text("+₱" + str(earned_price), Color.GREEN)
			
			await _play_vanish_animation()
			queue_free()
		else:
			is_purchasing = false

# Function para lumitaw ang smooth green text sa player
func _spawn_player_floating_text(text: String, color: Color) -> void:
	# Hanapin ang Player sa "player" group
	var player_node = get_tree().get_first_node_in_group("player")
	var spawn_pos = global_position # Fallback kung sakaling hindi mahanap ang player
	
	if player_node:
		spawn_pos = player_node.global_position
		
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.global_position = spawn_pos + Vector2(-15, -35)
	label.z_index = 100
	
	# Idagdag sa main scene para hindi sumama sa pagbura ng customer
	get_tree().current_scene.add_child(label)
	
	# Smooth Tween animation para sa posisyon at fade out
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position:y", label.global_position.y - 40.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)

func _leave_due_to_empty_stock() -> void:
	if target_stall and target_stall.has_method("unregister_customer"):
		target_stall.unregister_customer(self)
		
	_spawn_player_floating_text("Walang Stock!", Color.RED)
	await _play_vanish_animation()
	queue_free()

func _play_vanish_animation() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_property(self, "global_position:y", global_position.y - 12.0, 0.6)
	await tween.finished

func _update_walking_animation(direction: Vector2) -> void:
	var anim_name := "buyer" + str(buyer_type) + "_"

	if abs(direction.x) > abs(direction.y):
		anim_name += "right" if direction.x > 0 else "left"
	else:
		anim_name += "down" if direction.y > 0 else "up"

	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)

func _play_idle_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	var idle_anim := "buyer" + str(buyer_type) + "_idle"

	if animated_sprite.sprite_frames.has_animation(idle_anim):
		if animated_sprite.animation != idle_anim:
			animated_sprite.play(idle_anim)
