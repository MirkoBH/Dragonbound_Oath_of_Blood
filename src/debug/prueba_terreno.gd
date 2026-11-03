extends "res://src/debug/prueba_jugador.gd"
## Escena jugable para probar la colisión con terreno y plataformas (1.4.3.3)
## sobre un TileMapLayer con el tileset provisorio.
##
## Abrir src/debug/prueba_terreno.tscn y presionar F6. Mismas teclas que
## prueba_jugador. De izquierda a derecha:
##   1. Loma con rampas de 45° (3 tiles de alto).
##   2. Loma con rampas de 22,5° (3 tiles de alto).
##   3. Techo bajo con 4 tiles de alto libre, como debajo del granero (1.2.6.2).
##   4. Saliente de techo para probar la corrección de esquinas: saltá rozando
##      su borde izquierdo.
##   5. Escalera de plataformas atravesables (se suben desde abajo; no se
##      puede bajar a través de ellas).
##   6. Pared de 5 tiles, que no se puede saltar.

const F := FormasColisionTile.Forma


func _armar_escenario() -> void:
	var c := EscenarioPrueba.crear_tilemap(self)
	c.z_index = -1  # William se dibuja en _draw, por encima del tilemap.
	# Suelo y paredes de los extremos.
	EscenarioPrueba.pintar(c, Vector2i(-20, 0), Vector2i(160, 1))
	EscenarioPrueba.pintar(c, Vector2i(-21, -12), Vector2i(-20, -1))
	EscenarioPrueba.pintar(c, Vector2i(160, -12), Vector2i(161, -1))
	# 1. Loma de 45°.
	EscenarioPrueba.pintar_rampa(c, Vector2i(10, -1), 3, true, 1)
	EscenarioPrueba.pintar(c, Vector2i(13, -3), Vector2i(17, -1))
	EscenarioPrueba.pintar_rampa(c, Vector2i(20, -1), 3, true, -1)
	# 2. Loma de 22,5°.
	EscenarioPrueba.pintar_rampa(c, Vector2i(26, -1), 3, false, 1)
	EscenarioPrueba.pintar(c, Vector2i(32, -3), Vector2i(35, -1))
	EscenarioPrueba.pintar_rampa(c, Vector2i(41, -1), 3, false, -1)
	# 3. Techo bajo: 4 tiles de alto libre.
	EscenarioPrueba.pintar(c, Vector2i(46, -6), Vector2i(56, -5))
	# 4. Saliente de techo a 3 tiles.
	EscenarioPrueba.pintar(c, Vector2i(64, -4), Vector2i(70, -4))
	# 5. Plataformas atravesables.
	EscenarioPrueba.pintar(c, Vector2i(76, -3), Vector2i(80, -3), F.PLATAFORMA)
	EscenarioPrueba.pintar(c, Vector2i(82, -6), Vector2i(86, -6), F.PLATAFORMA)
	EscenarioPrueba.pintar(c, Vector2i(76, -9), Vector2i(80, -9), F.PLATAFORMA)
	# 6. Pared alta.
	EscenarioPrueba.pintar(c, Vector2i(95, -5), Vector2i(96, -1))
	# Decoración sin colisión, para ver que no molesta.
	EscenarioPrueba.pintar(c, Vector2i(2, -1), Vector2i(6, -1), F.NINGUNA)
