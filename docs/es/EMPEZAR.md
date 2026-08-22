# Empezar

Este repositorio contiene un **desensamblado comentado** de Super Cobra para
MSX (Konami, 1983, cartucho RC-705). Todo lo que hay aquí sale del binario y se
puede volver a generar desde él.

## Lo que hace falta

- **Python 3** (sin paquetes de terceros)
- **pasmo**, para reensamblar
- **z80dasm**, que solo se usa para los mnemónicos
- la imagen del cartucho, que este repositorio **no distribuye**

La ROM va en la raíz, como `supercobra.rom`. Son 8192 bytes exactos:

    sha256  062aeefd04e6ac28f565c15bd1010fc2a007bfbe8d3898ff8586778462091470

`make comprueba` lo verifica.

## Los comandos

    make                # trazado, listado, reensamblado, comprobaciones y tests
    make listado        # rehace src/supercobra.asm a partir de las anotaciones
    make verify         # reensambla y compara con la ROM, byte a byte
    make sanity         # nada declarado como datos puede salir como código,
                        # y ni un byte puede quedarse sin asignar
    make test           # las comprobaciones
    make imagenes       # rehace los dibujos leyendo la ROM
    make web            # rehace esta web

## Qué hay en cada carpeta

| | |
|---|---|
| `src/supercobra.entries` | los puntos de entrada, cada uno con su justificación |
| `src/supercobra.nocode` | los rangos que el trazador no debe leer como código |
| `src/supercobra.notes` | **lo único que se edita a mano**: todas las anotaciones |
| `src/supercobra.asm` | el listado, lo genera `tools/mkasm.py` |
| `tools/` | el trazador, el generador del listado y las herramientas de medida |
| `tests/` | las comprobaciones sobre el listado y las anotaciones |
| `docs/` | esta web |

## Cómo se lee el listado

Las anotaciones van **ancladas a una dirección**, así que sobreviven a un
retrazado. Las directivas siguen las pautas de theNestruo:

| | |
|---|---|
| `L` | una etiqueta y qué hace la rutina |
| `C` | un comentario en esa línea |
| `B` | una cabecera de bloque antes de esa dirección |
| `D` | un rango de datos, con su nombre y su explicación |
| `F` | la anchura de las filas de un bloque de datos |

## Cómo se hizo

El trazador sigue el flujo real desde los puntos de entrada. Lo que no se puede
deducir estáticamente —el gancho de la interrupción, las dos tablas incrustadas
detrás de un `call`— se declara a mano en el `.entries`, con la razón escrita al
lado.

Este cartucho tiene además dos rutinas a las que **no se llega con un `call`**:
0x4691 hace `push hl` con la dirección de una de ellas y el despachador termina
en `jp (hl)`, así que el `ret` de la rutina de estado aterriza ahí. Sin eso,
0x488B y 0x49EA se quedaban declaradas como datos siendo código.

Aquí no hay ninguna suposición disfrazada de hecho. Lo que no se sabe está en
[Preguntas abiertas](PREGUNTAS-ABIERTAS.html) y lo dice.

## Que se pueda repetir

`make verify` reensambla el listado y compara el resultado con la ROM original.
Tiene que salir **idéntico, byte a byte**. Y `make sanity` comprueba después lo
que el reensamblado no puede cazar: que ningún rango declarado como datos se
esté leyendo como código, y que **ni uno solo de los 8192 bytes** se quede sin
asignar.
