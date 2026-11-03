extends Node2D
## Escena jugable para probar la máquina de estados (1.4.3.1) y el movimiento
## y el salto de William (1.4.3.2).
##
## El escenario tiene un pozo de 4 tiles (se cruza con un salto con carrera),
## un escalón de 3 tiles (salto completo) y uno de 1 tile (toque corto).
## Arriba a la izquierda se ve la altura y la distancia del último salto.
## Abrir src/debug/prueba_jugador.tscn y presionar F6.
## A/D moverse · Espacio saltar · J atacar · H recibir un golpe de frente ·
## M morir · R reiniciar. El estado actual se ve arriba a la izquierda.
## William se dibuja como un rectángulo de color según el estado, hasta que
## 1.4.10 conecte las animaciones.

const COLORES := {
	&"Quieto": Color("b5a88f"),
	&"Correr": Color("45b8e8"),
	&"Saltar": Color("38c6b8"),
	&"Caer": Color("1e5f86"),
	&"Atacar": Color("e9c46a"),
	&"RecibirDanio": Color("e85454"),
	&"Morir": Color("7a6f86"),
}

var _jugador: Jugador
var _texto: Label
var _historial: PackedStringArray = []
var _destello_golpe: float = 0.0
var _muerte_terminada: bool = false
var _salto_y0: float = 0.0
var _salto_y_min: float = 0.0
var _salto_x: float = 0.0
var _ultimo_salto: String = "—"


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1b1424"))
	_armar_escenario()

	_jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	_jugador.position = Vector2(0, -1)
	add_child(_jugador)
	var camara := Camera2D.new()
	camara.position = Vector2(0, -60)
	_jugador.add_child(camara)
	_jugador.estado_cambiado.connect(_al_cambiar_estado)
	_jugador.golpe_activado.connect(func() -> void: _destello_golpe = 0.1)
	_jugador.muerte_terminada.connect(func() -> void: _muerte_terminada = true)

	var capa := CanvasLayer.new()
	add_child(capa)
	_texto = Label.new()
	_texto.position = Vector2(8, 8)
	_texto.add_theme_font_size_override(&"font_size", 8)
	capa.add_child(_texto)


## Arma el escenario. prueba_terreno.gd la reemplaza por un tilemap.
func _armar_escenario() -> void:
	# Piso con un pozo de 4 tiles, plataformas a 1 y 3 tiles, una más alta
	# (no alcanzable de un salto) y paredes en los extremos.
	EscenarioPrueba.crear_terreno(self, Rect2(-320, 0, 800, 32))
	EscenarioPrueba.crear_terreno(self, Rect2(544, 0, 600, 32))
	EscenarioPrueba.crear_terreno(self, Rect2(-160, -16, 64, 16))
	EscenarioPrueba.crear_terreno(self, Rect2(96, -48, 96, 8))
	EscenarioPrueba.crear_terreno(self, Rect2(256, -96, 96, 8))
	EscenarioPrueba.crear_terreno(self, Rect2(-320, -200, 16, 200))
	EscenarioPrueba.crear_terreno(self, Rect2(1128, -200, 16, 200))


func _al_cambiar_estado(anterior: StringName, nuevo: StringName) -> void:
	if (nuevo == &"Saltar" and anterior != &"Atacar") or (nuevo == &"Caer" and anterior in [&"Quieto", &"Correr"]):
		_salto_y0 = _jugador.position.y
		_salto_y_min = _jugador.position.y
		_salto_x = _jugador.position.x
	if nuevo in [&"Quieto", &"Correr"] and anterior == &"Caer":
		_ultimo_salto = "altura %.1f tiles · distancia %.1f tiles" % [
			(_salto_y0 - _salto_y_min) / Jugador.TILE,
			absf(_jugador.position.x - _salto_x) / Jugador.TILE]
	_historial.append("%s → %s" % [anterior, nuevo])
	if _historial.size() > 6:
		_historial.remove_at(0)


func _unhandled_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_H:
			_jugador.recibir_danio(_jugador.global_position.x + 16.0 * _jugador.mirando)
		KEY_M:
			_jugador.morir()
		KEY_R:
			get_tree().reload_current_scene()


func _process(delta: float) -> void:
	if not _jugador.is_on_floor():
		_salto_y_min = minf(_salto_y_min, _jugador.position.y)
	if _jugador.position.y > 400.0:
		get_tree().reload_current_scene()
	_destello_golpe = maxf(_destello_golpe - delta, 0.0)
	var lineas := PackedStringArray()
	lineas.append("Estado: %s" % _jugador.obtener_estado())
	lineas.append("Velocidad: (%.1f, %.1f) tiles/s  En el suelo: %s" % [_jugador.velocity.x / Jugador.TILE, _jugador.velocity.y / Jugador.TILE, "sí" if _jugador.is_on_floor() else "no"])
	lineas.append("Último salto: %s" % _ultimo_salto)
	lineas.append("")
	lineas.append_array(_historial)
	lineas.append("")
	lineas.append("A/D mover · Espacio saltar · J atacar · H golpe · M morir · R reiniciar")
	if _muerte_terminada:
		lineas.append("Muerte terminada: R para reiniciar.")
	_texto.text = "\n".join(lineas)
	queue_redraw()


func _draw() -> void:
	for hijo in get_children():
		if hijo.has_meta(&"rect"):
			draw_rect(hijo.get_meta(&"rect"), Color("8c6a3c"))
	var color: Color = COLORES.get(_jugador.obtener_estado(), Color.WHITE)
	var base := _jugador.position
	draw_rect(Rect2(base + Vector2(-6, -28), Vector2(12, 28)), color)
	# Marca hacia dónde mira.
	draw_rect(Rect2(base + Vector2(2 * _jugador.mirando - 1, -24), Vector2(2, 4)), Color("0b0810"))
	# Alcance de la espada (1,5 tiles) en el momento del golpe.
	if _destello_golpe > 0.0:
		var x := base.x + (6.0 if _jugador.mirando > 0 else -30.0)
		draw_rect(Rect2(Vector2(x, base.y - 22), Vector2(24, 12)), Color("f3e8cf"), false, 1.0)
