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

var spawn_level: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 20.0


func _ready() -> void:
	update_spawn_interval()
	spawn_timer = spawn_interval


func _process(delta: float) -> void:
	spawn_timer -= delta

	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = spawn_interval


func update_spawn_interval() -> void:
	spawn_interval = maxf(
		minimum_spawn_interval,
		base_spawn_interval - spawn_level * 0.1
	)


func spawn_enemy() -> void:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return

	var spawn_position := get_random_spawn_position(camera)

	if randf() < 0.7:
		var enemy = enemy_scene.instantiate()
		enemies.add_child(enemy)
		enemy.global_position = spawn_position
	else:
		var enemy = shotgun_enemy_scene.instantiate()
		enemies.add_child(enemy)
		enemy.global_position = spawn_position


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


func spawn_ghost(pos) -> void:
	var n = randf()

	if n > 0.5:
		var ghost = angry_ghost_scene.instantiate()
		ghost.global_position = pos
		enemies.add_child(ghost)
	else:
		var ghost = ghost_scene.instantiate()
		ghost.global_position = pos
		enemies.add_child(ghost)


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
