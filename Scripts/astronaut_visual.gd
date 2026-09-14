extends Node3D
# Smooth procedural animation for the supplied single-pose astronaut rig.
var clock_time := 0.0
var rig: Skeleton3D
var pilot: CharacterBody3D
var rest_rotations: Dictionary = {}
var air_blend := 0.0
var stride_blend := 0.0
var was_airborne := false
var landing := 0.0

func _ready():
	pilot = get_parent() as CharacterBody3D
	for node in find_children("*", "Skeleton3D", true, false):
		rig = node
		break
	if rig:
		for i in rig.get_bone_count():
			rest_rotations[i] = rig.get_bone_rest(i).basis.get_rotation_quaternion()
	$Model.rotation = Vector3.ZERO

func pose_bone(bone_name: String, world_axis: Vector3, angle: float, weight: float):
	var index := rig.find_bone("mixamorig_" + bone_name)
	if index < 0:
		return
	var local_axis := rig.get_bone_global_rest(index).basis.inverse() * world_axis
	var target: Quaternion = rest_rotations[index] * Quaternion(local_axis.normalized(), angle)
	rig.set_bone_pose_rotation(index, rig.get_bone_pose_rotation(index).slerp(target, weight))

func _process(delta):
	if not rig or not pilot:
		return
	clock_time += delta
	var weight := 1.0 - exp(-14.0 * delta)
	var airborne := not pilot.is_on_floor()
	if was_airborne and not airborne:
		landing = 1.0
	was_airborne = airborne
	landing = move_toward(landing, 0.0, delta * 6.0)
	air_blend = lerpf(air_blend, 1.0 if airborne else 0.0, weight)
	stride_blend = lerpf(stride_blend, 1.0 if pilot.is_moving() and not airborne else 0.0, weight)
	var stride := sin(clock_time * 11.0) * 0.38 * stride_blend
	var tuck := 0.28 if pilot.velocity.y > 0.0 else 0.10
	pose_bone("LeftArm", Vector3.FORWARD, 1.12 - air_blend * 0.22, weight)
	pose_bone("RightArm", Vector3.FORWARD, -1.12 + air_blend * 0.22, weight)
	pose_bone("LeftUpLeg", Vector3.RIGHT, stride - tuck * air_blend, weight)
	pose_bone("RightUpLeg", Vector3.RIGHT, -stride - tuck * air_blend, weight)
	pose_bone("LeftLeg", Vector3.RIGHT, maxf(0.0, -stride) + air_blend * 0.4 + landing * 0.12, weight)
	pose_bone("RightLeg", Vector3.RIGHT, maxf(0.0, stride) + air_blend * 0.4 + landing * 0.12, weight)
	$Model.position.y = 0.015 + absf(sin(clock_time * 11.0)) * 0.02 * stride_blend - landing * 0.035
