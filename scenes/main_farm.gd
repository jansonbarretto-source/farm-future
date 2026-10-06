extends Node2D

@onready var player_camera = $Player/Camera2D  # Adjust path to your player's Camera2D
@onready var tilemap = $Ground_Terrain          # Adjust to your main TileMap node

func _ready():
	# Get the used rectangle of the tilemap in cell coordinates
	var map_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size

	# Calculate pixel boundaries
	player_camera.limit_left = map_rect.position.x * tile_size.x
	player_camera.limit_top = map_rect.position.y * tile_size.y
	player_camera.limit_right = map_rect.end.x * tile_size.x
	player_camera.limit_bottom = map_rect.end.y * tile_size.y
