extends Control

const ghost_scene = preload("res://Scenes/ghost.tscn")
const angry_ghost_scene = preload("res://Scenes/angry_ghost.tscn")
const enemy_scene = preload("res://Scenes/outlaw.tscn")
const shotgun_enemy_scene = preload("res://Scenes/outlaw_shotgun.tscn")
const bullet_scene = preload("res://Scenes/bullet.tscn")

@onready var enemies: Control = $ForSorting/Enemies
@onready var projectile: Control = $ForSorting/Projectile

@export var top_left_boundary: Marker2D
@export var bottom_right_boundary: Marker2D

@export var base_spawn_interval: float = 20.0
@export var minimum_spawn_interval: float = 2.0

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var label: Label = $CanvasLayer/Label
@onready var button: Button = $CanvasLayer/Button
@onready var score_label: Label = $CanvasLayer/ScoreLabel



var spawn_level: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 20.0

var paused = false

func _ready() -> void:
	update_spawn_interval()
	spawn_timer = spawn_interval
	get_tree().paused = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and player.can_shoot:
		paused = !paused
		$CanvasLayer/Pause.visible = paused
		Engine.time_scale = 0 if paused else 1
		player.stopped = paused
		
	spawn_timer -= delta

	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = spawn_interval


	

func update_spawn_interval() -> void:
	spawn_interval = maxf(
		minimum_spawn_interval,
		base_spawn_interval - spawn_level * 1
	)


func spawn_enemy() -> void:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return

	var spawn_position := get_random_spawn_position(camera)
	var enemy

	if randf() < 0.7:
		enemy = enemy_scene.instantiate()
	else:
		enemy = shotgun_enemy_scene.instantiate()

	enemies.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.health = get_enemy_health()


func spawn_ghost(pos) -> void:
	var ghost

	if randf() > 0.5:
		ghost = angry_ghost_scene.instantiate()
	else:
		ghost = ghost_scene.instantiate()

	enemies.add_child(ghost)
	ghost.global_position = pos
	ghost.health = get_enemy_health()


func get_random_spawn_position(camera: Camera2D) -> Vector2:
	var area_min := top_left_boundary.global_position
	var area_max := bottom_right_boundary.global_position

	var viewport_size := get_viewport_rect().size
	var camera_size := viewport_size / camera.zoom
	var camera_center := camera.get_screen_center_position()

	var view_min := camera_center - camera_size / 2.0
	var view_max := camera_center + camera_size / 2.0

	for i in range(100):
		var pos := Vector2(
			randf_range(area_min.x, area_max.x),
			randf_range(area_min.y, area_max.y)
		)

		if (
			pos.x < view_min.x
			or pos.x > view_max.x
			or pos.y < view_min.y
			or pos.y > view_max.y
		):
			return pos

	return area_min


func shoot(
	spawn_position: Vector2,
	bullet_rotation: float,
	layer: int,
	mask: int,
	col: Color,
	speed: float,
	damage: int
) -> void:
	var bullet = bullet_scene.instantiate()

	bullet.color = col
	bullet.speed = speed
	bullet.damage = damage

	bullet.global_position = spawn_position
	bullet.global_rotation = bullet_rotation
	bullet.direction = Vector2.RIGHT.rotated(bullet_rotation).normalized()

	bullet.collision_layer = 1 << (layer - 1)
	bullet.collision_mask = 1 << (mask - 1)

	projectile.add_child(bullet)

func get_enemy_health() -> int:
	return 5 + int(spawn_level / 10)


func _on_button_pressed() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), 0.0)
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func death() -> void:
	color_rect.visible = true
	label.visible = true
	button.visible = true
	score_label.visible = true

	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(color_rect, "modulate", Color.BLACK, 3.0)
	tween.tween_property(label, "modulate", Color.WHITE, 3.0)
	tween.tween_property(button, "modulate", Color.WHITE, 3.0)
	tween.tween_property(score_label, "modulate", Color.WHITE, 3.0)

	if music_bus != -1:
		tween.tween_method(
			func(volume: float): AudioServer.set_bus_volume_db(music_bus, volume),
			AudioServer.get_bus_volume_db(music_bus),
			-80.0,
			3.0
		)

	if sfx_bus != -1:
		tween.tween_method(
			func(volume: float): AudioServer.set_bus_volume_db(sfx_bus, volume),
			AudioServer.get_bus_volume_db(sfx_bus),
			-80.0,
			3.0
		)


func _on_start_pressed() -> void:
	$CanvasLayer/Start.visible = false
	$CanvasLayer/Start.disabled = true
	get_tree().paused = false
	
func increase_score():
	score_label.text = "Score: " + str(spawn_level)
