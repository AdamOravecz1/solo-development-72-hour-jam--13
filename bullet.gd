extends Area2D

@export var speed: float = 500

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	



func _on_timer_timeout() -> void:
	queue_free()
