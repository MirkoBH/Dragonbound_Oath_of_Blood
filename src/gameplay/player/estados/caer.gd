extends EstadoJugador
## William cae (después de la cima del salto o al salir de un borde).
##
## Margen al borde: si dejó una plataforma caminando hace menos de 0,1 s,
## todavía puede saltar. Memoria del salto: si presionó Espacio poco antes de
## aterrizar, salta apenas toca el suelo (1.2.3.3).


func _init() -> void:
	prioridad = 7


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	jugador.mover_horizontal(jugador.obtener_direccion(), delta)
	if jugador.hay_salto_pedido() and jugador.puede_saltar_por_margen():
		cambiar_a(&"Saltar")
	elif Input.is_action_just_pressed(&"atacar"):
		cambiar_a(&"Atacar")
	elif jugador.is_on_floor():
		if jugador.hay_salto_pedido():
			cambiar_a(&"Saltar")
		else:
			cambiar_a(&"Correr" if jugador.obtener_direccion() != 0.0 else &"Quieto")
