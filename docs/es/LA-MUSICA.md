# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`SUENA`, 0x5D31, y `SUENA_ESTO`, 0x5C96, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la fanfarria de la demostración (0x89) entera, 258 cuadros;
- la pista larga 0x8C entera, 1.307 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`SUENA_ESTO` recibe el número en A. Del 0x89 al 0x8C usa dos canales y del 0x8D en adelante los tres; por debajo, un efecto con un solo canal. En el listado solo se ven dos peticiones de música, la 0x89 y la 0x8B; el resto de lo que pide el juego en la partida son efectos (el zumbido del motor, el disparo, la bomba). Las 0x8A y 0x8C están en la tabla de pistas pero ninguna rutina las pide con un `ld a`. El motor no escribe el mezclador del PSG: lo deja `ARRANCA_EL_SONIDO` (0x47FC), 0xB8, y aquí se parte de ese mismo valor.

## Las músicas

**La fanfarria de la demostración** (0x89)

Lo pide `ESTADO_08_DEMO` (0x47C1), antes de arrancar la demostración; dura 4,3 s.

<audio controls preload="none" src="../audio/musica_89.mp3?v=80faec8a"></audio>

**Una pista corta de la tabla** (0x8A)

Lo pide ninguna llamada directa: está en la tabla de pistas (0x5E5F); dura 5,3 s.

<audio controls preload="none" src="../audio/musica_8A.mp3?v=1700eef7"></audio>

**El aviso al parar la nave** (0x8B)

Lo pide `LA_NAVE_SE_PARA` (0x509C) y `MARCA_EL_TRAMO_FINAL` (0x537D); dura 5,3 s.

<audio controls preload="none" src="../audio/musica_8B.mp3?v=3b1c6f48"></audio>

**Una pista larga de la tabla** (0x8C)

Lo pide ninguna llamada directa: está en la tabla de pistas (0x5E5F); dura 21,8 s.

<audio controls preload="none" src="../audio/musica_8C.mp3?v=73fad73d"></audio>
