#!/usr/bin/env python3
"""Reconstruye la VRAM de Super Cobra tal como la deja el cartucho y la pinta.

    python3 tools/graficos.py supercobra.rom work/gfx

QUE HACE. Repite, en el mismo orden y con las mismas direcciones, lo que hace
MONTA_EL_TITULO (0x48B4) al arrancar. Los dos interpretes de dibujo del
cartucho estan copiados instruccion a instruccion del listado, no leidos a ojo:

    PINTA_ROTULO      0x4AC6   direccion de VRAM, y detras bytes de mando:
                               con el bit 7, C bytes distintos (0x4A69);
                               sin el, C veces el mismo (0x4A61);
                               0x80 abre otro tramo y 0x00 cierra el dibujo
    PINTA_DIBUJO      0x4068   direccion de VRAM y bytes en crudo, con 0xFE
                               entre tramo y tramo y 0xFF al final

Las direcciones que maneja el juego llevan sumado 0x4000 -el bit de ESCRITURA
que VPOKE le pone a D-, asi que la direccion de verdad es la de abajo del todo:
0x6300 es la VRAM 0x2300. Los registros del VDP (0x4830) reparten asi los
16 KB de la VRAM:

    0x0000  tabla de color         0x1800  patrones de SPRITE
    0x2000  tabla de patrones      0x3800  tabla de nombres
                                   0x3B00  fichas de sprite

Salen tres PNG:

    tiles.png     los 256 tiles del tercio de arriba, patron y color. Los que
                  el cartucho NO trae salen en gris: las letras y las cifras
                  las copia SUBE_FUENTE (0x4AA0) de la ROM del BASIC, no estan
                  aqui dentro
    sprites.png   los dibujos de sprite de 16x16 de la VRAM 0x1800, que es el
                  unico sitio donde escribe el flujo de 0x443A
    logo_konami.png  los 26 tiles del KONAMI grande de 0x4CFA, montados como
                  los monta SUBE_LOGOTIPO (0x4CBF): tres, once y doce. OJO:
                  este es el logotipo de la CASA. El rotulo del JUEGO no sale
                  de aqui, lo recorta tools/recorta_rotulo.py de la captura
"""
import os
import struct
import sys
import zlib

ORG = 0x4000

# La paleta del TMS9918, en el orden en que la numera el VDP.
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237),
       (125, 118, 252), (212, 82, 77), (66, 235, 245), (252, 85, 84),
       (255, 121, 120), (212, 193, 84), (230, 206, 128), (33, 176, 59),
       (201, 91, 186), (204, 204, 204), (255, 255, 255)]

GRIS = (56, 56, 64)          # lo que no viene del cartucho
REJILLA = (90, 90, 96)


def png(w, h, filas, fn):
    raw = b"".join(b"\x00" + bytes(v for p in f for v in p) for f in filas)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff))

    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw))
                + chunk(b"IEND", b""))


class VRAM:
    """Los 16 KB del VDP, y ademas la cuenta de que bytes ha tocado el cartucho."""

    def __init__(self):
        self.m = bytearray(0x4000)
        self.puesto = bytearray(0x4000)

    def pon(self, dir, valor):
        dir &= 0x3FFF                      # VPOKE pone el bit 6 de D: se quita
        self.m[dir] = valor
        self.puesto[dir] = 1

    def llena(self, dir, n, valor):
        for i in range(n):
            self.pon(dir + i, valor)

    def bloque(self, datos, dir):
        for i, b in enumerate(datos):
            self.pon(dir + i, b)


def pinta_rotulo(rom, v, hl, de=None):
    """PINTA_ROTULO (0x4AC6) y PINTA_ROTULO_EN_DE (0x4ACA).

    Con `de` puesto se entra por 0x4ACA, que es lo que hacen PINTA_LOGOTIPO
    (0x4CAB) y PINTA_SEIS_VECES (0x41D0): la direccion ya viene dada y el flujo
    empieza directamente en el primer byte de mando.
    """
    p = hl - ORG
    if de is None:
        de = rom[p] | (rom[p + 1] << 8)
        p += 2
    while True:
        mando = rom[p]
        c = mando & 0x7F
        p += 1
        if c == 0:                          # 0x4AD6: la cuenta a cero
            if mando == 0:                  # 0x00 cierra el rotulo entero
                return p + ORG
            de = rom[p] | (rom[p + 1] << 8)  # 0x80 abre otro tramo
            p += 2
            continue
        if mando & 0x80:                    # 0x4ADF -> 0x4A69: C bytes distintos
            for i in range(c):
                v.pon(de + i, rom[p + i])
            p += c
        else:                               # 0x4AE3 -> 0x4A61: C veces el mismo
            for i in range(c):
                v.pon(de + i, rom[p])
            p += 1
        de += c


def pinta_dibujo(rom, v, hl, borra=False):
    """PINTA_DIBUJO (0x4068) y BORRA_DIBUJO (0x4064): el `and c` decide."""
    p = hl - ORG
    while True:
        de = rom[p] | (rom[p + 1] << 8)
        p += 2
        while True:
            b = rom[p]
            p += 1
            if b == 0xFF:                   # 0x4072: se acabo el dibujo
                return p + ORG
            if b == 0xFE:                   # 0x4074: otro tramo
                break
            v.pon(de, 0 if borra else b)
            de += 1


def repite_tercios(v):
    """REPITE_TERCIOS (0x4A95): el tercio de arriba, copiado en los otros dos."""
    for tabla in (0x2000, 0x0000):
        for tercio in (1, 2):
            for i in range(0x800):
                if v.puesto[tabla + i]:
                    v.m[tabla + tercio * 0x800 + i] = v.m[tabla + i]
                    v.puesto[tabla + tercio * 0x800 + i] = 1


def monta_el_titulo(rom):
    """MONTA_EL_TITULO (0x48B4), llamada por llamada."""
    v = VRAM()
    # 0x48B4: SUBE_FUENTE_COLOR con DE=0x4008 y A=0x70. El color si es suyo;
    # los 0x180 bytes de patron salen de la ROM del BASIC y aqui no los hay.
    v.llena(0x0008, 0x180, 0x70)
    # 0x48BC: PINTA_LOGOTIPO (0x4CAB)
    pinta_rotulo(rom, v, 0x4CFA, de=0x6300)
    v.llena(0x0300, 0xD0, 0xF0)
    # 0x48BF: SUBE_FUENTE (0x4AA0), otra vez solo el color
    v.llena(0x0180, 0x180, 0xF0)
    # 0x48C2: MONTA_PANTALLA_TITULO (0x40BB)
    pinta_rotulo(rom, v, 0x4248)
    hl = 0x2787                             # 0x40C1: ocho retoques de nueve en nueve
    for _ in range(8):
        v.pon(hl, 0)
        hl += 9
    v.bloque(rom[0x42D1 - ORG:0x42D1 - ORG + 8], 0x6030)   # 0x40D4
    for base, flujo in ((0x4490, 0x4427), (0x4510, 0x4431)):   # PINTA_SEIS_VECES
        de = base
        for _ in range(6):
            pinta_rotulo(rom, v, flujo, de=de)
            de += 0x10
    repite_tercios(v)                       # 0x40F1
    v.llena(0x0408, 0x30, 0x02)             # 0x40F4
    pinta_rotulo(rom, v, 0x443A)            # 0x40FF: los dibujos de SPRITE
    pinta_rotulo(rom, v, 0x4BBC)            # 0x48C5: VIDEO CARTRIDGE
    return v


# ---------------------------------------------------------------- los dibujos
def tile(v, tercio, t, esc):
    """Un tile de 8x8 con su color, como lo pinta el VDP en SCREEN 2."""
    pat = 0x2000 + tercio * 0x800 + t * 8
    col = 0x0000 + tercio * 0x800 + t * 8
    if not any(v.puesto[pat:pat + 8]):
        return [[GRIS] * (8 * esc) for _ in range(8 * esc)]
    filas = []
    for r in range(8):
        c = v.m[col + r]
        fg, bg = PAL[c >> 4], PAL[c & 15]
        fila = []
        for b in range(8):
            fila += [fg if (v.m[pat + r] >> (7 - b)) & 1 else bg] * esc
        filas += [fila] * esc
    return filas


def rejilla(ancho):
    return [REJILLA] * ancho


def pinta_tiles(v, fn, tercio=0, esc=3):
    ancho = 16 * (8 * esc + 1) + 1
    out = [rejilla(ancho)]
    for fila in range(16):
        filas = [rejilla(ancho) for _ in range(8 * esc)]
        for c in range(16):
            px = tile(v, tercio, fila * 16 + c, esc)
            x0 = 1 + c * (8 * esc + 1)
            for r in range(8 * esc):
                filas[r][x0:x0 + 8 * esc] = px[r]
        out += filas
        out.append(rejilla(ancho))
    png(ancho, len(out), out, fn)


def pinta_sprites(v, fn, cuantos=16, esc=3):
    """Los patrones de 16x16 de la VRAM 0x1800: cuatro cuartos de 8x8."""
    ancho = 8 * (16 * esc + 1) + 1
    out = [rejilla(ancho)]
    for fila in range((cuantos + 7) // 8):
        filas = [rejilla(ancho) for _ in range(16 * esc)]
        for c in range(8):
            base = 0x1800 + (fila * 8 + c) * 32
            x0 = 1 + c * (16 * esc + 1)
            for r in range(16):
                bits = (v.m[base + r] << 8) | v.m[base + 16 + r]
                hay = v.puesto[base + r] or v.puesto[base + 16 + r]
                for b in range(16):
                    if not hay:
                        col = GRIS
                    else:
                        col = ((255, 255, 255) if (bits >> (15 - b)) & 1
                               else (16, 16, 24))
                    for dy in range(esc):
                        for dx in range(esc):
                            filas[r * esc + dy][x0 + b * esc + dx] = col
        out += filas
        out.append(rejilla(ancho))
    png(ancho, len(out), out, fn)


def pinta_logo(v, fn, esc=3):
    """SUBE_LOGOTIPO (0x4CBF): tres tiles arriba, once en medio y doce abajo."""
    trozos = [(0x60, 3), (0x63, 11), (0x6E, 12)]
    ancho = 12 * 8 * esc
    out = []
    for base, cuantos in trozos:
        filas = [[PAL[0]] * ancho for _ in range(8 * esc)]
        for i in range(cuantos):
            px = tile(v, 2, base + i, esc)      # los sube al tercio de abajo
            x0 = i * 8 * esc
            for r in range(8 * esc):
                filas[r][x0:x0 + 8 * esc] = px[r]
        out += filas
    png(ancho, len(out), out, fn)


def main():
    rom = open(sys.argv[1], "rb").read()
    salida = sys.argv[2]
    os.makedirs(salida, exist_ok=True)
    if len(rom) != 8192:
        sys.exit("la ROM tiene %d bytes y son 8192" % len(rom))
    v = monta_el_titulo(rom)
    pinta_tiles(v, os.path.join(salida, "tiles.png"))
    pinta_sprites(v, os.path.join(salida, "sprites.png"))
    pinta_logo(v, os.path.join(salida, "logo_konami.png"))
    print("  tabla de patrones : %4d de 2048 bytes puestos por el cartucho"
          % sum(v.puesto[0x2000:0x2800]))
    print("  dibujos de sprite : %4d de  512 bytes en la VRAM 0x1800"
          % sum(v.puesto[0x1800:0x1A00]))
    print("  PNG en %s/" % salida)


if __name__ == "__main__":
    main()
