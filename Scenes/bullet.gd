extends Area2D

@export var speed: float = 500
@export var damage: int = 1

var color := Color()

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	rotation = direction.angle()
	$Bullet.modulate = color

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	



func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit"):
		body.hit(damage)
		queue_free()
