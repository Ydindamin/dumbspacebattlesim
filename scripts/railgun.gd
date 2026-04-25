extends GPUParticles3D

@export var damage : float = 100.0
@export var force : float = 1000.0
@export var originator : PhysicsBody3D

@onready var hitRay : RayCast3D = $hitray
@onready var lifetimer : Timer = $lifetimer


func _ready():
	lifetimer.timeout.connect(kill)

func _physics_process(delta):
	if find_child("hitray", false, false):
		var target = hitRay.get_collider()
		if target != null:
			#stopProjectile()
			print(target.name)
			if target.has_signal("receiveForce"):
				target.receiveForce.emit(randf_range(0.9,1.1)*force, hitRay.get_collision_point(), rotation)
			if target.has_signal("receiveDamage"):
				target.receiveDamage.emit(randf_range(0.9,1.1)*damage)
			hitRay.add_exception(target)
			killRay()

func killRay() -> void:
	hitRay.enabled = false
	hitRay.force_raycast_update()
	hitRay.queue_free()

func kill() -> void:
	queue_free()
