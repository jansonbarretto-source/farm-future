extends CanvasLayer

@onready var rain_particles: GPUParticles2D = $RainParticles
@onready var weather_modulate: CanvasModulate = $WeatherModulate

func _ready() -> void:
	print("[DEBUG] Current Weather is: ", GameData.current_weather if GameData else "No GameData")
	# Ikonekta sa signal para magbago agad kapag nagpalit ng weather o araw ang laro
	if GameData and GameData.has_signal("data_changed"):
		GameData.data_changed.connect(_update_weather_visuals)
	
	_update_weather_visuals()

func _update_weather_visuals() -> void:
	if not GameData:
		return
		
	if GameData.current_weather == "Rainy":
		# I-on ang ulan
		if rain_particles:
			rain_particles.emitting = true
			rain_particles.visible = true
			
		# Bahagyang dumilim o maging maulap ang paligid (Overcast / Bluish-gray tint)
		if weather_modulate:
			weather_modulate.color = Color(0.5, 0.55, 0.65, 1.0)
			
		print("[WEATHER FX] Umuulan sa buong map!")
	else:
		# I-off ang ulan kapag Dry
		if rain_particles:
			rain_particles.emitting = false
			rain_particles.visible = false
			
		# Bumalik sa normal na liwanag (Normal / Sunny)
		if weather_modulate:
			weather_modulate.color = Color(1.0, 1.0, 1.0, 1.0)
