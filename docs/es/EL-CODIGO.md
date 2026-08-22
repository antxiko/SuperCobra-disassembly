# El código

## Todo pasa en la interrupción

INIT deja la máquina lista y se para en un `jr $` (0x40AD) del que no sale
nunca. Lo único que corre a partir de ahí es el gancho H.KEYI, o sea 0x402B, una
vez por fotograma.

Y dentro de ese gancho el orden importa:

    402B  in a,(099h)        leer el estado del VDP baja la petición
    402E  call SUENA         el sonido, ANTES del candado
    4031  ld a,(0E005h)      0xE005 es el candado
          or a / ret nz      si no está a cero, no se entra otra vez
    4038  ld (hl),a / ei     se echa el candado y se abren las interrupciones

**El sonido va antes del candado a propósito**: un paso del juego puede durar
más de un fotograma, y la música tiene que seguir sonando por encima. Y las
interrupciones se abren *dentro* de la interrupción, con el candado ya echado,
para que la siguiente entre, toque el sonido y se vuelva sin pisar el paso que
sigue a medias.

## El despachador que no vuelve

`DESPACHA` (0x4050) no lleva la tabla aparte. Hace `pop hl` —que no deshace la
llamada, sino que **coge la dirección de retorno para usarla de base**—, suma el
índice por dos, lee la palabra y termina en `jp (hl)`. Por eso la tabla va
pegada justo detrás del `call`, y por eso no se vuelve nunca a él.

Hay dos:

| dónde | entradas | índice | |
|---|---|---|---|
| 0x46AD | 15 palabras | (0xE000) | el estado del juego |
| 0x516F | 8 palabras | (0xE003) and 7 | el submodo de la partida |

Que termine en `jp (hl)` en vez de en `call` tiene una consecuencia: el `ret` de
la rutina despachada **no vuelve al despachador**, vuelve a lo que hubiera
dejado el llamador en la pila. 0x4691 se aprovecha de eso haciendo `push hl` con
la dirección de otra rutina antes de despachar. Es lo que hace que 0x488B y
0x49EA se ejecuten sin que nadie las llame.

## Los quince estados

El estado vive en 0xE000 y casi todas las rutinas acaban en el mismo par de
líneas: 0x4742 deja A en 0xE004 —el temporizador— y cae en 0x4745, que sube
0xE000. Los que esperan miran 0xE004 con `dec (hl) / ret nz`.

| | |
|---|---|
| 00 | sube los registros del VDP y deja la pantalla puesta |
| 01 | sube el KONAMI grande una fila cada dos fotogramas |
| 02, 03, 05 | esperas |
| 04 | limpia y monta la pantalla del título |
| 06 | monta el menú de PLAY SELECT |
| 07 | espera a que se elija |
| 08 | la demostración |
| 09 | descuenta una vida y anuncia de quién es el turno |
| 10 | borra el anuncio y suelta al jugador |
| 11 | **el juego**; aquí se está hasta que 0xE06F se apaga |
| 12 | mira si al jugador activo le quedan vidas |
| 13 | cambia el turno |
| 14 | fin de partida, salvo que el otro jugador siga vivo |

El 08 es el raro: es el único al que se entra sin `push`, así que su `ret`
vuelve al llamador en vez de al despachador.

![El logotipo subiendo](../imagenes/logotipo.png)

*El estado 01. `SUBE_LOGOTIPO` (0x4CBF) sube el KONAMI de abajo arriba, una fila
de 32 bytes por llamada, y lo pinta partido en tres: tres tiles arriba, once en
medio y doce abajo.*

## Los ocho submodos

Dentro de un paso de partida, la tabla de 0x516F se indexa con **el contador de
fotogramas** y 7. No son estados que se sucedan: son ocho trabajos que se
turnan, uno por fotograma, porque no caben todos en el mismo.

| | |
|---|---|
| 0 | cambia de búfer y sube el decorado a la pantalla |
| 1 | el gemelo del 0 para la mitad de arriba |
| 2 y 6 | la llama del motor, y luego mueven lo que vuela |
| 3 | gasta combustible |
| 4 | mueve lo que vuela, **sin** tocar la llama |
| 5 | suelta lo que dispara el decorado |
| 7 | la dificultad |

El 4 es el único de los ocho que **no entra por el principio de una rutina**:
apunta a 0x5278, tres instrucciones más adentro del 2, justo detrás del `call`
que mueve la llama del motor. La misma rutina hace dos trabajos distintos según
por dónde se entre.

## El decorado

El terreno de la fase se monta entero en la RAM al empezar la partida
(`MONTA_EL_MAPA`, 0x4106), y se monta **a doble búfer**: 0xE50D alterna entre 0
y 1 con un `xor 1`, y de ahí sale la página, 0xE800 con el 0 y 0xEA00 con el 1.
Mientras uno se vuelca a la memoria de vídeo, el otro se está montando.

Correrlo una columna son cinco tandas de 0x1F bytes, cada una desplazada un
sitio (0x532F). Cinco filas, y entre fila y fila 0x20 bytes: una columna de
arriba abajo.

Lo que se despliega en el búfer sale de una **receta** (0x45E5): un byte por
tramo, los dos bits bajos dicen de qué clase es y el resto, dónde va.

## Los siete bytes que se ejecutan en la RAM

0x412B copia siete bytes de 0x41DD a 0xE5F8 y desde entonces se los llama como
rutina. Montados allá son:

    E5F8  32 FD E5     ld (0E5FDh),a
    E5FB  DD 70 00     ld (ix+000h),b
    E5FE  C9           ret

0xE5FD **es el tercer byte del `ld (ix+000h),b`**, o sea su propio
desplazamiento. La rutina se escribe encima el desplazamiento con A y entonces
guarda B: es `ld (IX+A),B`, que el Z80 no sabe hacer, porque el desplazamiento
de IX es un byte fijo del opcode y no un registro.

Por eso hay que ejecutarla en RAM, y por eso son **los únicos siete bytes de
este cartucho que no corren desde la ROM**.

## Chocar

`HAY_CHOQUE` (0x53DC) es un solo test para todo: resta la posición del otro y su
ancho, le suma el ancho propio, y si eso no se desborda, en ese eje no se tocan.
Lo mismo en el otro eje, y solo hay choque si se pisan en los dos. Los tamaños
van siempre en (HL), y cada cosa trae su tabla:

| | |
|---|---|
| 0x5607 | lo que vuela, cuatro bytes por clase de zona |
| 0x55D3 | la bomba contra el decorado, por familia de tile |
| 0x55E3 | la bomba, por dibujo de la ficha |
| 0x55F3 | el disparo, por dibujo de la ficha |
| 0x5634 | los tiles del 0x87 para arriba, que ocupan más de una casilla |
| 0x5648 | el depósito del final de zona |
| 0x564C | la base |

En cada fotograma se encadenan tres comprobaciones (0x5139) y **en cuanto una da
carry las demás no se miran**. Entre las columnas 0x99 y 0xA1 no se mira
ninguna: es el paso de fase.
