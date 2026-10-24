extends Control

const ghost_scene = preload("res://ghost.tscn")
const bullet_scene = preload("res://bullet.tscn")

@onready var enemies: Control = $Enemies
@onready var projectile: Control = $Projectile


func shoot(spawn_position: Vector2, bullet_rotation: float, layer: int, mask: int, col: Color) -> void:
	var bullet = bullet_scene.instantiate()
	
	bullet.color = col

	bullet.global_position = spawn_position
	bullet.global_rotation = bullet_rotation
	bullet.direction = Vector2.RIGHT.rotated(bullet_rotation).normalized()

	bullet.collision_layer = 1 << (layer - 1)
	bullet.collision_mask = 1 << (mask - 1)

	projectile.add_child(bullet)

func spawn_ghost(pos):
	var ghost = ghost_scene.instantiate()
	ghost.global_position = pos
	enemies.add_child(ghost)
