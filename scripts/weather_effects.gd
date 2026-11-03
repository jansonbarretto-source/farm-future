extends CanvasLayer

@onready var rain_particles: GPUParticles2D = $RainParticles
@onready var weather_modulate: CanvasModulate = $WeatherModulate

var rain_audio_player: AudioStreamPlayer = null

func _ready() -> void:
	_setup_rain_audio()
	print("[DEBUG] Current Weather is: ", GameData.current_weather if GameData else "No GameData")
	
	if GameData and GameData.has_signal("data_changed"):
		GameData.data_changed.connect(_update_weather_visuals)
	
	_update_weather_visuals()

func _setup_rain_audio() -> void:
	rain_audio_player = AudioStreamPlayer.new()
	add_child(rain_audio_player)
	
	var rain_path = "res://sounds/rain sound.mp3"
	if ResourceLoader.exists(rain_path):
		var stream = load(rain_path) as AudioStream
		if stream:
			if stream is AudioStreamMP3 or stream is AudioStreamWAV:
				stream.loop = true
			rain_audio_player.stream = stream

func _update_weather_visuals() -> void:
	if not GameData:
		return
		
	if GameData.current_weather == "Rainy":
		# I-on ang ulan
		if rain_particles:
			rain_particles.emitting = true
			rain_particles.visible = true
			
		if rain_audio_player and not rain_audio_player.playing:
			rain_audio_player.play()
			
		if weather_modulate:
			weather_modulate.color = Color(0.5, 0.55, 0.65, 1.0)
			
		# --- BASAIN LANG ANG MGA TILES NA MAY NAKATANIM NA SEEDS/CROPS ---
		_water_planted_crops_only()
			
		print("[WEATHER FX] Umuulan sa buong map - Nabasa ang mga nakatanim na seeds!")
		
	elif GameData.current_weather == "Dry":
		# I-off ang ulan kapag Dry
		if rain_particles:
			rain_particles.emitting = false
			rain_particles.visible = false
			
		if rain_audio_player and rain_audio_player.playing:
			rain_audio_player.stop()
			
		# --- TUGTUGIN ANG DRY SEASON SOUND KUNG NAGPALIT SA DRY ---
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("dry_season")
			
		# Liwanag para sa Dry/Sunny season (Mainit ang paligid)
		if weather_modulate:
			weather_modulate.color = Color(1.0, 0.95, 0.85, 1.0)
			
		print("[WEATHER FX] Dry season / Mainit na panahon!")
	else:
		# Default / Normal weather
		if rain_particles:
			rain_particles.emitting = false
			rain_particles.visible = false
			
		if rain_audio_player and rain_audio_player.playing:
			rain_audio_player.stop()
			
		if weather_modulate:
			weather_modulate.color = Color(1.0, 1.0, 1.0, 1.0)

# --- FUNCTION PARA SA MGA TILE NA MAY NAKATANIM LANG ANG MAGIGING WET SOIL ---
func _water_planted_crops_only() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
		
	# Hanapin ang Ground_Terrain TileMapLayer
	var ground_terrain = current_scene.find_child("Ground_Terrain", true, false) as TileMapLayer
	
	# I-loop ang lahat ng child nodes sa active scene para hanapin ang mga Crop nodes
	for child in current_scene.get_children():
		# I-verify kung ang node ay isang Crop/Planted Seed
		var is_crop_node = child.has_method("_harvest") or "crop_type" in child or child.name.contains("Crop")
		
		if is_crop_node:
			# 1. I-set ang is_watered property ng Crop sa true
			if "is_watered" in child:
				child.is_watered = true
			
			# 2. Palitan ang Tile visual nito patungong Wet Soil (Vector2i(1, 1)) kung ito ay nakatanim sa Tilled Soil
			if ground_terrain:
				var crop_pos = Vector2i.ZERO
				if "grid_position" in child:
					crop_pos = child.grid_position
				elif "cell_pos" in child:
					crop_pos = child.cell_pos
				elif child.has_method("get_grid_position"):
					crop_pos = child.get_grid_position()
				else:
					crop_pos = ground_terrain.local_to_map(ground_terrain.to_local(child.global_position))
				
				var source_id = ground_terrain.get_cell_source_id(crop_pos)
				var atlas_coords = ground_terrain.get_cell_atlas_coords(crop_pos)
				
				# Kung nakatanim sa dry tilled dirt (Source 0, Vector2i(1,0)), gawing watered dirt (Vector2i(1,1))
				if source_id == 0 and atlas_coords == Vector2i(1, 0):
					ground_terrain.set_cell(crop_pos, 0, Vector2i(1, 1))
					print("[WEATHER FX] Naging wet soil ang tile ng pananim sa position: ", crop_pos)
