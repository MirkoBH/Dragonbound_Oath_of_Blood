class_name DisparadorFinNivel
extends Area2D
## Disparador de fin de nivel y salida del campamento (1.4.2.1).
##
## Se ubica en la escena con su CollisionShape2D. Si William muere encima, no
## se activa: la muerte tiene su propio camino (1.4.11.3).

## William llegó al disparador.
signal william_llego


func _ready() -> void:
	CapasColision.configurar(self, CapasColision.Perfil.DETECTOR_WILLIAM)
	body_entered.connect(_al_entrar_cuerpo)


## Rectángulo que ocupa, relativo al disparador. Usa su CollisionShape2D.
func obtener_rectangulo() -> Rect2:
	for hijo in get_children():
		var forma := hijo as CollisionShape2D
		if forma != null and forma.shape != null:
			var rectangulo := forma.shape.get_rect()
			rectangulo.position += forma.position
			return rectangulo
	return Rect2()


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	var william := cuerpo as Jugador
	if william != null and william.obtener_estado() != &"Morir":
		william_llego.emit()
