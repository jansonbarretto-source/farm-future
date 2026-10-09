extends Node2D

@onready var player_camera: Camera2D = $Player/Camera2D
@onready var ground_terrain: TileMapLayer = $Ground_Terrain
@onready var player: CharacterBody2D = $Player

var wheat_crop_scene: PackedScene = preload("res://scenes/WheatCrop.tscn")

# Untilled Dirt Ground (Inside Fence Area)
const UNTILLED_SOURCE_ID = 21
const UNTILLED_DIRT_COORDS = Vector2i(0, 0)

# Tilled Dirt Ground (Target Soil when Hoed)
const TILLED_SOURCE_ID = 0
const TILLED_DIRT_COORDS = Vector2i(1, 0)

# Watered Dirt Ground (Dark Wet Soil)
const WATERED_DIRT_COORDS = Vector2i(1, 1)

func _ready() -> void:
	_setup_camera_limits()

func _setup_camera_limits() -> void:
	var map_rect = ground_terrain.get_used_rect()
	var tile_size = ground_terrain.tile_set.tile_size

	player_camera.limit_left = map_rect.position.x * tile_size.x
	player_camera.limit_top = map_rect.position.y * tile_size.y
	player_camera.limit_right = map_rect.end.x * tile_size.x
	player_camera.limit_bottom = map_rect.end.y * tile_size.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var global_click_pos = get_global_mouse_position()
		var map_pos = ground_terrain.local_to_map(ground_terrain.to_local(global_click_pos))
		
		# Left Click -> Perform Active Tool Action
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_farm_interaction(map_pos)
			
		# Right Click -> Untill / Undo Hoe
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_untill_tile(map_pos)
		
	# Press 'Q' to Till tile under Player
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_Q:
		if player:
			var player_tile_pos = ground_terrain.local_to_map(ground_terrain.to_local(player.global_position))
			_till_tile(player_tile_pos)

func _handle_farm_interaction(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)

	match GameData.selected_item:
		GameData.ActiveItem.HOE:
			_till_tile(map_pos)
			
		GameData.ActiveItem.WATERING_CAN:
			_water_tile(map_pos)
			
		GameData.ActiveItem.SEED:
			# Plant on dry tilled soil or wet watered soil
			if current_source_id == TILLED_SOURCE_ID and (current_tile_coords == TILLED_DIRT_COORDS or current_tile_coords == WATERED_DIRT_COORDS):
				if GameData.remove_seeds(1):
					_spawn_crop(map_pos)
					print("Planted seed at: ", map_pos)
				else:
					print("No seeds in inventory!")

# Tills an untilled tile and triggers hoe animation
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

# Waters dry tilled ground and triggers watering animation
func _water_tile(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
		# Corrected parameters: set_cell(coords, source_id, atlas_coords)
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, WATERED_DIRT_COORDS)
		print("Successfully watered ground at: ", map_pos)
		
		if player and player.has_method("use_watering_can"):
			player.use_watering_can()
	else:
		print("Cannot water tile at ", map_pos, " (Must be dry tilled soil)")

# Reverts tilled or watered tile back to regular dirt
func _untill_tile(map_pos: Vector2i) -> void:
	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == TILLED_SOURCE_ID and (current_tile_coords == TILLED_DIRT_COORDS or current_tile_coords == WATERED_DIRT_COORDS):
		ground_terrain.set_cell(map_pos, UNTILLED_SOURCE_ID, UNTILLED_DIRT_COORDS)
		print("Successfully untilled ground at: ", map_pos)
	else:
		print("Cannot untill tile at ", map_pos)

func _spawn_crop(map_pos: Vector2i) -> void:
	var crop_instance = wheat_crop_scene.instantiate()
	crop_instance.global_position = ground_terrain.map_to_local(map_pos)
	add_child(crop_instance)
