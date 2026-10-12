#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `SUENA_ESTO` (0x5C96, A = numero) y corre `SUENA` (0x5D31),
el reproductor que cada cuadro llama la interrupcion.
Uso:  musica.py registros 0x89 [cuadros] | mp3 0x89 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

PIEZAS = [
    P(0x89, "La fanfarria de la demostración", "The demo fanfare",
      "`ESTADO_08_DEMO` (0x47C1), antes de arrancar la demostración"),
    P(0x8A, "Una pista corta de la tabla", "A short track in the table",
      "ninguna llamada directa: está en la tabla de pistas (0x5E5F)"),
    P(0x8B, "El aviso al parar la nave", "The warning as the ship stops",
      "`LA_NAVE_SE_PARA` (0x509C) y `MARCA_EL_TRAMO_FINAL` (0x537D)"),
    P(0x8C, "Una pista larga de la tabla", "A long track in the table",
      "ninguna llamada directa: está en la tabla de pistas (0x5E5F)"),
]

PAGINA = motor_musica.pagina_basica(
    "`SUENA`, 0x5D31, y `SUENA_ESTO`, 0x5C96, que le reparte los canales; lo "
    "llama la interrupción",
    "`SUENA`, 0x5D31, and `SUENA_ESTO`, 0x5C96, which hands it the channels; "
    "the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la fanfarria de la demostración (0x89) entera, 258 cuadros",
      "the demo fanfare (0x89), whole, 258 frames"),
     ("la pista larga 0x8C entera, 1.307 cuadros",
      "the long track 0x8C, whole, 1,307 frames")],
    [("Cómo se pide una pieza",
      "`SUENA_ESTO` recibe el número en A. Del 0x89 al 0x8C usa dos canales y "
      "del 0x8D en adelante los tres; por debajo, un efecto con un solo "
      "canal. En el listado solo se ven dos peticiones de música, la 0x89 y la 0x8B; "
      "el resto de lo que pide el juego en la partida son efectos (el zumbido "
      "del motor, el disparo, la bomba). Las 0x8A y 0x8C están en la tabla de pistas pero "
      "ninguna rutina las pide con un `ld a`. El motor no escribe el "
      "mezclador del PSG: lo deja `ARRANCA_EL_SONIDO` (0x47FC), 0xB8, y aquí "
      "se parte de ese mismo valor.",
      "How a piece is asked for",
      "`SUENA_ESTO` takes the number in A. From 0x89 to 0x8C it uses two "
      "channels and from 0x8D up all three; below that, an effect on a "
      "single channel. The listing shows only two music requests, 0x89 and "
      "0x8B; the rest of what the game asks for during play are effects (the "
      "engine hum, the shot, the bomb). Tracks 0x8A and 0x8C are in the track table but "
      "no routine asks for them with an `ld a`. The engine never writes the "
      "PSG mixer: `ARRANCA_EL_SONIDO` (0x47FC) sets it to 0xB8, and here it "
      "starts from that same value.")])

CFG = dict(rom="supercobra.rom", org=0x4000, frame=0x5D31, pide=0x5C96,
           ram=(0xE010, 0xE02E), hz=60, psg0={7: 0xB8}, piezas=PIEZAS,
           pagina=PAGINA, cotejado=[(0x89, 258, None), (0x8C, 1307, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
