class_name NivelProvisorio
extends Nivel
## Escena provisoria para recorrer la secuencia antes de tener los niveles
## reales (1.4.2.1). Se reemplaza con 1.4.2.2 a 1.4.2.6 y 1.4.2.8.
##
## Una pantalla con suelo, paredes, el nombre de la escena y la salida.
## William se dibuja como un rectángulo hasta que 1.4.10 conecte su animación.

const COLOR_FONDO := Color("1b1424")
const COLOR_SUELO := Color("6b5a4a")
const COLOR_SALIDA := Color("38c6b8")
const COLOR_WILLIAM := Color("e9c46a")
const ALTURA_SUELO := 320.0

## Nombre que se muestra en pantalla.
@export var etiqueta: String = "Escena provisoria"

var _william: Node2D


func _ready() -> void:
	super()
	EscenarioPrueba.crear_terreno(self, Rect2(0, ALTURA_SUELO, 640, 40))
	EscenarioPrueba.crear_terreno(self, Rect2(-16, 0, 16, 360))
	EscenarioPrueba.crear_terreno(self, Rect2(640, 0, 16, 360))
	var texto := Label.new()
	texto.text = etiqueta
	texto.position = Vector2(16, 16)
	add_child(texto)


func _process(_delta: float) -> void:
	if _william == null:
		_william = get_tree().root.find_child("Player", true, false)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), COLOR_FONDO)
	draw_rect(Rect2(0, ALTURA_SUELO, 640, 40), COLOR_SUELO)
	if disparador_fin != null:
		draw_rect(Rect2(disparador_fin.position + Vector2(-8, -40), Vector2(16, 80)), COLOR_SALIDA)
	if _william != null:
		draw_rect(Rect2(_william.global_position + Vector2(-6, -28), Vector2(12, 28)), COLOR_WILLIAM)
