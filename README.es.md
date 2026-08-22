# Super Cobra (MSX, Konami 1983) — desensamblado comentado

Desensamblado completo y comentado de **Super Cobra** para MSX: el cartucho
**RC-705** de Konami, 8 KB en la página 1.

**El 100 % del binario está explicado**, reensambla en el original byte a byte,
y aquí no hay ninguna suposición disfrazada de hecho.

📖 **[Leer la web](https://antxiko.github.io/SuperCobra-disassembly/es/)** ·
🇬🇧 **[In English](README.md)**

## Lo que hay dentro

| | bytes | |
|---|---|---|
| código trazado | 5.783 | 70,59 % |
| datos identificados | 2.409 | 29,41 % |
| **sin explicar** | **0** | **0,00 %** |

**407 etiquetas** (ni una sin bautizar), **771 comentarios anclados** —el 24,2 %
de las instrucciones, y **ninguna rutina por debajo del 10 %**— y **36 rangos de
datos**, cada uno con su nombre, su explicación y la anchura de sus filas. **25
tests** lo vigilan todo.

## Algo de lo que apareció

- **Con Frogger no comparte ni un byte seguido.** Mismo año, misma casa, los
  mismos 8 KB. Medido con `tools/comun_konami.py`: 400 bytes en común con
  Athletic Land, 287 con Monkey Academy, 239 con Antarctic Adventure y **cero**
  con Frogger.
- **El reproductor de sonido no está copiado de Athletic Land, está revisado**:
  no hay un desplazamiento único que alinee los dos, y las seis tiras idénticas
  se corren 29 bytes a lo largo del mismo bloque.
- **Las letras del juego no están en el cartucho**: `SUBE_FUENTE` lee CGTBL y
  sube 48 caracteres de la ROM del BASIC.
- **El hilo principal no hace nada.** INIT engancha la interrupción y se queda
  en un `jr $` para siempre; el juego entero corre dentro del gancho de vídeo.
- **La misma rutina pinta y borra**, según cuál de los dos puntos de entrada se
  use, y el mismo truco vuelve a salir en los submodos.
- **Cuatro tablas que empiezan dentro de una instrucción**, y una de ellas
  apunta fuera del cartucho.
- **Siete bytes que se ejecutan desde la RAM** porque son un `ld (IX+A),B`, que
  el Z80 no tiene.
- **Este cartucho no lleva la marca oculta de Konami** —el código RC-7xx y el
  título en katakana que descubrió Manuel Pazos—. Hay doce bytes de 0xFF y nada
  más.

La lista entera, con direcciones y cifras, está en
[docs/es/HALLAZGOS.md](docs/es/HALLAZGOS.md). Lo que *no* se sabe está en
[docs/es/PREGUNTAS-ABIERTAS.md](docs/es/PREGUNTAS-ABIERTAS.md), y lo dice.

## Cómo se usa

La imagen del cartucho **no se distribuye aquí**. Ponla en la raíz como
`supercobra.rom` —8192 bytes, sha256 `062aeefd…62091470`— y:

    make            # trazado, listado, reensamblado, comprobaciones y tests
    make verify     # reensambla y compara con la ROM, byte a byte
    make sanity     # ni un byte puede quedarse sin asignar
    make web        # rehace la web

Hacen falta Python 3, `pasmo` y `z80dasm`. Las instrucciones completas están en
[docs/es/EMPEZAR.md](docs/es/EMPEZAR.md).

## Aviso legal

Esto es trabajo de documentación y preservación. El código y los gráficos siguen
siendo de sus autores y de Konami, y **la imagen del cartucho no se
distribuye**. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
