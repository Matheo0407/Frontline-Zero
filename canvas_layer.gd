extends CanvasLayer

func _ready() -> void:
	# Oculta el contenedor si NO es Android ni iOS
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		hide() # O visible = false
