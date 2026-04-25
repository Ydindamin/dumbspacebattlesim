extends RigidBody3D

@export var massKG : float = 10.0
@export var healthMax : float = 100.0
@export var initialVelocity : Vector3 = Vector3.ZERO
@export var initialRotVelocity : Vector3 = Vector3.ZERO 

@onready var health : float = healthMax

signal receiveDamage(amount)
signal receiveForce(amount, applyPoint, applyDir)

func _ready():
	mass = massKG
	health = healthMax
	receiveDamage.connect(applyDamage)
	receiveForce.connect(applyForce)

func applyDamage(amount) -> void:
	print("received ", amount, " damage")
	health -= amount
	if health <= 0:
		kill()

func applyForce(amount, applyPoint, applyDir) -> void:
	print("received ", amount, " force")
	apply_impulse(applyDir.normalized() * amount, applyPoint)

func kill() -> void:
	# TODO: death effect(s)
	queue_free()
