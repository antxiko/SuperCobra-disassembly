# Preguntas abiertas

Lo que no se sabe. Nada de esto está disfrazado de hallazgo en ninguna otra
página de esta web.

## Dos bytes sin dueño

0x5632–0x5633: `0C 00`. Están entre las formas de tile del suelo —tres tiles de
tres bytes, 0x5629–0x5631— y las de los tiles grandes —cinco de cuatro bytes,
0x5634–0x5647—.

No encajan ni con las filas de tres de arriba ni con las de cuatro de abajo, y
en los 8192 bytes no hay ningún `ld hl,05632h` ni nada que caiga ahí. Están
declarados como datos porque el reensamblado lo exige, pero quién los lee no se
sabe.

## Dónde acaban de verdad las duraciones del sonido

0x5E85 es la tabla que `MUSICA_NOTA` (0x5E17) indexa con el nibble alto de la
nota, y detrás vienen las pistas del PSG. El problema es que los punteros de
0x5E61 apuntan a pistas que empiezan **dentro de ese primer tramo**: 0x5E89 y
0x5EA9.

O las duraciones que se usan de verdad son muy pocas, o esos bytes sirven para
las dos cosas a la vez. No está cerrado, y por eso el bloque está declarado
entero como `duraciones_y_pistas` en vez de partido en dos.

## Qué rótulo es el de 0x506D

`PINTA_EL_ROTULO_DE_FASE` (0x5012) despliega el dibujo de 0x506D en el búfer
del decorado, en 0xEB31. Y ese dibujo son **diez bytes de 0x00 y un 0xFF** que
lo cierra.

Pasados por `DESPLIEGA`, diez ceros no son diez columnas: sin ningún 0x50 de
por medio no se cambia de columna, así que las diez vueltas escriben en la
misma. Qué se supone que aparece ahí, y por qué hacen falta diez pasadas
iguales, no está comprobado.

## Nada medido en el emulador

Las tres capturas de esta web son pantallas reales de openMSX, pero aquí no hay
**ni una cifra** salida del emulador: ni el coste de la interrupción, ni cuántas
escrituras al VDP hace un fotograma, ni cuánto tarda una zona en pasar. Todo lo
demás sale de leer el binario.
