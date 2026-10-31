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
			
		print("[WEATHER FX] Umuulan sa buong map!")
		
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
