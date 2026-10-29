extends Control

@onready var clock_frame: TextureRect = $ClockFrame
@onready var time_icon: TextureRect = $ClockFrame/IconCenterContainer/TimeIcon
@onready var day_label: Label = $ClockFrame/LabelsVBox/DayLabel
@onready var time_label: Label = $ClockFrame/LabelsVBox/TimeLabel

# --- WEATHER PANEL & LABEL VARIABLES ---
var weather_panel: PanelContainer = null
var weather_label: Label = null

# Preload your sun/moon icons (configurable in Inspector)
@export var icon_morning: Texture2D = preload("res://images/assets/ui/morning_icon.png")
@export var icon_sunset: Texture2D = preload("res://images/assets/ui/sunset_icon.png")
@export var icon_night: Texture2D = preload("res://images/assets/ui/night_icon.png")

func _ready() -> void:
	# Configure and lower the CenterContainer further
	var center_container = $ClockFrame.get_node_or_null("IconCenterContainer")
	if center_container:
		center_container.anchor_left = 0.0
		center_container.anchor_top = 0.0
		center_container.anchor_right = 1.0
		center_container.anchor_bottom = 0.55
		
		center_container.offset_left = 6
		center_container.offset_top = 22
		center_container.offset_right = 6
		center_container.offset_bottom = 22

	if time_icon:
		time_icon.custom_minimum_size = Vector2(70, 70)
		time_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		time_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Styled labels for a polished RPG look
	if day_label:
		day_label.add_theme_font_size_override("font_size", 11)
		day_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8)) # Warm cream for Day
		day_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04)) # Dark brown outline
		day_label.add_theme_constant_override("outline_size", 3)

	if time_label:
		time_label.add_theme_font_size_override("font_size", 12)
		time_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4)) # Golden yellow for Time
		time_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04)) # Dark brown outline
		time_label.add_theme_constant_override("outline_size", 3)

	# --- HINDI NA SUSUNDIN ANG VBOX: IBINUKOD NATIN PARA SA WEATHER LANG ---
	if clock_frame:
		weather_panel = clock_frame.get_node_or_null("WeatherPanel") as PanelContainer
		if not weather_panel:
			weather_panel = PanelContainer.new()
			weather_panel.name = "WeatherPanel"
			clock_frame.add_child(weather_panel)
			
			# Maglagay ng madilim na brown background style katulad ng Day at Time boxes
			var panel_style = StyleBoxFlat.new()
			panel_style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
			panel_style.border_color = Color(0.3, 0.2, 0.1, 1.0)
			panel_style.set_border_width_all(1)
			panel_style.set_corner_radius_all(3)
			panel_style.content_margin_left = 8
			panel_style.content_margin_right = 8
			panel_style.content_margin_top = 3
			panel_style.content_margin_bottom = 3
			weather_panel.add_theme_stylebox_override("panel", panel_style)
			
		weather_label = weather_panel.get_node_or_null("WeatherLabel") as Label
		if not weather_label:
			weather_label = Label.new()
			weather_label.name = "WeatherLabel"
			weather_panel.add_child(weather_label)
			
		weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weather_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		weather_label.add_theme_font_size_override("font_size", 12)
		weather_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04))
		weather_label.add_theme_constant_override("outline_size", 3)
		
		# MANUAL POSITIONING: Pwede mong baguhin ang mga numerong ito kung gusto mo pang i-adjust
		# X = horizontal pwesto, Y = vertical pwesto sa ibaba ng time box
		weather_panel.position = Vector2(71, 142) 
		weather_panel.custom_minimum_size = Vector2(96, 24)

	if GameData and GameData.has_signal("time_changed"):
		if not GameData.time_changed.is_connected(_on_time_changed):
			GameData.time_changed.connect(_on_time_changed)
			
	if GameData and GameData.has_signal("data_changed"):
		if not GameData.data_changed.is_connected(_on_data_changed):
			GameData.data_changed.connect(_on_data_changed)
			
	_update_clock_ui()

func _process(_delta: float) -> void:
	_update_clock_ui()

func _on_time_changed(_hour: int, _day: int) -> void:
	_update_clock_ui()

func _on_data_changed() -> void:
	_update_clock_ui()

func _update_clock_ui() -> void:
	if not GameData:
		return

	var hour: int = GameData.current_hour
	var minute: int = int(GameData.time_minutes)
	var day: int = GameData.current_day

	# Update text labels
	if day_label:
		day_label.text = "Day " + str(day)
		
	if time_label:
		time_label.text = "%02d:%02d" % [hour, minute]

	# --- UPDATE WEATHER TEXT & COLOR ---
	if weather_label:
		var weather = GameData.current_weather
		if weather == "Rainy":
			weather_label.text = "Raining 🌧️"
			weather_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		else:
			weather_label.text = "Dry ☀️"
			weather_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))

	# Swap Sun / Sunset / Moon Icon based on time of day
	if time_icon:
		if hour >= 6 and hour < 17:
			if icon_morning and time_icon.texture != icon_morning:
				time_icon.texture = icon_morning
		elif hour >= 17 and hour < 19:
			if icon_sunset and time_icon.texture != icon_sunset:
				time_icon.texture = icon_sunset
		else:
			if icon_night and time_icon.texture != icon_night:
				time_icon.texture = icon_night
