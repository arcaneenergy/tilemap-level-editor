extends Node2D

onready var _camera: Camera2D = $"%Camera2D"
onready var _tms: Node2D = $"%Tilemaps"
onready var _cl: CanvasLayer = $CanvasLayer
onready var _ts_container: Control = $"%TilesetContainer"
onready var _layer_container: Control = $"%Layers"
onready var _fd_import: FileDialog = $"%FileDialogImportJson"
onready var _fd_export: FileDialog = $"%FileDialogExportJson"
onready var _fd_new_layer: FileDialog = $"%FileDialogNewLayer"

var _initial_drag_pos: Vector2
var _layers := []

const CAMERA_MOVE_SPEED := 100

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_up"):
		_camera.position.y -= CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("move_down"):
		_camera.position.y += CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("move_left"):
		_camera.position.x -= CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("move_right"):
		_camera.position.x += CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("drag"):
		_camera.position += _initial_drag_pos - get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("place"):
		var pos = get_global_mouse_position() / 16
#		_tm.set_cell(pos.x, pos.y, 0)

	if Input.is_action_pressed("delete"):
		var pos = get_global_mouse_position() / 16
#		_tm.set_cell(pos.x, pos.y, -1)

	if Input.is_action_just_pressed("toggle_gui"):
		_cl.visible = !_cl.visible

	if Input.is_action_just_pressed("drag"):
		_initial_drag_pos = get_global_mouse_position()

	if Input.is_action_just_pressed("zoom_in"):
		_camera.zoom -= Vector2.ONE * 0.01

	if Input.is_action_just_pressed("zoom_out"):
		_camera.zoom += Vector2.ONE * 0.01

func _on_ButtonNewLayer_pressed() -> void:
	_fd_new_layer.popup()

func _on_Layer_toggled(layer: Control) -> void:
	pass

func _on_Layer_moved_up(layer: Control) -> void:
	if layer.get_index() - 1 >= 0:
		_layer_container.move_child(layer, layer.get_index() - 1)

	_update_layers()

func _on_Layer_moved_down(layer: Control) -> void:
	if layer.get_index() + 1 < _layer_container.get_child_count():
		_layer_container.move_child(layer, layer.get_index() + 1)

	_update_layers()

func _update_layers() -> void:
	var i := 1
	for l in _layer_container.get_children():
		l.get_node("LabelIndex").text = "#%d" % i
		i += 1

func _on_Layer_deleted(layer: Control) -> void:
	_layer_container.remove_child(layer)
	layer.queue_free()
	_update_layers()

func _on_ButtonImport_pressed() -> void:
	_fd_import.popup()

func _on_ButtonExport_pressed() -> void:
	_fd_export.popup()

func _on_FileDialogImportJson_file_selected(path: String) -> void:
	pass

func _on_FileDialogExportJson_file_selected(path: String) -> void:
	pass

func _on_FileDialogNewLayer_file_selected(path: String) -> void:
	var layer := preload("res://layer.tscn").instance()
	layer.get_node("MarginContainer/HBoxContainer/CheckBox").connect("toggled", self, "_on_Layer_toggled", [layer])
	layer.get_node("MarginContainer/HBoxContainer/Name").text = "Layer %d" % _layer_container.get_child_count()
	layer.get_node("MarginContainer/HBoxContainer/ButtonUp").connect("pressed", self, "_on_Layer_moved_up", [layer])
	layer.get_node("MarginContainer/HBoxContainer/ButtonDown").connect("pressed", self, "_on_Layer_moved_down", [layer])
	layer.get_node("MarginContainer/HBoxContainer/ButtonDelete").connect("pressed", self, "_on_Layer_deleted", [layer])
	_layer_container.add_child(layer)
	_update_layers()
