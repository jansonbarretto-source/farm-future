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
var has_bought: bool = false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("customer")
	buyer_type = randi_range(1, 4)
	_play_idle_animation()
	
	if target_stall and target_stall.has_method("register_customer"):
		target_position = target_stall.register_customer(self)

func _physics_process(delta: float) -> void:
	# Kung nakabili na o kasalukuyang bumibili, huwag nang mag-process
	if not is_instance_valid(target_stall) or is_purchasing or has_bought:
		return

	# Suriin kung naubusan ng stock habang nakapila
	if target_stall.has_method("get") or "stock_count" in target_stall:
		var current_stock = target_stall.get("stock_count")
		if current_stock != null and current_stock <= 0:
			is_purchasing = true # Harangin agad para hindi mag-loop
			_leave_due_to_empty_stock()
			return

	var distance = global_position.distance_to(target_position)

	if distance > 12.0:
		var direction = global_position.direction_to(target_position)
		velocity = velocity.move_toward(direction * speed, speed * 10.0 * delta)
		_update_walking_animation(direction)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()
		
		# ISANG BESES LANG PAPASOK DITO DAHIL SA STATE FLAGS
		if not is_purchasing and not has_bought and target_stall.has_method("is_first_in_line"):
			if target_stall.is_first_in_line(self):
				is_purchasing = true # HARANGIN AGAD BAGO MAG-AWAIT
				_perform_purchase()

func update_target_position(new_pos: Vector2) -> void:
	target_position = new_pos

func _perform_purchase() -> void:
	_play_idle_animation()
	
	# Siguraduhing na-lock na na nakabili na ito para hindi maulit sa susunod na frame
	has_bought = true
	
	await get_tree().create_timer(0.6).timeout
	
	if is_instance_valid(target_stall) and target_stall.has_method("buy_item"):
		var earned_price = target_stall.get_item_price()
		var success = target_stall.buy_item() # Bumibili LAMANG ng 1 quantity
		
		if success:
			if target_stall.has_method("unregister_customer"):
				target_stall.unregister_customer(self)
			
			# Magpakita ng green text sa player
			_spawn_player_floating_text("+₱" + str(earned_price), Color.GREEN)
			
			await _play_vanish_animation()
			queue_free()
		else:
			is_purchasing = false
			has_bought = false

# LIGTAS NA FLOATING TEXT NA SIGURADONG MAG-FA-FADE OUT AT MAG-QUE-QUEUE FREE
func _spawn_player_floating_text(text: String, color: Color) -> void:
	var player_node = get_tree().get_first_node_in_group("player")
	var spawn_pos = global_position 
	
	if player_node:
		spawn_pos = player_node.global_position
		
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.global_position = spawn_pos + Vector2(-20, -35)
	label.z_index = 200 # Mataas na z-index para nasa ibabaw ng world
	
	# Idagdag sa pinaka-root scene
	get_tree().current_scene.add_child(label)
	
	# Explicit Tween Animation na may Callback para sa queue_free()
	var tween = label.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position:y", label.global_position.y - 35.0, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	
	# Kapag natapos ang 1.2s tween, automatic kusa itong mabu-bura sa memory
	tween.chain().tween_callback(label.queue_free)

func _leave_due_to_empty_stock() -> void:
	# Unregister muna sa pila bago magpakita ng text
	if is_instance_valid(target_stall) and target_stall.has_method("unregister_customer"):
		target_stall.unregister_customer(self)
		
	_spawn_player_floating_text("Out of Stock!", Color.RED)
	await _play_vanish_animation()
	queue_free()

func _play_vanish_animation() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "global_position:y", global_position.y - 10.0, 0.5)
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
