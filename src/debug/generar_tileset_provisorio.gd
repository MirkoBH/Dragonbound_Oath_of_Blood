extends SceneTree
## Genera el tileset provisorio de prueba (1.4.3.3): la imagen de tiles de
## color y el TileSet con las formas de FormasColisionTile.
##
## Solo hace falta correrlo si cambian las formas. Desde la carpeta del proyecto:
##   godot --headless -s res://src/debug/generar_tileset_provisorio.gd
##
## Es un tileset de prueba: el de cada nivel sale de 1.3.1.4 y se arma en
## 1.4.2.2 (y siguientes) con las mismas formas.

const RUTA_IMAGEN := "res://assets/art/world/tilesets/provisorio/tiles_provisorios.png"
const RUTA_TILESET := "res://src/resources/tilesets/tileset_provisorio.tres"

## Orden de los tiles en la fila 0 del atlas.
const ORDEN: Array[FormasColisionTile.Forma] = [
	FormasColisionTile.Forma.BLOQUE,
	FormasColisionTile.Forma.PLATAFORMA,
	FormasColisionTile.Forma.RAMPA_45_SUBE_DERECHA,
	FormasColisionTile.Forma.RAMPA_45_SUBE_IZQUIERDA,
	FormasColisionTile.Forma.RAMPA_22_BAJA_SUBE_DERECHA,
	FormasColisionTile.Forma.RAMPA_22_ALTA_SUBE_DERECHA,
	FormasColisionTile.Forma.RAMPA_22_ALTA_SUBE_IZQUIERDA,
	FormasColisionTile.Forma.RAMPA_22_BAJA_SUBE_IZQUIERDA,
	FormasColisionTile.Forma.NINGUNA,
]

const TIERRA := Color("8a6f47")
const PASTO := Color("6fa84a")
const MADERA := Color("9a6a3e")
const FLOR := Color("efe3c8")


func _init() -> void:
	var t := FormasColisionTile.TILE
	var imagen := Image.create(t * ORDEN.size(), t, false, Image.FORMAT_RGBA8)
	for i in ORDEN.size():
		_dibujar(imagen, i * t, ORDEN[i])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUTA_IMAGEN.get_base_dir()))
	imagen.save_png(ProjectSettings.globalize_path(RUTA_IMAGEN))

	# La textura se carga desde el PNG importado; si todavía no se importó,
	# hay que correr «godot --headless --import» y volver a correr este script.
	var textura: Texture2D = load(RUTA_IMAGEN) if ResourceLoader.exists(RUTA_IMAGEN) else ImageTexture.create_from_image(imagen)
	var tileset := TileSet.new()
	FormasColisionTile.preparar_tileset(tileset)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = textura
	atlas.texture_region_size = Vector2i(t, t)
	tileset.add_source(atlas, 0)
	for i in ORDEN.size():
		atlas.create_tile(Vector2i(i, 0))
		FormasColisionTile.aplicar(tileset, 0, Vector2i(i, 0), ORDEN[i])
	print("Errores: ", FormasColisionTile.validar(tileset))
	var resultado := ResourceSaver.save(tileset, RUTA_TILESET)
	print("Guardado: ", resultado == OK)
	quit()


func _dibujar(imagen: Image, x0: int, forma: FormasColisionTile.Forma) -> void:
	var t := FormasColisionTile.TILE
	var poligono := FormasColisionTile.poligono(forma)
	for y in t:
		for x in t:
			var punto := Vector2(x + 0.5 - t / 2.0, y + 0.5 - t / 2.0)
			var color := Color(0, 0, 0, 0)
			if forma == FormasColisionTile.Forma.NINGUNA:
				if y >= t - 5 and (x % 5 == 2 or (y >= t - 2 and x % 2 == 0)):
					color = PASTO if y > t - 4 else FLOR
			elif Geometry2D.is_point_in_polygon(punto, poligono):
				color = MADERA if forma == FormasColisionTile.Forma.PLATAFORMA else TIERRA
				# Grilla tenue en los bloques; borde de pasto en las rampas y
				# borde claro en las plataformas, para ver dónde se pisa.
				var arriba := punto - Vector2(0, 1.5)
				if forma == FormasColisionTile.Forma.BLOQUE:
					if x == 0 or y == 0:
						color = TIERRA.darkened(0.15)
				elif not Geometry2D.is_point_in_polygon(arriba, poligono):
					color = PASTO if forma != FormasColisionTile.Forma.PLATAFORMA else MADERA.lightened(0.3)
			imagen.set_pixel(x0 + x, y, color)
