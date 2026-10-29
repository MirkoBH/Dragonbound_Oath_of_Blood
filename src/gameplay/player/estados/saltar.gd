extends EstadoJugador
## William sube en el aire después de despegar.
##
## Datos de entrada: {"sin_impulso": true} para volver a este estado sin
## saltar de nuevo (por ejemplo, al terminar un ataque mientras sube).


func _init() -> void:
	prioridad = 7


func entrar(datos: Dictionary = {}) -> void:
	if not datos.get("sin_impulso", false):
		jugador.velocity.y = -jugador.obtener_velocidad_salto()


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	jugador.mover_horizontal(jugador.obtener_direccion())
	if Input.is_action_just_pressed(&"atacar"):
		cambiar_a(&"Atacar")
	elif jugador.velocity.y >= 0.0:
		cambiar_a(&"Caer")
