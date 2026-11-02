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


## Crea una trampa fija (zarzas, 1.2.6.3) de [param ancho] × [param alto] px
## apoyada en el suelo en [param posicion]: hitbox continua que hace
## [param danio] corazones físicos a William.
static func crear_trampa(padre: Node, posicion: Vector2, ancho: float = 48.0, alto: float = 10.0, danio: float = 0.5) -> Node2D:
	var trampa := Node2D.new()
	trampa.name = "Zarzas"
	trampa.position = posicion
	var hitbox := Hitbox.new()
	hitbox.perfil = CapasColision.Perfil.TRAMPA
	hitbox.modo = Hitbox.Modo.CONTINUO
	hitbox.danio = danio
	hitbox.activa_al_iniciar = true
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho, alto)
	forma.shape = rect
	forma.position = Vector2(0, -alto / 2.0)
	hitbox.add_child(forma)
	trampa.add_child(hitbox)
	trampa.set_meta(&"trampa", Rect2(posicion + Vector2(-ancho / 2.0, -alto), Vector2(ancho, alto)))
	padre.add_child(trampa)
	return trampa
