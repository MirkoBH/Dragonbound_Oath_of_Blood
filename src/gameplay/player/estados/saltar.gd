extends EstadoJugador
## William sube en el aire después de despegar.
##
## Salto de altura variable (1.2.3.3): mantener Espacio da 3,5 tiles; un toque
## da 1,5 tiles (1.2.6.1). Si se suelta entre medio, deja de subir ahí.
##
## Datos de entrada: {"sin_impulso": true} para volver a este estado sin
## saltar de nuevo (por ejemplo, al terminar un ataque mientras sube).


func _init() -> void:
	prioridad = 7


func entrar(datos: Dictionary = {}) -> void:
	if not datos.get("sin_impulso", false):
		jugador.impulsar_salto()


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	if not Input.is_action_pressed(&"saltar"):
		jugador.cortar_salto()
	jugador.mover_horizontal(jugador.obtener_direccion(), delta)
	if Input.is_action_just_pressed(&"atacar"):
		cambiar_a(&"Atacar")
	elif jugador.velocity.y >= 0.0:
		cambiar_a(&"Caer")
