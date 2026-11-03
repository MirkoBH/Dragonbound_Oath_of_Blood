class_name ProteccionesJugador
extends Resource
## Talismanes de resistencia que tiene William (1.2.4.2, sección 6, y
## 1.2.4.5, sección 4.4).
##
## PROVISORIO: cuando exista el estado global de la partida (1.4.11.1), estos
## datos salen de ahí; mientras tanto William usa una instancia de este
## recurso. Los talismanes se activan al comprarlos (1.4.9.3).
##
## La Armadura de dragón no va acá: mientras está activa desactiva la Hurtbox
## de William (1.4.5.10), así que el golpe ni siquiera llega al cálculo.

## Talismán de resistencia física.
@export var talisman_fisico: bool = false
## Talismán de resistencia mágica.
@export var talisman_magico: bool = false
## Fracción que reduce cada talismán: 25 % (1.2.4.5, sección 4.4).
@export_range(0.0, 1.0, 0.05) var reduccion_talisman: float = 0.25
