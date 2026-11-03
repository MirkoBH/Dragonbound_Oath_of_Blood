class_name FormasColisionTile
extends Object
## Formas de colisión estándar de los tiles de terreno (1.4.3.3).
##
## La forma de choque de un tile NO copia su dibujo: sigue la grilla de 16 px,
## para que William no se trabe en bordes irregulares y las medidas de 1.2.6.1
## valgan siempre (Pilar 03). Cada tile de un tileset lleva una de estas formas:
##
##   BLOQUE      Cuadrado completo: suelo, paredes y techos.
##   PLATAFORMA  Franja superior de un solo sentido: se atraviesa desde abajo
##               y no se puede bajar a través de ella.
##   RAMPA_45_*  Triángulo de 45°: sube 1 tile en 1 tile.
##   RAMPA_22_*  Rampa de 22,5° (en realidad 26,6°: sube 1 tile en 2). Usa dos
##               tiles: BAJA (de 0 a ½ tile) y ALTA (de ½ a 1 tile).
##   NINGUNA     Decoración (pasto, flores, salientes): no choca.
##
## SUBE_DERECHA = la rampa sube hacia la derecha; SUBE_IZQUIERDA, al revés.
##
## PENDIENTE para los tilesets reales (1.4.2.2 a 1.4.2.6 y 1.4.2.8): asignar a
## cada tile su forma con [method aplicar] (o a mano en el editor de TileSet,
## con los mismos polígonos) y correr [method validar]. El tileset de
## src/resources/tilesets/tileset_provisorio.tres es solo de prueba.

enum Forma {
	NINGUNA,
	BLOQUE,
	PLATAFORMA,
	RAMPA_45_SUBE_DERECHA,
	RAMPA_45_SUBE_IZQUIERDA,
	RAMPA_22_BAJA_SUBE_DERECHA,
	RAMPA_22_ALTA_SUBE_DERECHA,
	RAMPA_22_ALTA_SUBE_IZQUIERDA,
	RAMPA_22_BAJA_SUBE_IZQUIERDA,
}

const TILE := 16
## Capas físicas del TileSet: 0 = terreno sólido, 1 = plataformas atravesables.
const CAPA_FISICA_TERRENO := 0
const CAPA_FISICA_PLATAFORMAS := 1
## Alto de la franja de choque de una plataforma atravesable, en px.
const ALTO_PLATAFORMA := 4.0
## Margen de la plataforma de un solo sentido, en px: si William ya la cruzó
## hasta esta profundidad mientras sube, igual puede pararse encima.
const MARGEN_PLATAFORMA := 4.0
## Nombre de la capa de datos del TileSet que guarda la forma de cada tile.
const DATO_FORMA := "forma"


## Polígono de la forma, en coordenadas del tile (centro en 0, de −8 a 8 px).
static func poligono(forma: Forma) -> PackedVector2Array:
	var m := TILE / 2.0
	match forma:
		Forma.BLOQUE:
			return PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])
		Forma.PLATAFORMA:
			var b := -m + ALTO_PLATAFORMA
			return PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, b), Vector2(-m, b)])
		Forma.RAMPA_45_SUBE_DERECHA:
			return PackedVector2Array([Vector2(-m, m), Vector2(m, -m), Vector2(m, m)])
		Forma.RAMPA_45_SUBE_IZQUIERDA:
			return PackedVector2Array([Vector2(-m, -m), Vector2(m, m), Vector2(-m, m)])
		Forma.RAMPA_22_BAJA_SUBE_DERECHA:
			return PackedVector2Array([Vector2(-m, m), Vector2(m, 0), Vector2(m, m)])
		Forma.RAMPA_22_ALTA_SUBE_DERECHA:
			return PackedVector2Array([Vector2(-m, 0), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])
		Forma.RAMPA_22_ALTA_SUBE_IZQUIERDA:
			return PackedVector2Array([Vector2(-m, -m), Vector2(m, 0), Vector2(m, m), Vector2(-m, m)])
		Forma.RAMPA_22_BAJA_SUBE_IZQUIERDA:
			return PackedVector2Array([Vector2(-m, 0), Vector2(m, m), Vector2(-m, m)])
	return PackedVector2Array()


## Capa física del TileSet en la que va la forma (−1 si no choca).
static func capa_fisica(forma: Forma) -> int:
	match forma:
		Forma.NINGUNA:
			return -1
		Forma.PLATAFORMA:
			return CAPA_FISICA_PLATAFORMAS
	return CAPA_FISICA_TERRENO


## Prepara un TileSet: tamaño de tile, las dos capas físicas con las capas de
## CapasColision y la capa de datos «forma». Se puede llamar más de una vez.
static func preparar_tileset(tileset: TileSet) -> void:
	tileset.tile_size = Vector2i(TILE, TILE)
	while tileset.get_physics_layers_count() < 2:
		tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(CAPA_FISICA_TERRENO, CapasColision.capa(CapasColision.Perfil.TERRENO))
	tileset.set_physics_layer_collision_mask(CAPA_FISICA_TERRENO, 0)
	tileset.set_physics_layer_collision_layer(CAPA_FISICA_PLATAFORMAS, CapasColision.capa(CapasColision.Perfil.PLATAFORMA))
	tileset.set_physics_layer_collision_mask(CAPA_FISICA_PLATAFORMAS, 0)
	if tileset.get_custom_data_layer_by_name(DATO_FORMA) == -1:
		tileset.add_custom_data_layer()
		var i := tileset.get_custom_data_layers_count() - 1
		tileset.set_custom_data_layer_name(i, DATO_FORMA)
		tileset.set_custom_data_layer_type(i, TYPE_INT)


## Asigna [param forma] al tile [param coords] de la fuente [param fuente]:
## guarda la forma en la capa de datos y carga su polígono en la capa física
## que corresponde (y saca el de la otra capa).
static func aplicar(tileset: TileSet, fuente: int, coords: Vector2i, forma: Forma) -> void:
	var atlas := tileset.get_source(fuente) as TileSetAtlasSource
	var datos := atlas.get_tile_data(coords, 0)
	datos.set_custom_data(DATO_FORMA, forma)
	for capa in [CAPA_FISICA_TERRENO, CAPA_FISICA_PLATAFORMAS]:
		datos.set_collision_polygons_count(capa, 0)
	var capa := capa_fisica(forma)
	if capa == -1:
		return
	datos.set_collision_polygons_count(capa, 1)
	datos.set_collision_polygon_points(capa, 0, poligono(forma))
	if forma == Forma.PLATAFORMA:
		datos.set_collision_polygon_one_way(capa, 0, true)
		datos.set_collision_polygon_one_way_margin(capa, 0, MARGEN_PLATAFORMA)


## Revisa un TileSet: capas físicas bien configuradas y cada tile con la forma
## que declara su dato «forma». Devuelve la lista de errores (vacía si está bien).
static func validar(tileset: TileSet) -> PackedStringArray:
	var errores := PackedStringArray()
	if tileset.get_physics_layers_count() < 2:
		errores.append("El TileSet necesita 2 capas físicas (terreno y plataformas).")
		return errores
	if tileset.get_physics_layer_collision_layer(CAPA_FISICA_TERRENO) != CapasColision.capa(CapasColision.Perfil.TERRENO):
		errores.append("La capa física 0 no está en la capa Terreno.")
	if tileset.get_physics_layer_collision_layer(CAPA_FISICA_PLATAFORMAS) != CapasColision.capa(CapasColision.Perfil.PLATAFORMA):
		errores.append("La capa física 1 no está en la capa Plataformas atravesables.")
	if tileset.get_custom_data_layer_by_name(DATO_FORMA) == -1:
		errores.append("Falta la capa de datos «forma».")
		return errores
	for s in tileset.get_source_count():
		var id := tileset.get_source_id(s)
		var atlas := tileset.get_source(id) as TileSetAtlasSource
		if atlas == null:
			continue
		for t in atlas.get_tiles_count():
			var coords := atlas.get_tile_id(t)
			var datos := atlas.get_tile_data(coords, 0)
			var forma: Forma = datos.get_custom_data(DATO_FORMA)
			var capa := capa_fisica(forma)
			for c in [CAPA_FISICA_TERRENO, CAPA_FISICA_PLATAFORMAS]:
				var cantidad := datos.get_collision_polygons_count(c)
				var esperada := 1 if c == capa else 0
				if cantidad != esperada:
					errores.append("Tile %s de la fuente %d: %d polígonos en la capa física %d (se esperaba %d para %s)." % [coords, id, cantidad, c, esperada, Forma.keys()[forma]])
				elif cantidad == 1 and datos.get_collision_polygon_points(c, 0) != poligono(forma):
					errores.append("Tile %s de la fuente %d: el polígono no coincide con %s." % [coords, id, Forma.keys()[forma]])
				elif cantidad == 1 and datos.is_collision_polygon_one_way(c, 0) != (forma == Forma.PLATAFORMA):
					errores.append("Tile %s de la fuente %d: el sentido único no corresponde a %s." % [coords, id, Forma.keys()[forma]])
	return errores
