extends Node2D

onready var _camera: Camera2D = $"%Camera2D"
onready var _tm_container: Node2D = $"%Tilemaps"
onready var _cl: CanvasLayer = $CanvasLayer
onready var _ts_container: Control = $"%TilesetContainer"
onready var _layer_container: Control = $"%Layers"
onready var _objects_container: Control = $"%Objects"
onready var _fd_import: FileDialog = $"%FileDialogImportJson"
onready var _fd_export: FileDialog = $"%FileDialogExportJson"
onready var _fd_new_layer: FileDialog = $"%FileDialogNewLayer"
onready var _grid: Sprite = $Grid
onready var _lbl_position: Label = $"%LabelPosition"
onready var _btn_circle: Button = $"%ShapeContainer/ButtonCircle"
onready var _btn_square: Button = $"%ShapeContainer/ButtonSquare"
onready var _hslider_size: HSlider = $"%HSliderSize"
onready var _hslider_size_lbl: Label = $"%HSliderSize/Label"
onready var _cursor_container: Node2D = $CursorContainer
onready var _window_dialog_info: WindowDialog = $"%WindowDialogInfo"

enum BrushShape { CIRCLE, SQUARE }

var _initial_drag_pos: Vector2
var _current_layer := -1
var _selected_tile := -1
var _current_shape := 0
var _current_size := 1
var _cursors := []

const CAMERA_MOVE_SPEED := 100
const CURSOR := preload("res://cursor.tscn")
const TILE_BTN := preload("res://tile_button.tscn")

func _ready() -> void:
	_set_new_cursor_shape()

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_up"):
		_camera.position.y -= CAMERA_MOVE_SPEED * _camera.zoom.x * delta
	if Input.is_action_pressed("move_down"):
		_camera.position.y += CAMERA_MOVE_SPEED * _camera.zoom.x * delta
	if Input.is_action_pressed("move_left"):
		_camera.position.x -= CAMERA_MOVE_SPEED * _camera.zoom.x * delta
	if Input.is_action_pressed("move_right"):
		_camera.position.x += CAMERA_MOVE_SPEED * _camera.zoom.x * delta
	if Input.is_action_pressed("drag"):
		_camera.position += _initial_drag_pos - get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("drag"):
		_initial_drag_pos = get_global_mouse_position()
	if Input.is_action_just_pressed("toggle_gui"):
		_cl.visible = !_cl.visible

	var shift_pressed := Input.is_action_pressed("shift")

	if Input.is_action_just_pressed("zoom_in"):
		if shift_pressed:
			_hslider_size.value = clamp(_current_size + 1, 1, 8)
		else:
			_camera.zoom = Vector2.ONE * clamp(_camera.zoom.x - 0.05, 0.01, 4.0)
	if Input.is_action_just_pressed("zoom_out"):
		if shift_pressed:
			_hslider_size.value = clamp(_current_size - 1, 1, 8)
		else:
			_camera.zoom = Vector2.ONE * clamp(_camera.zoom.x + 0.05, 0.01, 4.0)

	var mouse_pos = get_global_mouse_position() / 64
	var place_pos := Vector2(floor(mouse_pos.x), floor(mouse_pos.y))
	for c in _cursors:
		c.position = place_pos * 64 + Vector2.ONE * 32 + c.offset_pos
	_lbl_position.text = "%s\n%d" % [place_pos, _selected_tile]

	if _current_layer == -1: return

	if Input.is_action_pressed("place"):
		for i in _cursors:
			_layer_container.get_child(_current_layer).get_meta("tm").set_cellv(
				Vector2(floor(i.position.x / 64), floor(i.position.y / 64)),
				_selected_tile)

	if Input.is_action_pressed("delete"):
		for i in _cursors:
			_layer_container.get_child(_current_layer).get_meta("tm").set_cellv(
				Vector2(floor(i.position.x / 64), floor(i.position.y / 64)),
				-1)

func _on_ButtonNewLayer_pressed() -> void:
	_fd_new_layer.popup()

func _on_ButtonNewObject_pressed() -> void:
	pass # Replace with function body.

func _on_Layer_toggled(button_pressed: bool, layer: Control) -> void:
	_clear_ts_container()
	_set_selection(-1)

	for i in _layer_container.get_children():
		i.get_node("MarginContainer/VBoxContainer/HBoxContainer/CheckBox").set_pressed_no_signal(false)
		i.self_modulate = Color.white

	if button_pressed:
		layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/CheckBox").set_pressed_no_signal(true)
		layer.self_modulate = Color.blue
	else:
		return

	var img_tex := layer.get_meta("tex") as ImageTexture
	var idx := 0
	for x in range(img_tex.get_width() / 16):
		for y in range(img_tex.get_height() / 16):
			var btn := TILE_BTN.instance()
			btn.connect("pressed", self, "_on_TileButton_pressed", [idx])
			btn.get_node("LabelIndex").text = str(idx)
			var at := AtlasTexture.new()
			at.atlas = img_tex
			at.region = Rect2(x * 16, y * 16, 16, 16)
			btn.texture_normal = at
			_ts_container.add_child(btn)
			idx += 1

	_current_layer = layer.get_index()
#	_update_cell_size()

func _set_selection(idx: int) -> void:
	if _selected_tile != -1:
		_ts_container.get_child(_selected_tile).get_node("LabelSelect").visible = false

	_selected_tile = idx

	if idx != -1:
		_ts_container.get_child(idx).get_node("LabelSelect").visible = true

func _on_TileButton_pressed(idx: int) -> void:
	_set_selection(idx)

func _on_TileDisplaySizeVSlider_value_changed(value: float) -> void:
	for i in _ts_container.get_children():
		i.rect_min_size = Vector2.ONE * int(value)
	_ts_container.set("custom_constants/vseparation", value / 8.0)
	_ts_container.set("custom_constants/hseparation", value / 8.0)

func _on_Layer_moved_up(layer: Control) -> void:
	if layer.get_index() - 1 >= 0:
		var new_idx := layer.get_index() - 1
		_layer_container.move_child(layer, new_idx)
		_tm_container.move_child(layer.get_meta("tm"), new_idx)
	_update_layers()

func _on_Layer_moved_down(layer: Control) -> void:
	if layer.get_index() + 1 < _layer_container.get_child_count():
		var new_idx := layer.get_index() + 1
		_layer_container.move_child(layer, new_idx)
		_tm_container.move_child(layer.get_meta("tm"), new_idx)
	_update_layers()

func _update_layers() -> void:
	var i := 0
	for l in _layer_container.get_children():
		l.get_node("LabelIndex").text = str(i)
		i += 1

		l.get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonUp").disabled = false
		l.get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonDown").disabled = false

	_layer_container.get_child(0).get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonUp").disabled = true
	_layer_container.get_child(_layer_container.get_child_count() - 1).get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonDown").disabled = true

func _clear_ts_container() -> void:
	for i in _ts_container.get_children():
		i.queue_free()

func _on_Layer_deleted(layer: Control) -> void:
	_clear_ts_container()
	layer.get_meta("tm").queue_free()
#	_layer_container.remove_child(layer)
	layer.queue_free()
	_update_layers()
	_current_layer = -1
	_set_selection(-1)

func _on_ButtonImport_pressed() -> void:
	_fd_import.popup()

func _on_ButtonExport_pressed() -> void:
	_fd_export.popup()
	_fd_export.current_file = "level.json"

func _on_FileDialogImportJson_file_selected(path: String) -> void:
	var file := File.new()
	file.open(path, File.READ)
	var text := file.get_as_text()

	var json_result := JSON.parse(text)
	if json_result.error == OK:
		for p in json_result.result:
			var layer := _create_layer(p["texture_path"])
			var tm := layer.get_meta("tm") as TileMap
			for c in p["cells"]:
				tm.set_cell(c[1], c[2], c[0])

	file.close()

func _on_FileDialogExportJson_file_selected(path: String) -> void:
	var file := File.new()
	file.open(path, File.WRITE)

	var data := []
	for lay in _layer_container.get_children():
		var a := {
			"texture_path": lay.get_meta("tex_path"),
			"cells": [],
		}
		var tm := lay.get_meta("tm") as TileMap
		for c in tm.get_used_cells():
			a["cells"].push_back([tm.get_cellv(c), c.x, c.y])
		data.push_back(a)

	file.store_string(JSON.print(data))
	file.close()

func _on_FileDialogNewLayer_file_selected(path: String) -> void:
	_create_layer(path)

func _create_layer(path: String) -> Control:
	var layer := preload("res://layer.tscn").instance() as Control
	layer.set_meta("path", path)
	var hbox := layer.get_node("MarginContainer/VBoxContainer/HBoxContainer")
	hbox.get_node("CheckBox").connect("toggled", self, "_on_Layer_toggled", [layer])
	hbox.get_node("Name").text = path.get_file()
	hbox.get_node("ButtonUp").connect("pressed", self, "_on_Layer_moved_up", [layer])
	hbox.get_node("ButtonDown").connect("pressed", self, "_on_Layer_moved_down", [layer])
	hbox.get_node("ButtonDelete").connect("pressed", self, "_on_Layer_deleted", [layer])
#	hbox.get_node("HSliderSize").connect("value_changed", self, "_on_HSliderSize_value_changed", [layer])

	_layer_container.add_child(layer)
	_update_layers()

	var file := File.new()
	file.open(path, File.READ)
	var buffer := file.get_buffer(file.get_len())
	var img := Image.new()
	var data
	if path.ends_with(".png"):
		data = img.load_png_from_buffer(buffer)
	elif path.ends_with(".jpg") or path.ends_with(".jpeg"):
		data = img.load_jpg_from_buffer(buffer)
	var img_tex := ImageTexture.new()
	img_tex.create_from_image(img, 1 | 2)
	file.close()

	var tm := TileMap.new()
	tm.cell_size = Vector2(16, 16)

	var ts := TileSet.new()
	var idx := 0
	for x in range(img_tex.get_width() / 16):
		for y in range(img_tex.get_height() / 16):
			var at := AtlasTexture.new()
			at.atlas = img_tex
			at.region = Rect2(x * 16, y * 16, 16, 16)
			ts.create_tile(idx)
			ts.tile_set_texture(idx, at)
			idx += 1

	tm.tile_set = ts

	tm.scale = Vector2.ONE * 4
	_tm_container.add_child(tm)

	layer.set_meta("tex", img_tex)
	layer.set_meta("tex_path", path)
	layer.set_meta("tm", tm)
#	layer.set_meta("size", size)

	hbox.get_node("CheckBox").emit_signal("toggled", true)
#	_update_cell_size()
	return layer

#func _on_HSliderSize_value_changed(value: float, layer: Control) -> void:
#	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer2/HSliderSize/Label").text = str(value)
#	_layers[layer.get_meta("path")]["size"] = int(value)
#	_update_cell_size()

#func _update_cell_size() -> void:
#	var tm: TileMap = _layers[_current_layer]["tm"]
#	var size: int = _layers[_current_layer]["size"]
##	tm.cell_size = Vector2(size, size)
#	print(size)
##	tm.tile_set.
##	tm.scale = Vector2.ONE * size / 4
#	_grid.scale = Vector2.ONE * (size / 16)


func _on_ButtonCircle_toggled(button_pressed: bool) -> void:
	_btn_circle.set_pressed_no_signal(true)
	_btn_square.set_pressed_no_signal(false)
	_current_shape = BrushShape.CIRCLE
	_set_new_cursor_shape()

func _on_ButtonSquare_toggled(button_pressed: bool) -> void:
	_btn_circle.set_pressed_no_signal(false)
	_btn_square.set_pressed_no_signal(true)
	_current_shape = BrushShape.SQUARE
	_set_new_cursor_shape()

func _on_HSliderSize_value_changed(value: float) -> void:
	_hslider_size_lbl.text = "%dx" % int(value)
	_current_size = int(value)
	_set_new_cursor_shape()

func _set_new_cursor_shape() -> void:
	for i in _cursor_container.get_children():
		i.queue_free()
	_cursors.clear()

	match _current_shape:
		BrushShape.CIRCLE:
			var half_size := int(floor(_current_size * 0.5))
			for x in range(-half_size, half_size + 1):
				for y in range(-half_size, half_size + 1):
					if pow(x, 2) + pow(y, 2) <= pow(half_size, 2):
						var c: Sprite = CURSOR.instance()
						c.offset_pos = 16 * 4 * Vector2(x, y)
						_cursor_container.add_child(c)
						_cursors.push_back(c)
		BrushShape.SQUARE:
			var half_size := int(floor(_current_size * 0.5))
			for x in range(-half_size, half_size + 1):
				for y in range(-half_size, half_size + 1):
					var c: Sprite = CURSOR.instance()
					c.offset_pos = 16 * 4 * Vector2(x, y)
					_cursor_container.add_child(c)
					_cursors.push_back(c)
		_:
			pass

func _on_ButtonInfo_pressed() -> void:
	_window_dialog_info.popup()

func _on_ButtonLayers_pressed() -> void:
	_layer_container.get_parent().visible = true
	_objects_container.get_parent().visible = false
	$"%ButtonLayers".set_pressed_no_signal(true)
	$"%ButtonObjects".set_pressed_no_signal(false)

func _on_ButtoObjects_pressed() -> void:
	_layer_container.get_parent().visible = false
	_objects_container.get_parent().visible = true
	$"%ButtonLayers".set_pressed_no_signal(false)
	$"%ButtonObjects".set_pressed_no_signal(true)
