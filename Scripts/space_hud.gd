extends Control
@export var level_number: int = 1
@export var required_cells: int = 5
@export var extraction_position := Vector3(18.02, 9.53, 2.0)
@export_file("*.tscn") var next_scene := "res://Scenes/level_2.tscn"
var complete := false
var changing_scene := false

func _ready():
	GameManager.score = 0

func _process(_delta):
	if complete or changing_scene or GameManager.score < required_cells:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.is_on_floor() and player.global_position.distance_to(extraction_position) < 3.5:
		complete = true
		if not next_scene.is_empty():
			changing_scene = true
			get_tree().change_scene_to_file.call_deferred(next_scene)
		else:
			show_win_banner()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func show_win_banner():
	var overlay := ColorRect.new()
	overlay.name = "WinOverlay"
	overlay.color = Color(0.01, 0.025, 0.07, 0.62)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.name = "WinLabel"
	label.text = "You win"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color("#b8f6ff"))
	label.add_theme_color_override("font_outline_color", Color("#123448"))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.35)