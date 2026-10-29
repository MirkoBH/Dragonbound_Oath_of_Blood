class_name EscenarioPrueba
extends RefCounted
## Ayudas para armar escenarios de prueba en src/debug (solo depuración).


## Crea un bloque de terreno sólido con la forma de [param rect] y lo agrega a
## [param padre]. Guarda el rectángulo en el metadato «rect» para dibujarlo.
static func crear_terreno(padre: Node, rect: Rect2, perfil: CapasColision.Perfil = CapasColision.Perfil.TERRENO) -> StaticBody2D:
	var cuerpo := StaticBody2D.new()
	CapasColision.configurar(cuerpo, perfil)
	cuerpo.position = rect.get_center()
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = rect.size
	forma.shape = caja
	cuerpo.add_child(forma)
	cuerpo.set_meta(&"rect", rect)
	padre.add_child(cuerpo)
	return cuerpo
