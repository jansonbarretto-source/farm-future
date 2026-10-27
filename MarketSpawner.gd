extends Node2D

@export var customer_scene: PackedScene = preload("res://scenes/customer_npc.tscn")
@export var market_stall_path: NodePath
@export var max_customers_in_scene: int = 6

@onready var timer: Timer = $Timer
var market_stall: Node2D

func _ready() -> void:
	if market_stall_path:
		market_stall = get_node_or_null(market_stall_path)
	if timer:
		timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	if not market_stall or market_stall.get("stock_count") <= 0:
		return
		
	var current_queue_count = 0
	if market_stall.has_method("get_customer_count"):
		current_queue_count = market_stall.get_customer_count()
		
	if current_queue_count >= max_customers_in_scene:
		return
		
	if customer_scene:
		var customer = customer_scene.instantiate()
		
		# Gumamit ng built-in randi_range para sa random mula 1 hanggang 4
		var rand_buyer = randi_range(1, 4)
		print("[MARKET SPAWNER] Piniling Buyer Variant: ", rand_buyer)
		
		# I-set diretso ang buyer_type at tawagin ang initialize
		customer.buyer_type = rand_buyer
		if customer.has_method("initialize"):
			customer.initialize(rand_buyer)
			
		customer.target_stall = market_stall
		customer.global_position = global_position
		
		get_parent().add_child(customer)
