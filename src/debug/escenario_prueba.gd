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


## Crea un TileMapLayer con el tileset provisorio de 1.4.3.3 y lo agrega a
## [param padre]. Las celdas se pintan con [method pintar].
static func crear_tilemap(padre: Node) -> TileMapLayer:
	var capa := TileMapLayer.new()
	capa.name = "Terreno"
	capa.tile_set = preload("res://src/resources/tilesets/tileset_provisorio.tres")
	padre.add_child(capa)
	return capa


## Pinta con [param forma] las celdas del rectángulo de tiles que va de
## [param desde] a [param hasta] (ambos incluidos). La fila 0 es la primera
## debajo de y = 0 px; las filas negativas están por encima.
static func pintar(capa: TileMapLayer, desde: Vector2i, hasta: Vector2i, forma: FormasColisionTile.Forma = FormasColisionTile.Forma.BLOQUE) -> void:
	var coords := Vector2i(_columna_de(forma), 0)
	for x in range(mini(desde.x, hasta.x), maxi(desde.x, hasta.x) + 1):
		for y in range(mini(desde.y, hasta.y), maxi(desde.y, hasta.y) + 1):
			capa.set_cell(Vector2i(x, y), 0, coords)


## Arma una rampa que sube [param alto] tiles desde la celda [param inicio]
## (la primera celda de la rampa, sobre el suelo), con pendiente de 45° o de
## 22,5° y hacia [param sentido] (1 = sube a la derecha, −1 = a la izquierda).
## Rellena con bloques debajo de la rampa hasta la fila del suelo.
static func pintar_rampa(capa: TileMapLayer, inicio: Vector2i, alto: int, de_45: bool, sentido: int) -> void:
	var F := FormasColisionTile.Forma
	var paso := 1 if de_45 else 2
	for nivel in alto:
		var y := inicio.y - nivel
		for i in paso:
			var x := inicio.x + sentido * (nivel * paso + i)
			var forma: FormasColisionTile.Forma
			if de_45:
				forma = F.RAMPA_45_SUBE_DERECHA if sentido > 0 else F.RAMPA_45_SUBE_IZQUIERDA
			elif i == 0:
				forma = F.RAMPA_22_BAJA_SUBE_DERECHA if sentido > 0 else F.RAMPA_22_BAJA_SUBE_IZQUIERDA
			else:
				forma = F.RAMPA_22_ALTA_SUBE_DERECHA if sentido > 0 else F.RAMPA_22_ALTA_SUBE_IZQUIERDA
			pintar(capa, Vector2i(x, y), Vector2i(x, y), forma)
			if y < inicio.y:
				pintar(capa, Vector2i(x, y + 1), Vector2i(x, inicio.y))


static func _columna_de(forma: FormasColisionTile.Forma) -> int:
	const ORDEN := [1, 2, 3, 4, 5, 6, 7, 8, 0]
	return ORDEN.find(forma)
