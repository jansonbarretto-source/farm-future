extends Node2D

@export var customer_scene: PackedScene = preload("res://scenes/customer_npc.tscn")
@export var market_stall_path: NodePath
@onready var timer: Timer = $Timer

var market_stall: Node2D

func _ready() -> void:
	if market_stall_path:
		market_stall = get_node_or_null(market_stall_path)
	
	if timer:
		timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	# Only spawn customers if the stall exists and actually has stock for sale
	if market_stall and market_stall.get("stock_count") > 0:
		if customer_scene:
			var customer = customer_scene.instantiate()
			customer.target_stall = market_stall
			customer.global_position = global_position
			get_parent().add_child(customer)
			print("[MARKET SPAWNER] Customer spawned!")
