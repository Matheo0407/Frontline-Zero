extends Control

# Ruta a la escena principal del juego cuando se presiona Jugar
@export_file("*.tscn") var game_scene_path: String = "res://juego.tscn"

# Se ejecuta al presionar el botón "PlayButton"
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

# Se ejecuta al presionar el botón "ExitButton" (opcional)
func _on_exit_button_pressed() -> void:
	get_tree().quit()
