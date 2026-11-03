class_name CalculoDanio
extends Object
## Cálculo del daño de cada golpe (1.4.5.1), según 1.2.4.2 (secciones 3 a 8).
##
## Todo el daño se mide en corazones y se aplica en múltiplos de ½ (1.2.4.1).
## La Hurtbox decide si el golpe se acepta (invulnerabilidad, Armadura); esta
## clase solo calcula cuánto daño hace un golpe aceptado.

## Unidad mínima de daño y de salud: ½ corazón (1.2.4.1, sección 2).
const UNIDAD := 0.5


## Lleva [param valor] al múltiplo de ½ más cercano, con los empates hacia
## arriba y un mínimo de ½ si el valor es mayor que 0 (1.2.4.1, sección 2).
## Ejemplos: 0,75 → 1 · 0,375 → ½ · 1,2 → 1 · 2,25 → 2,5 · 0 → 0.
static func redondear(valor: float) -> float:
	if valor <= 0.0:
		return 0.0
	# Se suma un margen chico para que los empates exactos (0,75, 2,25…)
	# vayan hacia arriba aunque la cuenta en coma flotante dé 0,7499999.
	var redondeado := floorf(valor / UNIDAD + 0.5 + 1e-6) * UNIDAD
	return maxf(redondeado, UNIDAD)


## Daño que un golpe de William le hace a un enemigo (1.2.4.2, sección 8.1):
## se separa el componente físico del mágico, a cada uno se le aplica la
## resistencia del enemigo, se suman y se redondea. Un enemigo que solo
## recibe daño mágico no recibe el componente físico: si el golpe es solo
## físico, el resultado es 0 (golpe sin efecto).
static func danio_a_enemigo(golpe: Golpe, resistencias: Resistencias) -> float:
	var fisico := golpe.obtener_fisico()
	var magico := golpe.obtener_magico()
	if resistencias:
		fisico = 0.0 if resistencias.solo_danio_magico else fisico * (1.0 - resistencias.resistencia_fisica)
		magico *= 1.0 - resistencias.resistencia_magica
	return redondear(fisico + magico)


## Daño que un golpe le hace a William (1.2.4.2, sección 8.2): a cada
## componente se le aplica la reducción del talismán de su tipo, si William
## lo tiene, y el resultado se redondea. Nunca baja de ½ corazón: un talismán
## nunca anula un golpe.
static func danio_a_william(golpe: Golpe, protecciones: ProteccionesJugador) -> float:
	var fisico := golpe.obtener_fisico()
	var magico := golpe.obtener_magico()
	if protecciones:
		if protecciones.talisman_fisico:
			fisico *= 1.0 - protecciones.reduccion_talisman
		if protecciones.talisman_magico:
			magico *= 1.0 - protecciones.reduccion_talisman
	return redondear(fisico + magico)
