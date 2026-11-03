extends Node2D
## Escena jugable para probar hitboxes y hurtboxes (1.4.4.2) y el daño con
## resistencias (1.4.5.1).
##
## Abrir src/debug/prueba_golpes.tscn y presionar F6.
## A/D moverse · Espacio saltar · J atacar · R reiniciar.
## T: talismán físico (sí/no) · U: runa de fuego (+1 mágico, sí/no).
## - Muñeco gris (izquierda): 3 corazones y 50 % de resistencia física.
## - Muñeco violeta (más a la izquierda): solo recibe daño mágico; sin runa,
##   el golpe no le hace nada.
## - Muñeco rojo (derecha): ataca a William cada 1,5 s.
## - Zarzas (centro): trampa que daña al tocarla y vuelve a dañar al terminar
##   la invulnerabilidad.
## Los cuerpos se bloquean, pero tocar un muñeco no hace daño.
## Se dibujan las áreas: espada activa (amarillo), áreas de golpes (contorno)
## y la trampa (violeta).

const COLOR_ESTADO := {
	&"Quieto": Color("b5a88f"), &"Correr": Color("45b8e8"), &"Saltar": Color("38c6b8"),
	&"Caer": Color("1e5f86"), &"Atacar": Color("e9c46a"), &"RecibirDanio": Color("e85454"),
	&"Morir": Color("7a6f86"),
}

var _jugador: Jugador
var _especial: Munieco
var _blanco: Munieco
var _atacante: Munieco
var _texto: Label
var _golpes_william: int = 0
var _ultimo_golpe_william: String = "—"


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1b1424"))
	EscenarioPrueba.crear_terreno(self, Rect2(-480, 0, 1120, 32))
	EscenarioPrueba.crear_terreno(self, Rect2(-480, -200, 16, 200))
	EscenarioPrueba.crear_terreno(self, Rect2(624, -200, 16, 200))
	EscenarioPrueba.crear_trampa(self, Vector2(160, 0), 48.0)

	_jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	_jugador.position = Vector2(0, -1)
	add_child(_jugador)
	var camara := Camera2D.new()
	camara.position = Vector2(0, -60)
	_jugador.add_child(camara)
	_jugador.golpe_recibido.connect(func(golpe: Golpe) -> void:
		_golpes_william += 1
		_ultimo_golpe_william = str(golpe))

	_blanco = Munieco.new()
	_blanco.position = Vector2(-120, -1)
	_blanco.salud_maxima = 3.0
	_blanco.resistencias = Resistencias.new()
	_blanco.resistencias.resistencia_fisica = 0.5
	add_child(_blanco)
	_especial = Munieco.new()
	_especial.position = Vector2(-220, -1)
	_especial.salud_maxima = 2.0
	_especial.resistencias = Resistencias.new()
	_especial.resistencias.solo_danio_magico = true
	add_child(_especial)
	_atacante = Munieco.new()
	_atacante.ataca = true
	_atacante.objetivo = _jugador
	_atacante.position = Vector2(400, -1)
	add_child(_atacante)

	var capa := CanvasLayer.new()
	add_child(capa)
	_texto = Label.new()
	_texto.position = Vector2(8, 8)
	_texto.add_theme_font_size_override(&"font_size", 8)
	capa.add_child(_texto)


func _unhandled_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_R:
			get_tree().reload_current_scene()
		KEY_T:
			_jugador.protecciones.talisman_fisico = not _jugador.protecciones.talisman_fisico
		KEY_U:
			_jugador.espada.danio_magico_extra = 0.0 if _jugador.espada.danio_magico_extra > 0.0 else 1.0


func _process(_delta: float) -> void:
	var lineas := PackedStringArray([
		"Estado de William: %s  ·  Salud: %s / %s" % [_jugador.obtener_estado(), _jugador.salud.obtener_actual(), _jugador.salud.salud_maxima],
		"Talismán físico: %s  ·  Runa de fuego: %s" % ["sí" if _jugador.protecciones.talisman_fisico else "no", "sí" if _jugador.espada.danio_magico_extra > 0.0 else "no"],
		"Golpes recibidos por William: %d  (último: %s)" % [_golpes_william, _ultimo_golpe_william],
		"Invulnerable: %s" % ("%.1f s" % _jugador.area_golpes.obtener_invulnerabilidad_restante() if _jugador.area_golpes.esta_invulnerable() else "no"),
		"Muñeco gris (50 %% físico): %s / 3 corazones%s" % [_blanco.salud.obtener_actual(), " · DERROTADO" if _blanco.muerto else ""],
		"Muñeco violeta (solo magia): %s / 2 corazones · golpes sin efecto: %d%s" % [_especial.salud.obtener_actual(), _especial.golpes_sin_efecto, " · DERROTADO" if _especial.muerto else ""],
		"Golpes al muñeco rojo: %d" % _atacante.golpes_recibidos,
		"",
		"A/D mover · Espacio saltar · J atacar · T talismán · U runa · R reiniciar",
	])
	_texto.text = "\n".join(lineas)
	queue_redraw()


func _draw() -> void:
	for hijo in get_children():
		if hijo.has_meta(&"rect"):
			draw_rect(hijo.get_meta(&"rect"), Color("8c6a3c"))
		if hijo.has_meta(&"trampa"):
			draw_rect(hijo.get_meta(&"trampa"), Color("8e5cc2"))
	_dibujar_munieco(_blanco, Color("b5a88f"))
	_dibujar_munieco(_especial, Color("8e5cc2"))
	_dibujar_munieco(_atacante, Color("e85454"))
	# William: color según el estado; parpadea mientras es invulnerable.
	var base := _jugador.position
	var color: Color = COLOR_ESTADO.get(_jugador.obtener_estado(), Color.WHITE)
	color.a = _jugador.modulate.a
	draw_rect(Rect2(base + Vector2(-6, -28), Vector2(12, 28)), color)
	draw_rect(Rect2(base + Vector2(2 * _jugador.mirando - 1, -24), Vector2(2, 4)), Color("0b0810"))
	draw_rect(Rect2(base + Vector2(-6, -28), Vector2(12, 28)), Color("f3e8cf"), false, 1.0)
	if _jugador.espada.esta_activa():
		var centro := _jugador.position + _jugador.espada.position
		draw_rect(Rect2(centro - Vector2(12, 10), Vector2(24, 20)), Color("e9c46a"), false, 1.0)


func _dibujar_munieco(munieco: Munieco, color: Color) -> void:
	if munieco.muerto:
		color = color.darkened(0.6)
	var rect := Rect2(munieco.position + Vector2(-7, -28), Vector2(14, 28))
	draw_rect(rect, Color.WHITE if munieco.destello > 0.0 else color)
	if munieco.hitbox and munieco.hitbox.esta_activa():
		var centro := munieco.position + munieco.hitbox.position
		draw_rect(Rect2(centro - Vector2(10, 10), Vector2(20, 20)), Color("ff8c42"), false, 1.0)
