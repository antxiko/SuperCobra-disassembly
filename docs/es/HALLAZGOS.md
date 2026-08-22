# Hallazgos

Todo lo de esta página está medido sobre el binario, y dice con qué
herramienta.

## Konami se copiaba a sí misma, y se puede contar

`tools/comun_konami.py` indexa todos los trozos de doce bytes de un cartucho,
recorre el otro y estira cada coincidencia hasta donde llega. Lo que salen son
tiras **idénticas** y sin solapes. Descarta las que tengan menos de cuatro
valores distintos, para que un relleno de ceros no cuente como rutina
compartida.

Con el umbral de la herramienta —24 bytes seguidos, que es donde una
coincidencia deja de poder ser casualidad—, Super Cobra contra los otros
cartuchos de Konami de esta serie:

| contra | tiras | bytes |
|---|---|---|
| Athletic Land | 8 | **400** |
| Monkey Academy | 4 | 287 |
| Antarctic Adventure | 7 | 239 |
| Time Pilot | 1 | 28 |
| Frogger | 0 | **0** |

Los 28 bytes de Time Pilot **no son una rutina**: son el logotipo KONAMI
pequeño de 0x43BE, un dibujo. Y contra Frogger no hay ni un byte seguido: son
dos cartuchos del mismo año, de la misma casa y del mismo tamaño, y no
comparten nada de código.

Lo que Super Cobra comparte de verdad es con Athletic Land, Monkey Academy y
Antarctic Adventure: las tres rutinas de vídeo (0x4013), el lector de mandos
(0x484B), el logotipo KONAMI grande —147 bytes **idénticos**— y el reproductor
de sonido.

## El reproductor de sonido no está copiado: está revisado

Es lo más grande que comparte con Athletic Land, y no encaja de un solo golpe:
**no hay un desplazamiento único que alinee los dos**. Bajando el umbral a ocho
bytes, de los 320 de 0x5D30–0x5E70 hay **177 —el 55,3 %— dentro de una tira
idéntica**, repartidos en seis tiras cuyos desplazamientos van de 0x1B0B a
0x1B28. Las dos mayores son 74 bytes en 0x5DCE y 41 en 0x5E38.

Un desplazamiento que se mueve 29 bytes a lo largo del mismo bloque es la firma
de un código al que le han metido y quitado trozos por el medio, no de un
copia y pega.

## Este cartucho no lleva la marca oculta de Konami

Manuel Pazos ([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) descubrió
que los cartuchos de Konami esconden al final de la ROM su número de catálogo
RC-7xx y el título del juego en katakana.

**Aquí no está.** El último byte con contenido es 0x5FF3 —el final de la última
pista de sonido— y de 0x5FF4 a 0x5FFF hay doce bytes de 0xFF y nada más. El
"RC-705" de esta web sale del catálogo, no del binario.

## Las letras del juego son las de la máquina

`SUBE_FUENTE` (0x4AA0) hace `ld hl,(00004h)`. Esa dirección es **CGTBL**, el
puntero a la fuente que la ROM del BASIC guarda ahí, y de ahí se suben 0x180
bytes: 48 caracteres, del `0` al `_`.

Ni las cifras del marcador ni las palabras del menú están dentro del cartucho.
En la imagen de los tiles de [El cartucho](EL-CARTUCHO.html) se ve el agujero:
todo lo gris es lo que llega de fuera.

## Una rutina que pinta y borra según por dónde entres

`PINTA_DIBUJO` está en 0x4068 y `BORRA_DIBUJO` dos bytes antes, en 0x4064. La
única diferencia es el valor que cargan en C: 0xFF una y 0x00 la otra. Abajo, en
el bucle, hay un `and c` (0x4076) que con 0xFF deja el byte tal cual y con 0x00
lo convierte en cero.

Es el mismo bucle pintando y borrando, y el juego lo usa así de verdad: el
cartel INVASION SUCCEEDED se pinta entrando por 0x4068 y se quita entrando por
0x4064 (0x5C63 y 0x5C7D).

Lo mismo pasa con los submodos: el 2 entra en 0x5275 y el 4 en 0x5278, tres
instrucciones más adentro. La misma rutina, dos trabajos distintos.

## Cuatro tablas que empiezan dentro de una instrucción

No es un error de lectura, y no es una: son cuatro.

| tabla | arranca sobre |
|---|---|
| 0x566B, los desplazamientos de la explosión | el operando del `jp 0x5B85` de 0x566A |
| 0x58D6, cuántos salen por zona | el operando del `jp 0x5C96` de 0x58D5 |
| 0x55D3, los márgenes de la bomba | el `call 0x4C93` y el `scf`/`ret` de 0x55D2 |
| 0x5E5F, la base de los punteros de pista | los dos últimos periodos de nota |

En las tres primeras, las entradas que caen encima del código **no se pueden
usar**: en 0x566B el índice llega dividido por dos y nunca vale 0 ni 1; en
0x58D6 las zonas 0 y 1 no llegan a leerla; en 0x55D3 la familia 0 tampoco.

La cuarta es distinta y más fea: `SONIDO_PISTAS` (0x5CD8) usa como base 0x5E5F,
**dos bytes antes** de la primera palabra de verdad. La entrada 0 se monta sobre
los dos últimos periodos de nota y apunta a 0x383C, que está fuera del cartucho.
El sonido número 0 no se puede pedir, y nadie lo pide.

## Un byte que es dos cosas a la vez

El flujo de rótulos del menú empieza en 0x443A y su `0x00` de cierre cae en
**0x4560**. Y 0x4560 es también la dirección que `MONTA_EL_MAPA` le pasa a
`DESPLIEGA` como primer dibujo del suelo (0x4135), porque `DESPLIEGA` hace `inc
de` antes de leer y por tanto empieza justo ahí.

El mismo byte es el final de un dibujo y el principio del siguiente.

## El registro de refresco como dado

`PUNTOS_DE_PREMIO` (0x501E) necesita un número al azar y no tiene generador. Usa
**el registro R del Z80**, el contador de refresco de la memoria dinámica, que
va subiendo solo con cada instrucción que se ejecuta. Sus dos bits bajos dan 0,
1, 2 o 3, y eso se sube al byte alto del premio: 0, 100, 200 o 300 puntos.

## Una instrucción que el Z80 no tiene

Los siete bytes de 0x41DD se copian a 0xE5F8 y se ejecutan desde la RAM porque
se **escriben encima su propio desplazamiento**: son un `ld (IX+A),B`, que no
existe. Está contado en [El código](EL-CODIGO.html).
