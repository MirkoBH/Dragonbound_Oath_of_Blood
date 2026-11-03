class_name MetricasJugador
extends Resource
## Métricas de movimiento de William (1.2.6.1, sección 3), en tiles.
##
## Se editan en el Inspector abriendo src/resources/metricas_william.tres, sin
## tocar código, para calibrarlas en el prototipo (1.5.3). Todas las medidas
## están en tiles (16 px) y segundos; los valores en píxeles se calculan acá.

const TILE := 16.0

@export_group("Correr")
## Velocidad máxima al correr, en tiles/s.
@export var velocidad_correr: float = 7.0
## Tiempo para pasar de quieto a la velocidad máxima.
@export var tiempo_aceleracion: float = 0.1
## Tiempo para frenar del todo al soltar la tecla. También se usa al cambiar
## de dirección, así que dar la vuelta a toda velocidad tarda el doble.
@export var tiempo_frenado: float = 0.05
## Control en el aire: 1 = igual que en el suelo.
@export_range(0.0, 1.0, 0.05) var control_aereo: float = 1.0

@export_group("Salto")
## Altura máxima, manteniendo Espacio, en tiles.
@export var altura_salto_max: float = 3.5
## Altura mínima, con un toque de Espacio, en tiles.
@export var altura_salto_min: float = 1.5
## Distancia horizontal máxima de un salto corriendo, al mismo nivel, en tiles.
## Junto con la altura máxima define la gravedad.
@export var distancia_salto_max: float = 5.0
## Velocidad máxima de caída, en tiles/s.
@export var velocidad_max_caida: float = 15.0

@export_group("Tolerancias (1.2.3.3)")
## Margen al borde: se puede saltar hasta este tiempo después de dejar una
## plataforma caminando.
@export var margen_borde: float = 0.1
## Memoria del salto: un Espacio presionado hasta este tiempo antes de tocar
## el suelo se ejecuta al aterrizar.
@export var memoria_salto: float = 0.1
## Corrección de esquinas, en px: si William choca la cabeza con el borde de
## un techo por esta distancia o menos, se lo corre de costado y sigue subiendo.
@export var correccion_esquinas: float = 4.0

@export_group("Colisión (1.4.3.3)")
## Pendiente máxima que cuenta como suelo, en grados. Las rampas son de 45° y
## de 22,5° (26,6°: 1 tile en 2); una pared es más empinada que esto.
@export var angulo_max_suelo: float = 46.0
## Distancia, en px, a la que William se pega al suelo al bajar una rampa o al
## pasar de rampa a llano, para no despegarse ni saltar sin querer.
@export var pegado_al_suelo: float = 6.0


# --- Valores en píxeles ---

## Velocidad máxima al correr, en px/s.
func obtener_velocidad() -> float:
	return velocidad_correr * TILE


## Aceleración al arrancar, en px/s².
func obtener_aceleracion() -> float:
	return obtener_velocidad() / tiempo_aceleracion


## Desaceleración al frenar o al cambiar de dirección, en px/s².
func obtener_frenado() -> float:
	return obtener_velocidad() / tiempo_frenado


## Tiempo desde el despegue hasta la cima del salto máximo. Un salto
## simétrico dura el doble, y en ese tiempo se recorre la distancia máxima.
func obtener_tiempo_hasta_cima() -> float:
	return (distancia_salto_max / velocidad_correr) / 2.0


## Gravedad, en px/s². Igual al subir y al bajar (caída simétrica).
func obtener_gravedad() -> float:
	var t := obtener_tiempo_hasta_cima()
	return 2.0 * altura_salto_max * TILE / (t * t)


## Velocidad inicial del salto, en px/s.
func obtener_velocidad_salto() -> float:
	return 2.0 * altura_salto_max * TILE / obtener_tiempo_hasta_cima()


## Velocidad máxima de caída, en px/s.
func obtener_velocidad_max_caida() -> float:
	return velocidad_max_caida * TILE
