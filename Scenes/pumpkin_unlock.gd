extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: InteractionArea = $InteractionArea
@onready var canvas_layer: CanvasLayer = $CanvasLayer


@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().current_scene

func _ready():
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_shop")
		
func _shop():
	canvas_layer.visible = !canvas_layer.visible
	player.can_shoot = !canvas_layer.visible
	if canvas_layer.visible:
		animated_sprite.play("up")
		$Sounds/GetUp.play()
		Engine.time_scale = 0.2
	else:
		animated_sprite.play("down")
		$Sounds/GetDown.play()
		Engine.time_scale = 1
		

func _on_body_exited(body: Node2D) -> void:
	if body == player and canvas_layer.visible:
		Engine.time_scale = 1
		animated_sprite.play("down")
		$Sounds/GetDown.play()
		player.can_shoot = true
		canvas_layer.visible = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "up":
		animated_sprite.play("idle")



func _on_fast_pressed() -> void:
	if player.money >= 10:
		$CanvasLayer/GridContainer/Fast.icon = null
		$CanvasLayer/GridContainer/Fast.disabled = true
		player.unlock_fast()


func _on_triple_pressed() -> void:
	if player.money >= 10:
		$CanvasLayer/GridContainer/Triple.icon = null
		$CanvasLayer/GridContainer/Triple.disabled = true
		player.unlock_triple()


func _on_ghost_fast_pressed() -> void:
	if player.money >= 10:
		$CanvasLayer/GridContainer/GhostFast.icon = null
		$CanvasLayer/GridContainer/GhostFast.disabled = true
		player.unlock_ghost_fast()


func _on_ghost_triple_pressed() -> void:
	if player.money >= 10:
		$CanvasLayer/GridContainer/GhostTriple.icon = null
		$CanvasLayer/GridContainer/GhostTriple.disabled = true
		player.unlock_ghost_triple()
