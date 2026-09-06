#!/usr/bin/env python3
"""Dibuja el mapa de Super Cobra EJECUTANDO el cartucho, no leyendolo.

    python3 tools/mapa.py supercobra.rom docs/imagenes

POR QUE ASI Y NO DE OTRA MANERA. El decorado de este juego no esta guardado en
la ROM como un mapa que se pueda leer y pintar. Se monta en la RAM al empezar
la partida -MONTA_EL_MAPA (0x4106) y MONTA_EL_TERRENO (0x4190)- con una rutina,
DESPLIEGA (0x4626), que escribe con un `ld (IX+A),B` que el Z80 no tiene: el
cartucho se fabrica esa instruccion copiandose siete bytes a la RAM (0x41DD ->
0xE5F8) y automodificando el desplazamiento en cada escritura. Y luego el mapa
solo aparece a trozos: CORRE_EL_BUFFER (0x5322) mete UNA columna nueva por la
derecha en cada paso de scroll.

Reescribir todo eso en Python seria adivinar. Aqui se hace lo unico que no
admite discusion: se ejecuta el cartucho entero en el interprete de
tools/z80run.py -que revienta ante cualquier opcode que no implemente-, se le
pulsa la tecla 1 para empezar la partida, y se va guardando la columna que
entra por la derecha en cada cuadro. El mapa es la tira de columnas.

LAS DOS AYUDAS, dichas en voz alta:

  - El deposito (0xE51C) se rellena en cada cuadro. Sin eso la nave se queda sin
    combustible a las 270 columnas y no llega ni al final de la primera zona.
    Es lo mismo que hace un jugador recogiendo depositos, y no toca el decorado.
  - Las naves (0xE050) tambien se reponen, para que la partida siga. Al morir,
    la zona vuelve a empezar, asi que las columnas capturadas desde el ultimo
    cambio de zona se tiran y la zona se rehace entera de una tirada.

Ni una instruccion del cartucho se modifica: las dos ayudas son escrituras en
las mismas casillas de RAM que el propio juego usa.

De la VRAM que deja el cartucho salen tambien los tiles: los patrones viven en
0x2000 y los colores en 0x0000, porque este cartucho -como el Nemesis- pone la
tabla de patrones y la de colores al reves de como las deja la BIOS.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image

from z80run import Z80, ParadaZ80

# La paleta del TMS9918, tal cual la da el estandar.
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]

INIT = 0x407D           # la entrada del cartucho
QUIETO = 0x40AD         # el `jr` eterno en el que INIT se queda
INTERRUPCION = 0x402B   # el gancho H.KEYI: un cuadro entero del juego

DECORADO = 0x3A00       # donde SUBMODO_0_VUELCA deja las cinco filas de tierra
ANCHO_DECORADO = 0xA0   # 5 filas de 32 casillas

NAVES = 0xE050          # las naves que quedan
ZONA = 0xE053           # el numero de zona, el que sirve de indice
DEPOSITO = 0xE51C       # el combustible
FILA_NAVE = 0xE7D0      # la fila de la nave, en pixeles
EN_PARTIDA = 0xE002     # el bit 6 dice que hay partida en curso


def arranca(rom):
    """Enciende la maquina, corre el INIT y empieza una partida de un jugador."""
    z = Z80()
    z.carga(rom, 0x4000)
    z.corre_hasta(INIT, QUIETO)
    for _ in range(40):
        z.corre(INTERRUPCION)
    z.maq.teclado[0] = 0xFD                 # la tecla 1: un jugador
    for _ in range(120):
        z.corre(INTERRUPCION)
    z.maq.teclado[0] = 0xFF
    return z


def mando(z):
    """El piloto: se mantiene a media altura y no suelta el disparo."""
    m = 0xEF                                # el bit 4, el disparo, siempre
    fila = z.mem[FILA_NAVE]
    if fila > 0x30:
        m &= ~1                             # arriba
    elif fila < 0x20:
        m &= ~2                             # abajo
    return m


def recorre(rom, cuadros=200_000, zonas=8):
    """Vuela guardando la columna que entra en cada paso, zona a zona."""
    z = arranca(rom)
    mapas = {}
    zona = z.mem[ZONA]
    cols = []
    antes = None
    naves = z.mem[NAVES]
    for i in range(cuadros):
        z.mem[DEPOSITO] = 0x40              # el deposito, siempre lleno
        z.maq.mando = mando(z)
        z.corre(INTERRUPCION)

        tira = bytes(z.vdp.vram[DECORADO:DECORADO + ANCHO_DECORADO])
        if tira != antes:
            cols.append([tira[f * 32 + 31] for f in range(5)])
            antes = tira

        if z.mem[NAVES] != naves:
            # Al morir, la zona vuelve a empezar: lo capturado no vale.
            naves = z.mem[NAVES]
            if naves < 3:
                z.mem[NAVES] = 3
            cols = []
            antes = None
        if z.mem[ZONA] != zona:
            mapas[zona] = cols
            print("  zona %d: %d columnas (cuadro %d)" % (zona, len(cols), i))
            zona = z.mem[ZONA]
            cols = []
            antes = None
            if len(mapas) >= zonas:
                break
        if not z.mem[EN_PARTIDA] & 0x40:
            break
    if cols and zona not in mapas:
        mapas[zona] = cols
    return z, mapas


def dibuja(vram, cols):
    """Las cinco filas del decorado, con los tiles del tercio de abajo."""
    img = Image.new("RGB", (len(cols) * 8, 40))
    px = img.load()
    for c, columna in enumerate(cols):
        for f, tile in enumerate(columna):
            # Las filas 16 a 20 de la pantalla caen en el TERCER tercio.
            base = 0x1000 + tile * 8
            for y in range(8):
                patron = vram[0x2000 + base + y]
                color = vram[0x0000 + base + y]
                tinta, fondo = PALETA[color >> 4], PALETA[color & 0x0F]
                for b in range(8):
                    px[c * 8 + b, f * 8 + y] = \
                        tinta if patron & (0x80 >> b) else fondo
    return img


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    with open(argv[1], "rb") as f:
        rom = f.read()
    salida = argv[2]
    os.makedirs(salida, exist_ok=True)
    print("Volando el cartucho para capturar el decorado:")
    try:
        z, mapas = recorre(rom)
    except ParadaZ80 as e:
        print("  el interprete se ha parado:", e)
        return 1
    for zona, cols in sorted(mapas.items()):
        if len(cols) < 32:
            continue
        img = dibuja(z.vdp.vram, cols)
        ruta = os.path.join(salida, "mapa_zona%02d.png" % (zona + 1))
        img.save(ruta)
        print("  %-24s %d x %d  (%d columnas)"
              % (os.path.basename(ruta), img.width, img.height, len(cols)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
