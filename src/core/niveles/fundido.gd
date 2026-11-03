class_name Fundido
extends ColorRect
## Fundido a negro entre escenas (1.4.2.1; regla NV-03 de 1.2.3.2).
##
## Vive en TransitionRoot, que sigue procesando con el juego en pausa. Arranca
## en negro para que el juego aparezca con un fundido de entrada (T-01).

## Duración de cada tramo, en segundos: 0,5 para oscurecer y 0,5 para aclarar.
@export var duracion_tramo: float = 0.5


## Funde a negro. Mientras la pantalla no esté clara, los clics no pasan.
func oscurecer() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	await _animar(1.0)


## Vuelve a mostrar el juego.
func aclarar() -> void:
	await _animar(0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _animar(alfa: float) -> void:
	if is_equal_approx(color.a, alfa):
		return
	var animacion := create_tween()
	animacion.tween_property(self, "color:a", alfa, duracion_tramo)
	await animacion.finished
