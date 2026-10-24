extends Control


const bullet_scene = preload("res://bullet.tscn")

@onready var projectile: Control = $Projectile


func shoot(pos):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = pos
	bullet.direction = (get_global_mouse_position() - bullet.global_position).normalized()
	projectile.add_child(bullet)
