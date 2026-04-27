extends Node3D

@export var enemy : PackedScene
var timerStarted = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_child_count() <= 1 and timerStarted == false:
		$Timer.start()
		timerStarted = true


func _on_timer_timeout() -> void:
	var instance = enemy.instantiate()
	add_child(instance)
	timerStarted = false
