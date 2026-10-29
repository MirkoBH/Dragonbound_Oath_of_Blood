extends EstadoJugador
## William muere: interrumpe todo y no se interrumpe (1.2.5.1, 5.3).
##
## Al terminar la animación emite [signal Jugador.muerte_terminada]; el
## reinicio de la aventura lo hace 1.4.11.3.

var _tiempo: float = 0.0
var _terminada: bool = false


func _init() -> void:
	prioridad = 1


func entrar(_datos: Dictionary = {}) -> void:
	_tiempo = 0.0
	_terminada = false
	jugador.velocity.x = 0.0


func actualizar_fisica(delta: float) -> void:
	_tiempo += delta
	jugador.aplicar_gravedad(delta)
	jugador.velocity.x = 0.0
	if not _terminada and _tiempo >= jugador.duracion_muerte:
		_terminada = true
		jugador.muerte_terminada.emit()


func puede_interrumpirse() -> bool:
	return false
