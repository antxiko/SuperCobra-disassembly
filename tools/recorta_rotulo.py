#!/usr/bin/env python3
"""Recorta el rotulo SUPER COBRA de la captura de la pantalla del titulo.

    python3 tools/recorta_rotulo.py docs/imagenes/titulo.png docs/imagenes/logo.png

POR QUE NO SE RECONSTRUYE. El resto de dibujos de la web salen de la ROM
(tools/graficos.py), pero el rotulo del titulo no se puede sacar de un solo
momento: MONTA_EL_TITULO (0x48B4) deja unos colores y el estado 04 y el 06
vuelven a tocar la misma tabla despues, asi que el color con el que se ve el
rotulo no es el que hay al acabar de montarlo. Lo que se ve de verdad es la
pantalla, y de ahi se recorta.

La captura de openMSX son 320x240: los 256x192 de la pantalla mas el borde. El
rotulo cae en las filas 64 a 84 -por debajo empieza el "(c) Konami 1983"-, y
las columnas se buscan solas: la primera y la ultima que tengan tinta.
"""
import struct
import sys
import zlib

FILA_ALTA, FILA_BAJA = 62, 86       # la banda del rotulo, sin el (c) Konami
UMBRAL = 40                         # por encima de esto, un pixel es tinta
MARGEN = 4                          # pixeles de aire alrededor del recorte
ESCALA = 2


def lee_png(fn):
    """Solo lo que hace falta: PNG de 8 bits en color verdadero, sin paleta."""
    d = open(fn, "rb").read()
    p, idat, w, h, bd, ct = 8, b"", 0, 0, 0, 0
    while p < len(d):
        ln = struct.unpack(">I", d[p:p + 4])[0]
        tipo, dat = d[p + 4:p + 8], d[p + 8:p + 8 + ln]
        if tipo == b"IHDR":
            w, h, bd, ct = struct.unpack(">IIBB", dat[:10])
        elif tipo == b"IDAT":
            idat += dat
        p += 12 + ln
    if (bd, ct) != (8, 2):
        sys.exit("%s no es un PNG de 8 bits en color verdadero" % fn)
    raw = zlib.decompress(idat)
    bpp, stride = 3, w * 3
    filas, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        filtro = raw[i]
        i += 1
        ln_ = bytearray(raw[i:i + stride])
        i += stride
        for x in range(stride):
            a = ln_[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if filtro == 1:
                ln_[x] = (ln_[x] + a) & 255
            elif filtro == 2:
                ln_[x] = (ln_[x] + b) & 255
            elif filtro == 3:
                ln_[x] = (ln_[x] + (a + b) // 2) & 255
            elif filtro == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                ln_[x] = (ln_[x] + pr) & 255
        filas.append([tuple(ln_[x * 3:x * 3 + 3]) for x in range(w)])
        prev = ln_
    return w, h, filas


def escribe_png(fn, filas):
    alto, ancho = len(filas), len(filas[0])
    raw = b"".join(b"\x00" + bytes(v for px in f for v in px) for f in filas)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff))

    open(fn, "wb").write(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def main():
    origen, destino = sys.argv[1], sys.argv[2]
    w, h, filas = lee_png(origen)
    banda = filas[FILA_ALTA:FILA_BAJA]
    columnas = [x for x in range(w)
                if any(max(f[x]) > UMBRAL for f in banda)]
    if not columnas:
        sys.exit("no hay tinta en las filas %d-%d de %s"
                 % (FILA_ALTA, FILA_BAJA, origen))
    x0 = max(0, min(columnas) - MARGEN)
    x1 = min(w, max(columnas) + 1 + MARGEN)
    recorte = [[px for px in f[x0:x1] for _ in range(ESCALA)]
               for f in banda for _ in range(ESCALA)]
    escribe_png(destino, recorte)
    print("  %s: filas %d-%d, columnas %d-%d, %dx%d al %dx"
          % (destino, FILA_ALTA, FILA_BAJA, x0, x1,
             len(recorte[0]), len(recorte), ESCALA))


if __name__ == "__main__":
    main()
