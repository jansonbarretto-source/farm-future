extends Node2D

@onready var player_camera: Camera2D = $Player/Camera2D
@onready var ground_terrain: TileMapLayer = $Ground_Terrain
@onready var player: CharacterBody2D = $Player
@onready var tile_cursor: Control = $TileCursor
@onready var how_to_play_panel: Control = $CanvasLayer/CenterContainer/HowToPlayPanel
@onready var close_button: Button = $CanvasLayer/CenterContainer/HowToPlayPanel/CloseButton

# Corrected path pointing to the child AnimatedSprite2D node
@onready var campfire: AnimatedSprite2D = $Campfire/Campfire

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

# Time tracking para sa sleep warning notification
var _already_warned_today: int = -1

# Background Music Player para sa Main Farm (Naka-loop)
var bgm_player: AudioStreamPlayer = null

# Mini-map camera reference para sumunod sa player
var mini_camera: Camera2D = null

func _ready() -> void:
	_setup_camera_limits()
	_setup_background_music()
	_setup_ingame_settings_button()
	_setup_minimap() # --- CLICKABLE MINIMAP & FULLSCREEN MAP SETUP ---
	
	# Auto-play the campfire flickering animation
	if campfire:
		campfire.play("burn")
	
	if tile_cursor:
		tile_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if how_to_play_panel:
		how_to_play_panel.hide()
		
	if close_button:
		close_button.pressed.connect(_on_close_how_to_play_pressed)
		
	# Ikonekta ang signal ng oras mula sa GameData para sa 8:00 PM warning
	if GameData and GameData.has_signal("time_changed"):
		GameData.time_changed.connect(_on_time_changed)
		
	await get_tree().create_timer(0.8).timeout
	
	if how_to_play_panel:
		_show_how_to_play_animated()

# --- SETUP NG MINIMAP NA MAY CLICK-TO-OPEN FULL-SCREEN MAP ---
func _setup_minimap() -> void:
	var canvas_layer = get_node_or_null("CanvasLayer")
	if not canvas_layer:
		return
		
	var map_panel = PanelContainer.new()
	map_panel.name = "MiniMapPanel"
	map_panel.custom_minimum_size = Vector2(180, 150)
	map_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	map_panel.offset_left = 15
	map_panel.offset_bottom = -15
	map_panel.offset_top = -165
	map_panel.offset_right = 195
	
	# Ginagawang interactive ang panel para ma-click at magbukas ng buong mapa
	map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	map_panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("open")
			_open_fullscreen_map()
	)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.06, 0.03, 0.98)
	style.border_color = Color(0.9, 0.7, 0.35, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	map_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var label = Label.new()
	label.text = "🗺️ FARM MAP (Click to Expand)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	vbox.add_child(label)
	
	var map_container = Control.new()
	map_container.custom_minimum_size = Vector2(170, 120)
	map_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sub_viewport = SubViewport.new()
	sub_viewport.handle_input_locally = false
	sub_viewport.size = Vector2i(512, 384)
	sub_viewport.msaa_2d = SubViewport.MSAA_2X
	
	# Isama ang lahat ng visual nodes sa minimap
	for child in get_children():
		if child is TileMapLayer or child is TileMap or child is Sprite2D or child is Node2D:
			if child.name != "Player" and child.name != "CanvasLayer" and not child is Camera2D:
				var asset_clone = child.duplicate()
				sub_viewport.add_child(asset_clone)
	
	mini_camera = Camera2D.new()
	mini_camera.name = "MiniCamera"
	mini_camera.zoom = Vector2(0.2, 0.2) 
	sub_viewport.add_child(mini_camera)
	
	viewport_container.add_child(sub_viewport)
	map_container.add_child(viewport_container)
	
	# --- PLAYER AVATAR MARKER (Minimap) ---
	var player_avatar = TextureRect.new()
	player_avatar.name = "PlayerAvatarMarker"
	player_avatar.custom_minimum_size = Vector2(24, 24)
	player_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var avatar_path = "res://images/assets/ui/player.avatar.png" 
	if ResourceLoader.exists(avatar_path):
		player_avatar.texture = load(avatar_path)
	else:
		print("[WARNING] Player avatar image not found at: ", avatar_path)
		
	player_avatar.set_anchors_preset(Control.PRESET_CENTER)
	player_avatar.offset_left = -12
	player_avatar.offset_top = -12
	player_avatar.offset_right = 12
	player_avatar.offset_bottom = 12
	map_container.add_child(player_avatar)
	
	vbox.add_child(map_container)
	map_panel.add_child(vbox)
	
	canvas_layer.add_child(map_panel)

# --- FUNCTION PARA SA NAKA-ZOOM IN NA FULL-SCREEN WORLD MAP NA MAY MGA WASTONG LABELS ---
func _open_fullscreen_map() -> void:
	if get_tree().current_scene.has_node("FullScreenMapLayer"):
		return

	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "FullScreenMapLayer"
	canvas_layer.layer = 150
	
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.02, 0.01, 0.0, 0.85)
	canvas_layer.add_child(bg_overlay)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 560)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.98)
	style.border_color = Color(0.95, 0.75, 0.4, 1.0)
	style.set_border_width_all(5)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	center_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Header title at close button
	var header_hbox = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "🗺️ FARM WORLD MAP - OVERVIEW"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)
	
	var close_btn = Button.new()
	close_btn.text = "  ✕ CLOSE  "
	close_btn.custom_minimum_size = Vector2(80, 32)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.8, 0.3, 0.1)
	btn_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		canvas_layer.queue_free()
	)
	header_hbox.add_child(close_btn)
	vbox.add_child(header_hbox)
	
	# Map Wrapper Container na may Control para sa mga Labels
	var map_wrapper = Control.new()
	map_wrapper.custom_minimum_size = Vector2(768, 470)
	map_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vp_container = SubViewportContainer.new()
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_container.stretch = true
	vp_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	var full_viewport = SubViewport.new()
	full_viewport.handle_input_locally = false
	full_viewport.size = Vector2i(768, 470)
	full_viewport.msaa_2d = SubViewport.MSAA_2X
	
	# Kopyahin ang lahat ng assets para sa full world map
	for child in get_children():
		if child is TileMapLayer or child is TileMap or child is Sprite2D or child is Node2D:
			if child.name != "Player" and child.name != "CanvasLayer" and not child is Camera2D:
				var asset_clone = child.duplicate()
				full_viewport.add_child(asset_clone)
	
	# Full Map Camera (Naka-zoom in gamit ang 0.35 zoom)
	var full_camera = Camera2D.new()
	full_camera.name = "FullMapCamera"
	full_camera.zoom = Vector2(0.35, 0.35) 
	if player:
		full_camera.global_position = player.global_position
	full_viewport.add_child(full_camera)
	
	vp_container.add_child(full_viewport)
	map_wrapper.add_child(vp_container)
	
	# --- MGA INAYOS NA POSISYON NG AREA LABELS ---
	var labels_data = [
		{"text": "🏠 Player House", "pos": Vector2(330, 210)},   # Gitna
		{"text": "🏭 Factory Area", "pos": Vector2(520, 90)},    # Upper Right
		{"text": "🏪 Market", "pos": Vector2(350, 40)},          # Itaas (Top)
		{"text": "🌾 Livestock Area", "pos": Vector2(550, 310)}, # Lower Right
		{"text": "🌊 River", "pos": Vector2(80, 220)}            # Kaliwa
	]
	
	for item in labels_data:
		var area_lbl = Label.new()
		area_lbl.text = item["text"]
		area_lbl.position = item["pos"]
		area_lbl.add_theme_font_size_override("font_size", 14)
		area_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
		area_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
		area_lbl.add_theme_constant_override("outline_size", 4)
		map_wrapper.add_child(area_lbl)
	
	# Player Avatar sa Full Map
	var avatar_path = "res://images/assets/ui/player.avatar.png"
	var full_avatar = TextureRect.new()
	full_avatar.custom_minimum_size = Vector2(28, 28)
	full_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	full_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(avatar_path):
		full_avatar.texture = load(avatar_path)
	full_avatar.set_anchors_preset(Control.PRESET_CENTER)
	full_avatar.offset_left = -14
	full_avatar.offset_top = -14
	full_avatar.offset_right = 14
	full_avatar.offset_bottom = 14
	map_wrapper.add_child(full_avatar)
	
	vbox.add_child(map_wrapper)
	get_tree().current_scene.add_child(canvas_layer)

# --- SETUP NG IN-GAME SETTINGS BUTTON SA ILALIM NG PLAYER AVATAR ---
func _setup_ingame_settings_button() -> void:
	var settings_btn = TextureButton.new()
	settings_btn.name = "InGameSettingsButton"
	settings_btn.position = Vector2(20, 68) 
	settings_btn.custom_minimum_size = Vector2(40, 40)
	settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var icon_path = "res://Settings button.png"
	if ResourceLoader.exists(icon_path):
		settings_btn.texture_normal = load(icon_path)
		settings_btn.ignore_texture_size = true
		settings_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		print("[WARNING] Settings button texture not found at: ", icon_path)
		
	settings_btn.pressed.connect(_on_ingame_settings_pressed)
	
	var ui_layer = get_node_or_null("CanvasLayer")
	if ui_layer:
		ui_layer.add_child(settings_btn)
	else:
		add_child(settings_btn)

func _on_ingame_settings_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("open")
		
	var existing_settings = get_tree().current_scene.get_node_or_null("SettingsLayer")
	if existing_settings:
		return

	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "SettingsLayer"
	canvas_layer.layer = 120
	
	var settings_ui = Control.new()
	settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.03, 0.02, 0.75)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			canvas_layer.queue_free()
	)
	settings_ui.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_ui.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 380)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.11, 0.07, 0.98)
	style.border_color = Color(0.9, 0.63, 0.27, 1.0)
	style.set_border_width_all(5)
	style.border_width_top = 7
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🌿 GAME SETTINGS 🌿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(0.9, 0.63, 0.27, 0.8)
	vbox.add_child(divider)
	
	var master_idx = AudioServer.get_bus_index("Master")
	var bgm_idx = AudioServer.get_bus_index("BGM")
	if bgm_idx == -1: bgm_idx = master_idx
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1: sfx_idx = master_idx
	
	vbox.add_child(_create_volume_slider("🔊 Master Volume", master_idx))
	vbox.add_child(_create_volume_slider("🎵 Music / BGM Volume", bgm_idx))
	vbox.add_child(_create_volume_slider("🔔 SFX Volume", sfx_idx))
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = "CLOSE SETTINGS"
	close_btn.custom_minimum_size = Vector2(0, 42)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.82, 0.35, 0.12)
	close_style.border_color = Color(0.98, 0.8, 0.4)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.add_theme_font_size_override("font_size", 14)
	
	close_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		canvas_layer.queue_free()
	)
	vbox.add_child(close_btn)
	
	canvas_layer.add_child(settings_ui)
	get_tree().current_scene.add_child(canvas_layer)

func _create_volume_slider(label_text: String, bus_idx: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	
	var hbox = HBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	
	var current_vol_db = AudioServer.get_bus_volume_db(bus_idx)
	var current_pct = int(db_to_linear(current_vol_db) * 100)
	
	var val_lbl = Label.new()
	val_lbl.text = str(current_pct) + "%"
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	hbox.add_child(val_lbl)
	
	container.add_child(hbox)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = db_to_linear(current_vol_db)
	
	slider.value_changed.connect(func(val: float):
		var db = linear_to_db(val)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, val <= 0.001)
		val_lbl.text = str(int(val * 100)) + "%"
		
		if label_text.contains("SFX") and has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
	)
	
	container.add_child(slider)
	return container

# --- SETUP NA NAGPAPATUGTOG NG MAIN GAME MUSIC NA NAKA-LOOP ---
func _setup_background_music() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	var music_path = "res://sounds/main game music.mp3"
	if ResourceLoader.exists(music_path):
		var stream = load(music_path) as AudioStream
		if stream:
			if stream is AudioStreamMP3 or stream is AudioStreamWAV:
				stream.loop = true
				
			bgm_player.stream = stream
			bgm_player.play()
			print("[BGM] Main game music is now playing on loop.")
	else:
		print("[BGM ERROR] Main game music file not found at: ", music_path)

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

func _process(delta: float) -> void:
	if GameData and GameData.has_method("update_game_time"):
		GameData.update_game_time(delta)
		
	_update_tile_cursor()
	
	# Sinusundan ng minimap camera ang posisyon ng player para laging nasa gitna
	if mini_camera and player:
		mini_camera.global_position = player.global_position

# --- TIME CHANGED LISTENER (8:00 PM SLEEP WARNING) ---
func _on_time_changed(hour: int, day: int) -> void:
	if hour >= 20 and _already_warned_today != day:
		_already_warned_today = day
		_spawn_dynamic_sleep_popup()

func _spawn_dynamic_sleep_popup() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.18, 0.95)
	style.border_color = Color(0.95, 0.75, 0.35, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "🌙 It's 8:00 PM! You need to go to sleep."
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)
	
	await get_tree().process_frame
	
	panel.position += Vector2(-130, -120)
	panel.scale = Vector2(0.5, 0.5)
	panel.pivot_offset = panel.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		var fade = create_tween()
		fade.tween_property(canvas, "modulate:a", 0.0, 1.5)
		fade.chain().tween_callback(canvas.queue_free)
	)

# --- FARM BOUNDARY RESTRICTION ---
func _is_inside_farm_boundary(map_pos: Vector2i) -> bool:
	var min_x = -5
	var max_x = 11
	var min_y = 12
	var max_y = 21
	
	return map_pos.x >= min_x and map_pos.x <= max_x and map_pos.y >= min_y and map_pos.y <= max_y

# --- LIVESTOCK BOUNDARY RESTRICTION ---
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
	
	var current_item = ""
	if GameData:
		if "selected_seed_type" in GameData and GameData.selected_seed_type != "":
			current_item = GameData.selected_seed_type
		elif "selected_inventory_item" in GameData:
			current_item = GameData.selected_inventory_item
	
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

	if current_item in ["Wheat", "Egg", "Milk", "Manure", "Wool"]:
		tile_cursor.visible = false
		return

	tile_cursor.visible = true
	tile_cursor.global_position = ground_terrain.map_to_local(map_pos) - (ground_terrain.tile_set.tile_size / 2.0)
	
	if tile_cursor is ColorRect and current_item in ANIMAL_NAMES:
		tile_cursor.color = Color(0.2, 1.0, 0.4, 0.5)
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
		
		var active_selected = ""
		if GameData:
			if "selected_seed_type" in GameData and GameData.selected_seed_type != "":
				active_selected = GameData.selected_seed_type
			elif "selected_inventory_item" in GameData:
				active_selected = GameData.selected_inventory_item

		var current_tool = GameData.selected_item if (GameData and "selected_item" in GameData) else -1
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if active_selected in ANIMAL_NAMES:
				if not _is_inside_livestock_boundary(map_pos):
					print("[LIVESTOCK] Dito lang pwedeng ilagay ang hayop sa Livestock Area!")
					return
				if _try_place_animal(active_selected, global_click_pos):
					return
				return

			if current_tool == GameData.ActiveItem.HOE or current_tool == GameData.ActiveItem.WATERING_CAN or active_selected == "":
				if not _is_inside_farm_boundary(map_pos):
					return
				if not _try_harvest_tile(map_pos):
					_handle_farm_interaction(map_pos)
				return

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
		
		if GameData:
			if GameData.animal_inventory.get(animal_name, 0) <= 0:
				GameData.selected_inventory_item = ""
				GameData.selected_seed_type = ""
			if GameData.has_signal("data_changed"):
				GameData.data_changed.emit()
			
		print("[LIVESTOCK] Placed 1x ", animal_name, " at position: ", click_pos)
		return true

	print("[LIVESTOCK] You don't have any ", animal_name, " in inventory!")
	return false

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

func _try_harvest_tile(map_pos: Vector2i) -> bool:
	var crop_on_tile = _get_crop_at_tile(map_pos)
	if crop_on_tile and _is_crop_harvestable(crop_on_tile):
		if crop_on_tile.has_method("_harvest"):
			crop_on_tile._harvest()
		else:
			crop_on_tile.queue_free()
			
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("harvest")
			
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
					
					if has_node("/root/AudioManager"):
						AudioManager.play_sfx("planting")
						
					print("Planted ", current_seed, " seed at: ", map_pos)

func _till_tile(map_pos: Vector2i) -> void:
	if not _is_inside_farm_boundary(map_pos):
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == UNTILLED_SOURCE_ID and current_tile_coords == UNTILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, TILLED_DIRT_COORDS)
		
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("hoe")
		
		if player and player.has_method("use_hoe"):
			player.use_hoe()

func _water_tile(map_pos: Vector2i) -> void:
	if not _is_inside_farm_boundary(map_pos):
		return

	var current_source_id = ground_terrain.get_cell_source_id(map_pos)
	var current_tile_coords = ground_terrain.get_cell_atlas_coords(map_pos)
	
	if current_source_id == TILLED_SOURCE_ID and current_tile_coords == TILLED_DIRT_COORDS:
		ground_terrain.set_cell(map_pos, TILLED_SOURCE_ID, WATERED_DIRT_COORDS)
		
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("watering")
		
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
