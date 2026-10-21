extends Node2D

@onready var player_camera: Camera2D = $Player/Camera2D
@onready var ground_terrain: TileMapLayer = $Ground_Terrain
@onready var player: CharacterBody2D = $Player
@onready var tile_cursor: Control = $TileCursor
@onready var how_to_play_panel: Control = $CanvasLayer/CenterContainer/HowToPlayPanel
@onready var close_button: Button = $CanvasLayer/CenterContainer/HowToPlayPanel/CloseButton

# Packed Scenes for dynamic spawning
var crop_scene: PackedScene = preload("res://scenes/Crop.tscn")
@export var animal_scene: PackedScene = preload("res://scenes/animal.tscn")

const UNTILLED_SOURCE_ID = 21
const UNTILLED_DIRT_COORDS = Vector2i(0, 0)
const TILLED_SOURCE_ID = 0
const TILLED_DIRT_COORDS = Vector2i(1, 0)
const WATERED_DIRT_COORDS = Vector2i(1, 1)

# List of placeable animals
const ANIMAL_NAMES = ["Chicken", "Cow", "Pig", "Sheep"]

func _ready() -> void:
	_setup_camera_limits()
	
	if tile_cursor:
		tile_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if how_to_play_panel:
		how_to_play_panel.hide()
		
	if close_button:
		close_button.pressed.connect(_on_close_how_to_play_pressed)
		
	await get_tree().create_timer(0.8).timeout
	
	if how_to_play_panel:
		_show_how_to_play_animated()

func _setup_camera_limits() -> void:
	if not ground_terrain or not player_camera:
		print("Warning: ground_terrain or player_camera is unassigned in MainFarm!")
		return
		
	var map_rect = ground_terrain.get_used_rect()
	var tile_size = ground_terrain.tile_set.tile_size

	player_camera.limit_left = map_rect.position.x * tile_size.x
	player_camera.limit_top = map_rect.position.y * tile_size.y
	player_camera.limit_right = map_rect.end.x * tile_size.x
	player_camera.limit_bottom = map_rect.end.y * tile_size.y

func _process(_delta: float) -> void:
	_update_tile_cursor()

# --- FARM BOUNDARY RESTRICTION (Tanging sa loob lang ng bakod ng farm) ---
func _is_inside_farm_boundary(map_pos: Vector2i) -> bool:
	var min_x = -5
	var max_x = 11
	var min_y = 12
	var max_y = 21
	
	return map_pos.x >= min_x and map_pos.x <= max_x and map_pos.y >= min_y and map_pos.y <= max_y

# --- LIVESTOCK BOUNDARY RESTRICTION (Tanging sa loob lang ng Livestock Area) ---
func _is_inside_livestock_boundary(map_pos: Vector2i) -> bool:
	var min_x = 30
	var max_x = 45
	var min_y = 14
	var max_y = 24
	
	return map_pos.x >= min_x and map_pos.x <= max_x and map_pos.y >= min_y and map_pos.y <= max_y

func _update_tile_cursor() -> void:
	if not tile_cursor or not ground_terrain:
		return
		
	var global_mouse_pos = get_global_mouse_position()
	var map_pos = ground_terrain.local_to_map(ground_terrain.to_local(global_mouse_pos))
	
	var current_item = GameData.selected_seed_type if (GameData and "selected_seed_type" in GameData) else ""
	
	# Kung naglalagay ng hayop, icheck ang livestock boundary; kung nagtatanim, icheck ang farm boundary
	if current_item in ANIMAL_NAMES:
		if not _is_inside_livestock_boundary(map_pos):
			tile_cursor.visible = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			return
	else:
		if not _is_inside_farm_boundary(map_pos):
			tile_cursor.visible = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			return
	
	# 1. HIDE TILE CURSOR IF OVER AN EXISTING ANIMAL
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

	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# 2. HIDE TILE CURSOR IF FEEDS / PRODUCE HELD
	if current_item in ["Wheat", "Egg", "Milk", "Manure", "Wool"]:
		tile_cursor.visible = false
		return

	# Show green highlight if holding an animal to place
	tile_cursor.visible = true
	tile_cursor.global_position = ground_terrain.map_to_local(map_pos) - (ground_terrain.tile_set.tile_size / 2.0)
	
	if tile_cursor is ColorRect and current_item in ANIMAL_NAMES:
		tile_cursor.color = Color(0.2, 1.0, 0.4, 0.5) # Soft Green outline for placing animal
	else:
		_update_cursor_color(map_pos)

func _update_cursor_color(map_pos: Vector2i) -> void:
	if not GameData or not "selected_item" in GameData or not "ActiveItem" in GameData:
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if tile_cursor is ColorRect:
		var crop_on_tile = _get_crop_at_tile(map_pos)
		if crop_on_tile and _is_crop_harvestable(crop_on_tile):
			tile_cursor.color = Color(0.2, 1.0, 0.8, 0.4)
			return

		match GameData.selected_item:
			GameData.ActiveItem.HOE:
				if current_source_id == UNTILLED_SOURCE_ID:
					tile_cursor.color = Color(0.2, 1.0, 0.2, 0.4)
				else:
					tile_cursor.color = Color(1.0, 0.2, 0.2, 0.4)
			GameData.ActiveItem.WATERING_CAN:
				if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
					tile_cursor.color = Color(0.2, 0.6, 1.0, 0.4)
				else:
					tile_cursor.color = Color(1.0, 0.2, 0.2, 0.4)
			GameData.ActiveItem.SEED:
				if current_source_id == TILLED_SOURCE_ID and crop_on_tile == null:
					tile_cursor.color = Color(1.0, 0.9, 0.2, 0.4)
				else:
					tile_cursor.color = Color(1.0, 0.2, 0.2, 0.4)

# --- KEYBOARD INPUT (TOGGLE HOW TO PLAY SA PAMAMAGITAN NG 'H' KEY) ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_H or event.physical_keycode == KEY_H:
			if how_to_play_panel:
				if how_to_play_panel.visible:
					_on_close_how_to_play_pressed()
				else:
					_show_how_to_play_animated()

func _unhandled_input(event: InputEvent) -> void:
	if how_to_play_panel and how_to_play_panel.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		var global_click_pos = get_global_mouse_position()
		var map_pos = ground_terrain.local_to_map(ground_terrain.to_local(global_click_pos))
		
		var active_selected = GameData.selected_seed_type if (GameData and "selected_seed_type" in GameData) else ""
		var current_tool = GameData.selected_item if (GameData and "selected_item" in GameData) else -1
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 1. KUNG MAY HAWAK NA ANIMAL AT NASA LOOB NG LIVESTOCK AREA
			if active_selected in ANIMAL_NAMES:
				if not _is_inside_livestock_boundary(map_pos):
					print("[LIVESTOCK] Dito lang pwedeng ilagay ang hayop sa Livestock Area!")
					return
				if _try_place_animal(active_selected, global_click_pos):
					return
				return

			# 2. KUNG ANG HAWAK AY TOOL (HOE O WATERING CAN) O WALA PANG SEED/ANIMAL NA NAKASELECT
			if current_tool == GameData.ActiveItem.HOE or current_tool == GameData.ActiveItem.WATERING_CAN or active_selected == "":
				if not _is_inside_farm_boundary(map_pos):
					return
				if not _try_harvest_tile(map_pos):
					_handle_farm_interaction(map_pos)
				return

			# 3. IBA PANG INTERACTION (HALIMBAWA AY SEEDS)
			if not _is_inside_farm_boundary(map_pos):
				return

			if not _try_harvest_tile(map_pos):
				_handle_farm_interaction(map_pos)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not _is_inside_farm_boundary(map_pos):
				return
			_handle_right_click_undo(map_pos)
		
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_Q:
		if player:
			var player_tile_pos = ground_terrain.local_to_map(ground_terrain.to_local(player.global_position))
			if _is_inside_farm_boundary(player_tile_pos):
				_till_tile(player_tile_pos)

# --- ANIMAL PLACEMENT LOGIC ---

func _try_place_animal(animal_name: String, click_pos: Vector2) -> bool:
	var map_pos = ground_terrain.local_to_map(ground_terrain.to_local(click_pos))
	if not _is_inside_livestock_boundary(map_pos):
		print("[LIVESTOCK] Dito lang pwedeng ilagay ang hayop sa Livestock Area!")
		return false

	if not animal_scene:
		print("[ERROR] animal_scene is missing in main_farm.gd Inspector!")
		return false

	var has_animal = false
	if GameData and "animal_inventory" in GameData and GameData.animal_inventory.get(animal_name, 0) > 0:
		GameData.animal_inventory[animal_name] -= 1
		has_animal = true

	if has_animal:
		if GameData and "crop_inventory" in GameData and GameData.crop_inventory.get(animal_name, 0) > 0:
			GameData.crop_inventory[animal_name] -= 1

		var new_animal = animal_scene.instantiate()
		
		if "animal_type" in new_animal and "AnimalType" in new_animal:
			match animal_name:
				"Chicken":
					new_animal.animal_type = new_animal.AnimalType.CHICKEN
				"Cow":
					new_animal.animal_type = new_animal.AnimalType.COW
				"Pig":
					new_animal.animal_type = new_animal.AnimalType.PIG
				"Sheep":
					new_animal.animal_type = new_animal.AnimalType.SHEEP

		new_animal.global_position = click_pos
		add_child(new_animal)
		
		# --- AUTO-RESET SELECTION KAPAG NAILAPAG NA ANG HAYOP O NAUBOS NA ---
		if GameData:
			if GameData.animal_inventory.get(animal_name, 0) <= 0:
				GameData.selected_seed_type = "" # I-clear lang kung naubos na ang hayop na ito
			if GameData.has_signal("data_changed"):
				GameData.data_changed.emit()
			
		print("[LIVESTOCK] Placed 1x ", animal_name, " at position: ", click_pos)
		return true

	print("[LIVESTOCK] You don't have any ", animal_name, " in inventory!")
	return false

# --- SMOOTH POP-UP ANIMATIONS ---

# --- SMOOTH POP-UP ANIMATIONS NA NAKA-CENTER SA SCREEN ---
# --- SMOOTH POP-UP ANIMATIONS NA NAKA-CENTER SA SCREEN ---
func _show_how_to_play_animated() -> void:
	if not how_to_play_panel:
		return
		
	how_to_play_panel.show()
	
	await get_tree().process_frame
	
	how_to_play_panel.pivot_offset = how_to_play_panel.size / 2.0
	how_to_play_panel.scale = Vector2(0.8, 0.8)
	how_to_play_panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(how_to_play_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(how_to_play_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_close_how_to_play_pressed() -> void:
	if not how_to_play_panel or not how_to_play_panel.visible:
		return
		
	how_to_play_panel.pivot_offset = how_to_play_panel.size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(how_to_play_panel, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(how_to_play_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tween.finished
	how_to_play_panel.hide()

# --- FARMING MECHANICS ---

func _try_harvest_tile(map_pos: Vector2i) -> bool:
	var crop_on_tile = _get_crop_at_tile(map_pos)
	if crop_on_tile and _is_crop_harvestable(crop_on_tile):
		if crop_on_tile.has_method("_harvest"):
			crop_on_tile._harvest()
		else:
			crop_on_tile.queue_free()
			
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		get_viewport().set_input_as_handled()
		return true
		
	return false

func _is_crop_harvestable(crop_node: Node) -> bool:
	if "is_mature" in crop_node:
		return crop_node.is_mature
	elif crop_node.has_method("is_harvestable"):
		return crop_node.is_harvestable()
	elif "current_stage" in crop_node and "Stage" in crop_node:
		return crop_node.current_stage == crop_node.Stage.HARVESTABLE
	return false

func _handle_farm_interaction(map_pos: Vector2i) -> void:
	if not GameData or not "selected_item" in GameData or not "ActiveItem" in GameData:
		return

	if not _is_inside_farm_boundary(map_pos):
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)

	match GameData.selected_item:
		GameData.ActiveItem.HOE:
			_till_tile(map_pos)
			
		GameData.ActiveItem.WATERING_CAN:
			_water_tile(map_pos)
			
		GameData.ActiveItem.SEED:
			if current_source_id == TILLED_SOURCE_ID and (current_tile_coords == TILLED_DIRT_COORDS or current_tile_coords == WATERED_DIRT_COORDS):
				if _get_crop_at_tile(map_pos) != null:
					print("Cannot plant! A seed is already planted on this tile.")
					return

				var current_seed = GameData.selected_seed_type if "selected_seed_type" in GameData else ""
				
				if current_seed in ["Egg", "Milk", "Manure", "Wool"] or current_seed in ANIMAL_NAMES:
					return

				var is_soil_watered = (current_tile_coords == WATERED_DIRT_COORDS)
				
				if GameData.has_method("remove_seeds") and GameData.remove_seeds(current_seed, 1):
					_spawn_crop(map_pos, current_seed, is_soil_watered)
					print("Planted ", current_seed, " seed at: ", map_pos)

func _till_tile(map_pos: Vector2i) -> void:
	if not _is_inside_farm_boundary(map_pos):
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == UNTILLED_SOURCE_ID and current_tile_coords == UNTILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		
		if player and player.has_method("use_hoe"):
			player.use_hoe()

func _water_tile(map_pos: Vector2i) -> void:
	if not _is_inside_farm_boundary(map_pos):
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, WATERED_DIRT_COORDS)
		
		var crop_on_tile = _get_crop_at_tile(map_pos)
		if crop_on_tile and crop_on_tile.has_method("water_crop"):
			crop_on_tile.water_crop()
		
		if player and player.has_method("use_watering_can"):
			player.use_watering_can()

func _handle_right_click_undo(map_pos: Vector2i) -> void:
	if not _is_inside_farm_boundary(map_pos):
		return

	var crop_on_tile = _get_crop_at_tile(map_pos)
	
	if crop_on_tile:
		var seed_type = ""
		if "seed_type" in crop_on_tile:
			seed_type = crop_on_tile.seed_type
		elif "crop_type" in crop_on_tile:
			seed_type = crop_on_tile.crop_type
			
		if seed_type != "" and GameData and GameData.has_method("add_seeds"):
			GameData.add_seeds(seed_type, 1)
		
		crop_on_tile.queue_free()
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == WATERED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		return

	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, UNTILLED_SOURCE_ID, UNTILLED_DIRT_COORDS)
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
