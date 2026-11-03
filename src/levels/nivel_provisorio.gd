class_name NivelProvisorio
extends Nivel
## Escena provisoria para recorrer la secuencia antes de tener los niveles
## reales (1.4.2.1). Se reemplaza con 1.4.2.2 a 1.4.2.6 y 1.4.2.8.
##
## Una pantalla con suelo, paredes, el nombre de la escena y la salida. Las
## medidas salen del tamaño de la vista, y el suelo queda a la altura del punto
## de aparición. William se dibuja con su caja de colisión hasta que 1.4.10
## conecte su animación.

const COLOR_FONDO := Color("1b1424")
const COLOR_SUELO := Color("6b5a4a")
const COLOR_SALIDA := Color("38c6b8")
const COLOR_WILLIAM := Color("e9c46a")
const NOMBRE_CAJA_WILLIAM := ^"CajaColision"

## Nombre que se muestra en pantalla.
@export var etiqueta: String = "Escena provisoria"

var _pantalla: Rect2
var _suelo: Rect2


func _ready() -> void:
	super()
	_pantalla = get_viewport_rect()
	var altura_suelo := punto_aparicion.position.y
	_suelo = Rect2(0, altura_suelo, _pantalla.size.x, _pantalla.size.y - altura_suelo)
	EscenarioPrueba.crear_terreno(self, _suelo)
	EscenarioPrueba.crear_terreno(self, Rect2(-Jugador.TILE, 0, Jugador.TILE, _pantalla.size.y))
	EscenarioPrueba.crear_terreno(self, Rect2(_pantalla.size.x, 0, Jugador.TILE, _pantalla.size.y))
	var texto := Label.new()
	texto.text = etiqueta
	texto.position = Vector2.ONE * Jugador.TILE
	add_child(texto)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(_pantalla, COLOR_FONDO)
	draw_rect(_suelo, COLOR_SUELO)
	if disparador_fin != null:
		var salida := disparador_fin.obtener_rectangulo()
		salida.position += disparador_fin.position
		draw_rect(salida, COLOR_SALIDA)
	if jugador != null:
		var caja: CollisionShape2D = jugador.get_node(NOMBRE_CAJA_WILLIAM)
		var cuerpo := caja.shape.get_rect()
		cuerpo.position += jugador.global_position + caja.position
		draw_rect(cuerpo, COLOR_WILLIAM)
