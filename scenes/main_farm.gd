extends Node2D

@onready var player_camera: Camera2D = $Player/Camera2D
@onready var ground_terrain: TileMapLayer = $Ground_Terrain
@onready var player: CharacterBody2D = $Player
@onready var tile_cursor: Control = $TileCursor
@onready var how_to_play_panel: Control = $HowToPlayPanel
@onready var close_button: Button = $HowToPlayPanel/CloseButton

var crop_scene: PackedScene = preload("res://scenes/Crop.tscn")

const UNTILLED_SOURCE_ID = 21
const UNTILLED_DIRT_COORDS = Vector2i(0, 0)
const TILLED_SOURCE_ID = 0
const TILLED_DIRT_COORDS = Vector2i(1, 0)
const WATERED_DIRT_COORDS = Vector2i(1, 1)

func _ready() -> void:
	_setup_camera_limits()
	
	if tile_cursor:
		tile_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Ensure the panel starts completely hidden
	if how_to_play_panel:
		how_to_play_panel.hide()
		
	# Connect CloseButton pressed signal
	if close_button:
		close_button.pressed.connect(_on_close_how_to_play_pressed)
		
	# DELAY: Let the player see the farm scene for 0.8 seconds before popping up instructions
	await get_tree().create_timer(0.8).timeout
	
	if how_to_play_panel:
		_show_how_to_play_animated()

func _setup_camera_limits() -> void:
	var map_rect = ground_terrain.get_used_rect()
	var tile_size = ground_terrain.tile_set.tile_size

	player_camera.limit_left = map_rect.position.x * tile_size.x
	player_camera.limit_top = map_rect.position.y * tile_size.y
	player_camera.limit_right = map_rect.end.x * tile_size.x
	player_camera.limit_bottom = map_rect.end.y * tile_size.y

func _process(_delta: float) -> void:
	_update_tile_cursor()

# Snaps the visual cursor outline to the tile under the mouse cursor and updates color feedback
func _update_tile_cursor() -> void:
	if not tile_cursor or not ground_terrain:
		return
		
	var global_mouse_pos = get_global_mouse_position()
	
	# --- 1. HIDE TILE CURSOR IF OVER ANIMAL OR LIVESTOCK OBJECT ---
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_mouse_pos
	query.collide_with_bodies = true
	var results = space_state.intersect_point(query)
	
	for result in results:
		if result.collider is CharacterBody2D and (result.collider.has_method("_handle_interaction") or "animal_type" in result.collider):
			tile_cursor.visible = false
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			return

	# Reset cursor shape to normal if not hovering an animal
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# --- 2. HIDE TILE CURSOR IF A CROP / LIVESTOCK FEED (LIKE WHEAT) IS ACTIVE ---
	if GameData.selected_item == GameData.ActiveItem.SEED:
		var current_item = GameData.selected_seed_type
		# If Wheat or non-sowable feed is held, hide tile highlight
		if current_item in ["Wheat", "Egg", "Milk"]:
			tile_cursor.visible = false
			return

	tile_cursor.visible = true
	var map_pos = ground_terrain.local_to_map(ground_terrain.to_local(global_mouse_pos))
	
	tile_cursor.global_position = ground_terrain.map_to_local(map_pos) - (ground_terrain.tile_set.tile_size / 2.0)
	_update_cursor_color(map_pos)

func _update_cursor_color(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if tile_cursor is ColorRect:
		var crop_on_tile = _get_crop_at_tile(map_pos)
		if crop_on_tile and _is_crop_harvestable(crop_on_tile):
			tile_cursor.color = Color(0.2, 1.0, 0.8, 0.4) # Cyan for Harvest ready
			return

		match GameData.selected_item:
			GameData.ActiveItem.HOE:
				if current_source_id == UNTILLED_SOURCE_ID:
					tile_cursor.color = Color(0.2, 1.0, 0.2, 0.4) # Green
				else:
					tile_cursor.color = Color(1.0, 0.2, 0.2, 0.4) # Red
			GameData.ActiveItem.WATERING_CAN:
				if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
					tile_cursor.color = Color(0.2, 0.6, 1.0, 0.4) # Blue
				else:
					tile_cursor.color = Color(1.0, 0.2, 0.2, 0.4)
			GameData.ActiveItem.SEED:
				if current_source_id == TILLED_SOURCE_ID and crop_on_tile == null:
					tile_cursor.color = Color(1.0, 0.9, 0.2, 0.4) # Yellow
				else:
					tile_cursor.color = Color(1.0, 0.2, 0.2, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	# Prevent farm tile actions while instructions panel is visible
	if how_to_play_panel and how_to_play_panel.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		var global_click_pos = get_global_mouse_position()
		var map_pos = ground_terrain.local_to_map(ground_terrain.to_local(global_click_pos))
		
		# Left Click -> Harvest FIRST, then Tool Actions
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _try_harvest_tile(map_pos):
				_handle_farm_interaction(map_pos)
			
		# Right Click -> Smart Undo (Crop -> Water -> Tilled Soil)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click_undo(map_pos)
		
	# Press 'Q' to Till tile under Player
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_Q:
		if player:
			var player_tile_pos = ground_terrain.local_to_map(ground_terrain.to_local(player.global_position))
			_till_tile(player_tile_pos)

# --- SMOOTH POP-UP ANIMATIONS ---

func _show_how_to_play_animated() -> void:
	how_to_play_panel.show()
	
	# Set pivot point to the center of the panel for balanced scaling
	how_to_play_panel.pivot_offset = how_to_play_panel.size / 2.0
	
	# Start state (Small & Transparent)
	how_to_play_panel.scale = Vector2(0.8, 0.8)
	how_to_play_panel.modulate.a = 0.0
	
	# Create Smooth Entrance Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(how_to_play_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(how_to_play_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_close_how_to_play_pressed() -> void:
	if not how_to_play_panel or not how_to_play_panel.visible:
		return
		
	# Ensure pivot is centered for shrinking
	how_to_play_panel.pivot_offset = how_to_play_panel.size / 2.0
	
	# Create Smooth Exit Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(how_to_play_panel, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(how_to_play_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Hide panel once animation completes
	await tween.finished
	how_to_play_panel.hide()

# --- FARMING MECHANICS ---

func _try_harvest_tile(map_pos: Vector2i) -> bool:
	var crop_on_tile = _get_crop_at_tile(map_pos)
	if crop_on_tile and _is_crop_harvestable(crop_on_tile):
		var crop_name = ""
		if "seed_type" in crop_on_tile:
			crop_name = crop_on_tile.seed_type
		elif "crop_type" in crop_on_tile:
			crop_name = crop_on_tile.crop_type
			
		if crop_name != "":
			if GameData.has_method("add_crop"):
				GameData.add_crop(crop_name, 1)
			elif GameData.has_method("add_item"):
				GameData.add_item(crop_name, 1)
			print("Harvested 1x ", crop_name, " from tile: ", map_pos)
		
		crop_on_tile.queue_free()
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		return true
		
	return false

func _is_crop_harvestable(crop_node: Node) -> bool:
	if "is_mature" in crop_node:
		return crop_node.is_mature
	elif crop_node.has_method("is_harvestable"):
		return crop_node.is_harvestable()
	return false

func _handle_farm_interaction(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)

	match GameData.selected_item:
		GameData.ActiveItem.HOE:
			_till_tile(map_pos)
			
		GameData.ActiveItem.WATERING_CAN:
			_water_tile(map_pos)
			
		GameData.ActiveItem.SEED:
			# Plant on dry tilled soil or wet watered soil (Strict 1-seed per tile check)
			if current_source_id == TILLED_SOURCE_ID and (current_tile_coords == TILLED_DIRT_COORDS or current_tile_coords == WATERED_DIRT_COORDS):
				if _get_crop_at_tile(map_pos) != null:
					print("Cannot plant! A seed is already planted on this tile.")
					return

				var current_seed = GameData.selected_seed_type
				
				# Prevent planting raw non-sowable products
				if current_seed in ["Egg", "Milk"]:
					print("Cannot plant produce!")
					return

				var is_soil_watered = (current_tile_coords == WATERED_DIRT_COORDS)
				
				if GameData.remove_seeds(current_seed, 1):
					_spawn_crop(map_pos, current_seed, is_soil_watered)
					print("Planted ", current_seed, " seed at: ", map_pos)
				else:
					print("No ", current_seed, " seeds in inventory!")

func _till_tile(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == UNTILLED_SOURCE_ID and current_tile_coords == UNTILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		print("Successfully tilled ground at: ", map_pos)
		
		if player and player.has_method("use_hoe"):
			player.use_hoe()
	else:
		print("Cannot till tile at ", map_pos)

func _water_tile(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, WATERED_DIRT_COORDS)
		print("Successfully watered ground at: ", map_pos)
		
		var crop_on_tile = _get_crop_at_tile(map_pos)
		if crop_on_tile and crop_on_tile.has_method("water_crop"):
			crop_on_tile.water_crop()
		
		if player and player.has_method("use_watering_can"):
			player.use_watering_can()
	else:
		print("Cannot water tile at ", map_pos)

func _handle_right_click_undo(map_pos: Vector2i) -> void:
	var crop_on_tile = _get_crop_at_tile(map_pos)
	
	# 1. UNDO SEED: Remove crop & refund seed
	if crop_on_tile:
		var seed_type = ""
		if "seed_type" in crop_on_tile:
			seed_type = crop_on_tile.seed_type
		elif "crop_type" in crop_on_tile:
			seed_type = crop_on_tile.crop_type
			
		if seed_type != "":
			GameData.add_seeds(seed_type, 1)
			print("Undid seed! Returned 1x ", seed_type, " back to inventory.")
		
		crop_on_tile.queue_free()
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	# 2. UNDO WATER: Dry soil back to dry tilled dirt
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == WATERED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		print("Undid water! Tile is now dry tilled dirt at: ", map_pos)
		return

	# 3. UNDO HOE: Revert to raw untilled dirt
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, UNTILLED_SOURCE_ID, UNTILLED_DIRT_COORDS)
		print("Undid hoe! Reverted ground back to untilled dirt at: ", map_pos)
		return

func _get_crop_at_tile(map_pos: Vector2i) -> Node:
	var tile_world_pos = ground_terrain.map_to_local(map_pos)
	for child in get_children():
		if (child.has_method("setup_crop") or child.has_method("water_crop")) and child.global_position.distance_to(tile_world_pos) < 8.0:
			return child
	return null

func _spawn_crop(map_pos: Vector2i, seed_type: String, start_watered: bool = false) -> void:
	var crop_instance = crop_scene.instantiate()
	crop_instance.global_position = ground_terrain.map_to_local(map_pos)
	
	if crop_instance.has_method("setup_crop"):
		crop_instance.setup_crop(seed_type, start_watered)
		
	add_child(crop_instance)
