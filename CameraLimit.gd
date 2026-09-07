extends Camera3D

# Guardamos el ángulo acumulado en X para el bloqueo vertical
var rot_x: float = 0.0

func _ready() -> void:
	# Captura la rotación inicial que tenga la cámara en el editor
	rot_x = rotation_degrees.x

func _process(_delta: float) -> void:
	# 1. BLOQUEO HORIZONTAL (Eje Y):
	# Si el personaje (CharacterBody3D) gira más de 180 grados, lo frena en seco.
	if owner and owner is CharacterBody3D:
		owner.rotation_degrees.y = clamp(owner.rotation_degrees.y, -180.0, 180.0)
	
	# 2. BLOQUEO VERTICAL (Eje X):
	# Evitamos el bug diagonal limitando localmente la inclinación de la cámara.
	rotation_degrees.x = clamp(rotation_degrees.x, -85.0, 85.0)
