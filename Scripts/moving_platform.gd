extends AnimatableBody3D
@export var travel := Vector3(1.0, 0, 0)
@export_range(4.0, 30.0) var period := 10.0
var origin := Vector3.ZERO
var elapsed := 0.0

func _ready():
	origin = position
	# This body is driven in physics ticks; movement is applied immediately.
	sync_to_physics = false
	process_physics_priority = -10
	add_to_group("MovingPlatforms")

func _physics_process(delta):
	elapsed += delta
	position = origin + travel * sin(elapsed * TAU / period)
