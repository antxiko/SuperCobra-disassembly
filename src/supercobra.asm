; ==========================================================================
; SUPER COBRA - Konami - MSX1 - cartucho RC-705 de 8 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera: Los dieciseis bytes que lee la BIOS al arrancar la maquina:
;   "AB", INIT=0x407D, y los otros tres punteros a cero. Este cartucho no
;   declara STATEMENT, ni DEVICE, ni TEXT.
;   0x4000..0x4010  (16 bytes)
DATA_cabecera:
	defb 041h,042h,07dh,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4000  AB}@............

; ======================================================================
; CODIGO 0x4010..0x41dd  (461 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Las rutinas de video, identicas a las de Athletic Land 0x401C
; ----------------------------------------------------------------------
VPEEK:		; Lee en A el byte de la VRAM DE
	di			;4010   ; Sin interrupciones desde que se pone la direccion hasta que se lee el dato
	call VDP_DIRECCION		;4011   ; Sin poner el bit 6 de D: direccion de LECTURA de la VRAM
	nop			;4014   ; Dos nop de margen entre mandar la direccion y leer el puerto de datos
	nop			;4015
	in a,(098h)		;4016   ; Puerto 0x98: el byte de la VRAM
	ei			;4018
	ret			;4019
VDP_DIRECCION:		; Manda DE al VDP como direccion (con el bit 6 de D a 1 es de escritura)
	ld a,e			;401a
	out (099h),a		;401b
	ld a,d			;401d
	out (099h),a		;401e
	ret			;4020
HL_MAS_A:		; HL = HL + A, sin signo
	add a,l			;4021
	ld l,a			;4022
	ret nc			;4023
	inc h			;4024
	ret			;4025
DE_MAS_A:		; DE = DE + A, sin signo
	add a,e			;4026
	ld e,a			;4027
	ret nc			;4028
	inc d			;4029
	ret			;402a

; ----------------------------------------------------------------------
; Cada fotograma: el sonido, y un paso del juego si el anterior ya acabo
; ----------------------------------------------------------------------
INTERRUPCION:		; El gancho H.KEYI. El juego entero corre aqui dentro
	di			;402b
	in a,(099h)		;402c   ; Leer el estado del VDP baja la peticion de interrupcion
	call SUENA		;402e   ; El sonido va antes del candado: suena aunque el paso anterior siga a medias
	ld hl,0e005h		;4031   ; 0xE005 es el candado: mientras no sea cero, no se entra otra vez
	bit 0,(hl)		;4034   ; El bit 0 de 0xE005 es el candado
	jr nz,LA_INTERRUPCION_TERMINA		;4036
	inc (hl)			;4038   ; Se echa el candado y se abren las interrupciones: un paso del juego dura mas de un fotograma y el sonido tiene que seguir sonando por encima
	ei			;4039
	call PUERTO_DEL_JOYSTICK		;403a   ; Los mandos, antes que el paso del juego
	call UN_PASO		;403d   ; Y el paso del juego
	di			;4040
	xor a			;4041
	ld (0e005h),a		;4042
LA_INTERRUPCION_TERMINA:
	ei			;4045
	reti		;4046

; ----------------------------------------------------------------------
; Escribir en la VRAM, y el despachador con la tabla pegada detras
; ----------------------------------------------------------------------
VPOKE:		; Escribe A en la VRAM DE
	di			;4048
	call VDP_ESCRITURA		;4049   ; 0x4A3D pone la direccion con el bit 6 de D a 1: escritura
	out (098h),a		;404c
	ei			;404e
	ret			;404f
DESPACHA:		; Salta a la entrada A de la tabla que va PEGADA detras del `call`
	add a,a			;4050   ; Dos bytes por entrada
	pop hl			;4051   ; El `pop` no deshace la llamada: coge la direccion de retorno para usarla como base de la tabla. Por eso la tabla va pegada detras del `call` y por eso no se vuelve nunca aqui
	call HL_MAS_A		;4052
	ld e,(hl)			;4055
	inc hl			;4056
	ld d,(hl)			;4057
	ex de,hl			;4058
	jp (hl)			;4059   ; Y se salta a la rutina, sin `call`: lo que quede en la pila manda al `ret`
INTERCAMBIA:		; Cambia entre si los B bytes de HL y los de DE
	ld c,(hl)			;405a   ; El byte de HL se aparta en C mientras entra el de DE
	ld a,(de)			;405b
	ld (hl),a			;405c
	ld a,c			;405d
	ld (de),a			;405e
	inc hl			;405f
	inc de			;4060
	djnz INTERCAMBIA		;4061
	ret			;4063

; ----------------------------------------------------------------------
; El pintor de la pantalla. La misma rutina pinta y borra: lo decide C
; ----------------------------------------------------------------------
BORRA_DIBUJO:		; Recorre el dibujo de HL escribiendo CEROS: lo borra
	ld c,000h		;4064   ; C = 0x00, asi que el `and c` de 0x4076 deja siempre 0
	jr PINTA_TRAMO		;4066
PINTA_DIBUJO:		; Vuelca el dibujo de HL en la VRAM
	ld c,0ffh		;4068   ; C = 0xFF, asi que el `and c` de 0x4076 deja el byte tal cual
PINTA_TRAMO:		; Toma del flujo la direccion de VRAM y va soltando bytes
	ld e,(hl)			;406a   ; Los dos primeros bytes del tramo son la direccion de la VRAM
	inc hl			;406b
	ld d,(hl)			;406c
	inc hl			;406d
PINTA_SIGUIENTE_BYTE:
	ld a,(hl)			;406e   ; 0xFF cierra el dibujo entero (el `inc b` lo deja a cero)
	inc hl			;406f
	ld b,a			;4070
	inc b			;4071
	ret z			;4072
	inc b			;4073   ; 0xFE cierra el tramo: se vuelve arriba a por otra direccion de VRAM
	jr z,PINTA_TRAMO		;4074
	and c			;4076   ; Aqui esta el truco: `and c` con 0xFF deja el byte y con 0x00 lo borra
	call VPOKE		;4077
	inc de			;407a
	jr PINTA_SIGUIENTE_BYTE		;407b

; ----------------------------------------------------------------------
; INIT: lo que llama la BIOS al encontrar la cabecera AB
; ----------------------------------------------------------------------
INIT:		; Deja la maquina lista y se queda quieto: todo pasa en la interrupcion
	di			;407d
	im 1		;407e
	ld sp,0f800h		;4080
	ld hl,0e000h		;4083   ; Borra de 0xE000 a 0xF7FF: toda la RAM que usa el juego, a cero
	ld de,0e001h		;4086
	ld bc,017ffh		;4089
	ld (hl),000h		;408c   ; El cero que se propaga por toda la RAM
	ldir		;408e
	ld a,0c3h		;4090   ; C3 = jp; el gancho H.KEYI queda como `jp 0x402B`
	ld (0fd9ah),a		;4092
	ld hl,INTERRUPCION		;4095   ; La direccion de la rutina de interrupcion
	ld (0fd9bh),hl		;4098
	ld a,001h		;409b   ; Candado echado mientras dura el arranque: la interrupcion no ejecuta pasos
	ld (0e005h),a		;409d   ; Y con el candado echado se hace el arranque largo
	call ARRANCA_EL_SONIDO		;40a0   ; El PSG y la VRAM
	call MONTA_EL_TITULO		;40a3   ; Y el menu de arranque
	in a,(099h)		;40a6   ; Leer el estado del VDP deja limpia la peticion de interrupcion
	xor a			;40a8
	ld (0e005h),a		;40a9
	ei			;40ac
AQUI_SE_QUEDA:
	jr AQUI_SE_QUEDA		;40ad   ; Y aqui se queda para siempre. El hilo principal no hace nada mas

; ----------------------------------------------------------------------
; Volcar a la VRAM sin perder HL
; ----------------------------------------------------------------------
VPOKE_HL:		; Escribe A en la VRAM HL, dejando DE como estaba
	ex de,hl			;40af
	call VPOKE		;40b0
	ex de,hl			;40b3
	ret			;40b4
VPEEK_HL:		; Lee en A el byte de la VRAM HL
	ex de,hl			;40b5
	call VPEEK		;40b6
	ex de,hl			;40b9
	ret			;40ba
MONTA_PANTALLA_TITULO:		; Pinta el rotulo, los colores y los tiles de la pantalla del titulo
	ld hl,04248h		;40bb
	call PINTA_ROTULO		;40be
	ld hl,02787h		;40c1   ; VRAM 0x2787 y de nueve en nueve: siete retoques sueltos en los patrones
	dec a			;40c4
	call VPOKE_HL		;40c5   ; Un byte por retoque
	inc hl			;40c8
	ld b,007h		;40c9   ; Siete retoques
RETOCA_LOS_PATRONES:
	call VPOKE_HL		;40cb
	ld de,00009h		;40ce   ; Y de nueve en nueve bytes en la VRAM
	add hl,de			;40d1
	djnz RETOCA_LOS_PATRONES		;40d2
	ld hl,042d1h		;40d4   ; Ocho bytes a la VRAM 0x6030: un tile del tercio de abajo
	ld de,06030h		;40d7
	ld b,008h		;40da
	call COPIA_A_VRAM		;40dc
	ld de,04490h		;40df   ; 0x4490 y 0x4510 son direcciones de la VRAM, no de la ROM: la tabla de color
	ld hl,04427h		;40e2
	call PINTA_SEIS_VECES		;40e5
	ld de,04510h		;40e8
	ld hl,04431h		;40eb
	call PINTA_SEIS_VECES		;40ee
	call REPITE_TERCIOS		;40f1
	ld a,002h		;40f4
	ld hl,00408h		;40f6   ; VRAM 0x0408, 0x30 bytes del color 2
	ld bc,00030h		;40f9
	call LLENA_VRAM_HL		;40fc
	ld hl,0443ah		;40ff
	call PINTA_ROTULO		;4102
	ret			;4105

; ----------------------------------------------------------------------
; El arranque de una partida: se monta en la RAM el mapa por el que se vuela
; ----------------------------------------------------------------------
MONTA_EL_MAPA:		; Construye en 0xE660 y siguientes el terreno de la fase
	ld a,0f9h		;4106
	ld hl,0e660h		;4108   ; 0xE660 en adelante: doce tandas (C) de ocho bytes (B)
	ld c,00ch		;410b
LLENA_UNA_TANDA:
	ld b,008h		;410d
LLENA_UN_BYTE:
	ld (hl),a			;410f   ; Ocho bytes iguales de golpe
	inc hl			;4110
	djnz LLENA_UN_BYTE		;4111
	dec c			;4113   ; Y cuando se acaban las doce tandas, fuera
	jr z,COPIA_LA_RUTINA_A_LA_RAM		;4114
	ld b,004h		;4116
	inc a			;4118   ; El relleno sube de 0xF9 en adelante, y se salta el 0xFB y el 0x05
	jr z,LLENA_UN_BYTE		;4119
	cp 0fah		;411b
	jr nz,SALTA_EL_CINCO		;411d
	ld a,0fch		;411f
SALTA_EL_CINCO:
	cp 005h		;4121
	jr nz,SIGUIENTE_TANDA		;4123
	inc a			;4125
SIGUIENTE_TANDA:
	jr LLENA_UNA_TANDA		;4126
COPIA_LA_RUTINA_A_LA_RAM:
	ld hl,041ddh		;4128   ; Y aqui se copia a 0xE5F8 la rutina que hace `ld (IX+A),B`
	ld de,0e5f8h		;412b
	ld bc,00007h		;412e
	ldir		;4131   ; Siete bytes, que es lo que ocupa la rutina
	ld c,080h		;4133   ; C = 0x80 es el relleno. De aqui a 0x417D se montan DOS decorados enteros y simetricos: el de abajo en 0xE800/0xEA00 y el de ARRIBA en 0xEC00/0xEE00
	ld de,04560h		;4135
	ld hl,0e8b6h		;4138   ; El primer dibujo, arriba
	call DESPLIEGA		;413b   ; El suelo: el dibujo 0x4560 en las dos paginas de abajo, 0xE8B6 y 0xEAB6
	ld hl,0eab6h		;413e   ; Y el mismo, mas abajo
	call DESPLIEGA		;4141
	ld hl,0ecbbh		;4144   ; Entre los dos, el suelo raso
	ld de,0ecbch		;4147   ; De 0xECBB a 0xECBC: un `ldir` que se copia a si mismo, otra vez
	ld (hl),c			;414a   ; Y aqui empieza el TECHO: 0x14B bytes de relleno en 0xECBB para asentarlo
	ld bc,0014bh		;414b
	push bc			;414e
	ldir		;414f
	ld de,0456ah		;4151
	ld hl,0ecb6h		;4154   ; El tercer dibujo
	call DESPLIEGA		;4157
	ld de,04560h		;415a
	ld l,0c9h		;415d   ; `ld l,0C9h` cambia solo el byte bajo: 0xECC9, y el dibujo es el 0x4560, el mismo del suelo
	call DESPLIEGA		;415f
	ld hl,0eebbh		;4162   ; Y el cuarto tramo, en la pagina de al lado
	ld de,0eebch		;4165
	ld (hl),080h		;4168   ; La segunda pagina del techo, 0xEE00, con el relleno puesto a mano
	pop bc			;416a
	ldir		;416b
	ld de,045ach		;416d
	ld hl,0eeb6h		;4170   ; Los dos ultimos dibujos
	call DESPLIEGA		;4173
	ld de,045a2h		;4176
	ld l,0c9h		;4179
	call DESPLIEGA		;417b
	ld hl,0e800h		;417e   ; El buffer de 0xE800, cuatro tercios de 0xBA bytes
	ld c,004h		;4181
LIMPIA_EL_BUFFER:
	ld b,0bah		;4183
LIMPIA_UNA_PAGINA:
	xor a			;4185   ; La pagina se llena de ceros de ocho en ocho
	ld (hl),a			;4186
	inc hl			;4187
	djnz LIMPIA_UNA_PAGINA		;4188
	ld l,a			;418a
	inc h			;418b   ; Dos `inc h`: de un tercio al siguiente
	inc h			;418c
	dec c			;418d   ; Y las cuatro pasadas que hay que dar
	jr nz,LIMPIA_EL_BUFFER		;418e

; ----------------------------------------------------------------------
; Montar el terreno de la fase leyendo la receta de 0x45E5
; ----------------------------------------------------------------------
MONTA_EL_TERRENO:		; Recorre la receta y va desplegando dibujos en el buffer
	ld de,045e5h		;4190
	ld ix,0eac0h		;4193
EL_SEGUNDO_RECORRIDO:
	ld hl,04602h		;4197
	ld a,(de)			;419a
	and 003h		;419b   ; Los dos bits bajos de la receta dicen que clase de tramo es
	ld b,a			;419d
	ld c,a			;419e
	cp 002h		;419f   ; La clase 2 lleva una repeticion mas que las otras
	jr nz,SIN_REPETICIONES		;41a1
	inc c			;41a3
SIN_REPETICIONES:
	or a			;41a4
	jr z,DESPLIEGA_ESTE_TRAMO		;41a5
	ld a,00bh		;41a7   ; 0x0B y 0x07 de separacion entre uno y otro dentro del buffer
SEPARA_LAS_COPIAS:
	call HL_MAS_A		;41a9
	ld a,007h		;41ac
	djnz SEPARA_LAS_COPIAS		;41ae
DESPLIEGA_ESTE_TRAMO:
	ld a,(de)			;41b0
	rra			;41b1
	call DESPLIEGA_DESDE_AQUI		;41b2   ; 0x465C es DESPLIEGA por dentro, ya con el buffer y el dibujo puestos
	jr nz,EL_SEGUNDO_RECORRIDO		;41b5
	inc de			;41b7
	ld ix,0eec2h		;41b8   ; Y la receta se recorre OTRA VEZ, ahora sobre 0xEEC2 y con el flujo de 0x461F: el techo lleva su propio relieve, no es un espejo del suelo
EL_TERCER_RECORRIDO:
	ld hl,0461fh		;41bc
	ld a,(de)			;41bf
	and 003h		;41c0
	ld c,a			;41c2
	ld a,(de)			;41c3
	rra			;41c4
	scf			;41c5   ; El `scf` marca la diferencia entre los dos recorridos dentro de 0x465C
	call DESPLIEGA_DESDE_AQUI		;41c6
	jr nz,EL_TERCER_RECORRIDO		;41c9
	ret			;41cb
PINTA_SEIS_VECES:		; El mismo flujo de HL, seis veces, bajando 0x10 en la VRAM cada vez
	ld b,006h		;41cc
PINTA_UNA_DE_LAS_SEIS:
	push hl			;41ce
	push bc			;41cf
	call PINTA_ROTULO_EN_DE		;41d0
	pop bc			;41d3
	ld a,010h		;41d4   ; 0x10 en la VRAM es una fila de ocho pixeles en la tabla de color
	call DE_MAS_A		;41d6
	pop hl			;41d9
	djnz PINTA_UNA_DE_LAS_SEIS		;41da
	ret			;41dc

; ----------------------------------------------------------------------
; DATOS rutina_para_la_ram: Los siete bytes que 0x412B copia a 0xE5F8 para
;   poder hacer `ld (IX+A),B` automodificandose el desplazamiento. Son el
;   unico codigo del cartucho que no se ejecuta desde la ROM.
;   0x41dd..0x41e4  (7 bytes)
DATA_rutina_para_la_ram:
	defb 032h,0fdh,0e5h,0ddh,070h,000h,0c9h	; 41dd

; ----------------------------------------------------------------------
; DATOS fichas_de_la_nave: Las cuatro fichas de sprite con las que arranca la
;   nave, que 0x4D9C copia a 0xE7D0. Cada una son cuatro bytes -fila, columna,
;   dibujo y color-: (5, 0x10, 0x18, blanco), (5, 0x20, 0x20, blanco), (0x70,
;   0xDC, 0x28, blanco) y (0x70, 0xDC, 0x2C, rojo).
;   0x41e4..0x41f4  (16 bytes)
DATA_fichas_de_la_nave:
	defb 005h,010h,018h,00fh	; 41e4
	defb 005h,020h,020h,00fh	; 41e8
	defb 070h,0dch,028h,00fh	; 41ec
	defb 070h,0dch,02ch,00bh	; 41f0

; ----------------------------------------------------------------------
; DATOS textos_de_la_intro: Los tres carteles en ASCII, cada uno con su
;   direccion de VRAM delante y 0xFE entre tramo y tramo: INVADE THE BASE AND
;   / CARRY AWAY BOOTY (VRAM 0x3907 y 0x3948, lo pinta 0x4E05), INVASION
;   SUCCEEDED (0x421D, desde 0x5C63 y 0x5C7D) y ATTACK TO NEXT BASE.
;   0x41f4..0x4248  (84 bytes)
DATA_textos_de_la_intro:
	defb 007h,039h,049h,04eh,056h,041h,044h,045h,000h,054h,048h,045h,000h,042h,041h,053h	; 41f4  .9INVADE.THE.BAS
	defb 045h,000h,041h,04eh,044h,0feh,048h,039h,043h,041h,052h,052h,059h,000h,041h,057h	; 4204  E.AND.H9CARRY.AW
	defb 041h,059h,000h,042h,04fh,04fh,054h,059h,0ffh,0a8h,038h,049h,04eh,056h,041h,053h	; 4214  AY.BOOTY..8INVAS
	defb 049h,04fh,04eh,000h,053h,055h,043h,043h,045h,045h,044h,045h,044h,0feh,0e8h,038h	; 4224  ION.SUCCEEDED..8
	defb 041h,054h,054h,041h,043h,04bh,000h,054h,04fh,000h,04eh,045h,058h,054h,000h,042h	; 4234  ATTACK.TO.NEXT.B
	defb 041h,053h,045h,0ffh	; 4244

; ----------------------------------------------------------------------
; DATOS rotulo_del_titulo: El rotulo que 0x40BB pasa a PINTA_ROTULO al montar
;   la pantalla del titulo.
;   0x4248..0x42d1  (137 bytes)
DATA_rotulo_del_titulo:
	defb 000h,064h,008h,0ffh,002h,001h,002h,003h,002h,00fh,086h,01fh,07fh,01fh,01fh,03fh	; 4248  .d.............?
	defb 03fh,004h,0ffh,006h,000h,08eh,001h,007h,000h,080h,080h,0c0h,0f0h,0f0h,0f8h,0feh	; 4258  ?...............
	defb 0f0h,0f8h,0f8h,0fch,004h,0ffh,006h,000h,082h,080h,0e0h,006h,0ffh,003h,000h,0a7h	; 4268  ................
	defb 001h,003h,007h,00fh,01fh,03fh,0ffh,000h,000h,080h,0c0h,0fch,0feh,0ffh,0ffh,001h	; 4278  .....?..........
	defb 003h,00fh,01fh,03fh,07fh,0ffh,0ffh,000h,080h,0c0h,0e1h,0f3h,0ffh,0ffh,0ffh,000h	; 4288  ...?............
	defb 000h,080h,0c0h,0e0h,0fch,0feh,0ffh,080h,028h,060h,007h,000h,081h,001h,080h,090h	; 4298  ........(`......
	defb 064h,006h,000h,08ah,040h,060h,033h,01fh,00ah,01fh,07fh,065h,03ah,01fh,008h,000h	; 42a8  d...@`3....e:...
	defb 088h,0c0h,0e0h,0b0h,0f8h,0feh,056h,0ach,0f8h,080h,0c0h,064h,006h,000h,0a1h,004h	; 42b8  ......V....d....
	defb 006h,003h,001h,000h,001h,007h,006h,003h,001h	; 42c8  .........

; ----------------------------------------------------------------------
; DATOS tiles_del_juego: Dibujos de tile. De aqui 0x40D4 sube ocho bytes a la
;   VRAM 0x6030, y el resto entra por los mismos sitios que la fuente. Es
;   tambien donde cae el KONAMI pequeno de 0x43BE, los mismos 28 bytes que
;   Athletic Land 0x492E.
;   0x42d1..0x4427  (342 bytes)
DATA_tiles_del_juego:
	defb 0c0h,0e0h,060h,010h,008h,004h,000h,000h,03ch,0ffh,0abh,0ffh,0ffh,055h,0aah,0ffh	; 42d1  ..`.....<....U..
	defb 000h,000h,03fh,004h,00eh,04fh,07fh,003h,000h,085h,080h,0e0h,060h,0c0h,080h,080h	; 42e1  ..?..O......`...
	defb 010h,065h,0a0h,000h,000h,000h,003h,00fh,018h,039h,038h,039h,019h,00fh,00fh,019h	; 42f1  .e.......989....
	defb 01fh,010h,039h,000h,000h,000h,0e0h,0f8h,01ch,0feh,03eh,0feh,0fch,0f8h,0f8h,04ch	; 4301  ..9.......>....L
	defb 0fch,084h,0ceh,080h,040h,065h,005h,000h,09bh,001h,003h,003h,003h,001h,000h,000h	; 4311  ....@e..........
	defb 001h,001h,081h,0c3h,000h,000h,000h,03eh,0ffh,081h,09fh,083h,09fh,09fh,0ffh,0ffh	; 4321  .......>........
	defb 094h,0ffh,008h,09ch,004h,000h,08ch,080h,0c0h,0e0h,0e0h,0e0h,0c0h,080h,080h,0c0h	; 4331  ................
	defb 0c0h,041h,0e3h,080h,090h,065h,004h,000h,084h,020h,020h,070h,020h,004h,070h,002h	; 4341  .A...e...  p .p.
	defb 0f8h,082h,0d8h,088h,080h,0c0h,065h,004h,000h,002h,002h,082h,007h,002h,004h,007h	; 4351  ......e.........
	defb 002h,00fh,082h,00dh,008h,00ch,000h,004h,080h,080h,010h,066h,08eh,05ah,05ah,07eh	; 4361  ...........f.ZZ~
	defb 03ch,03ch,03ch,018h,018h,03ch,018h,03ch,03ch,018h,018h,003h,000h,006h,0ffh,002h	; 4371  <<<..<.<<.......
	defb 000h,006h,0c0h,002h,000h,006h,0f0h,002h,000h,006h,0fch,0a1h,000h,005h,005h,007h	; 4381  ................
	defb 003h,003h,003h,001h,001h,003h,001h,003h,003h,001h,001h,000h,000h,0a0h,0a0h,0e0h	; 4391  ................
	defb 0c0h,0c0h,0c0h,080h,080h,0c0h,080h,0c0h,0c0h,080h,080h,000h,000h,080h,0d0h,061h	; 43a1  ...............a
	defb 089h,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,000h,007h,003h,09ch,01ch,038h,070h	; 43b1  .<B....B<.....8p
	defb 0e1h,0cdh,0cdh,0fdh,079h,000h,000h,000h,0eeh,06bh,06bh,06bh,0ebh,000h,000h,000h	; 43c1  ....y....kkk....
	defb 073h,01ah,07ah,05ah,07ah,000h,003h,000h,0f3h,004h,05bh,080h,060h,061h,0a0h,000h	; 43d1  s.zZz.....[.`a..
	defb 040h,049h,05ah,073h,052h,059h,000h,000h,000h,092h,052h,0ceh,002h,0dch,000h,000h	; 43e1  @IZsRY....R.....
	defb 002h,000h,08ah,0aah,0aah,0dah,000h,000h,008h,048h,0eeh,04ah,04ah,06ah,000h,080h	; 43f1  .........H.JJj..
	defb 000h,062h,003h,000h,081h,07eh,004h,000h,080h,080h,060h,003h,000h,081h,07eh,004h	; 4401  .b...~....`...~.
	defb 000h,080h,000h,044h,040h,020h,080h,090h,045h,050h,080h,080h,010h,046h,050h,0a0h	; 4411  ...D@ ..EP...FP.
	defb 080h,080h,047h,040h,0f0h,000h	; 4421

; ----------------------------------------------------------------------
; DATOS dibujos_de_color_del_titulo: Dos flujos que 0x40E2 y 0x40EB despliegan
;   seis veces cada uno, separados 0x10, sobre la tabla de color de la VRAM
;   (0x0490 y 0x0510).
;   0x4427..0x443a  (19 bytes)
DATA_dibujos_de_color_del_titulo:
	defb 008h,0f0h,084h,050h,050h,0f0h,050h,004h,040h,000h,008h,0a0h,003h,0a0h,003h,050h	; 4427  ...PP.P.@......P
	defb 002h,040h,000h	; 4437

; ----------------------------------------------------------------------
; DATOS dibujos_de_sprite: El unico flujo del cartucho que escribe en la VRAM
;   0x1800, que es donde R6=0x03 pone la tabla de patrones de SPRITE: 144
;   bytes en 0x1800 y 328 en 0x18A8. Son los dibujos de la nave, de lo que
;   vuela y de las explosiones. Lo pasa 0x40FF a PINTA_ROTULO.
;   0x443a..0x4560  (294 bytes)
DATA_dibujos_de_sprite:
	defb 000h,058h,0a0h,008h,004h,004h,003h,083h,044h,02fh,01fh,015h,016h,03fh,025h,043h	; 443a  .X......D/...?%C
	defb 081h,001h,002h,001h,006h,008h,010h,0d8h,0f0h,070h,058h,0ech,0f6h,091h,0b0h,0d0h	; 444a  .........pX.....
	defb 018h,008h,004h,009h,000h,081h,018h,004h,03ch,082h,07eh,05ah,019h,000h,087h,003h	; 445a  ........<.~Z....
	defb 00fh,039h,0ffh,06eh,03bh,011h,009h,000h,08ah,0c0h,0f0h,09ch,0ffh,076h,0dch,088h	; 446a  .9.n;........v..
	defb 05ah,05ah,07eh,003h,03ch,088h,018h,018h,03ch,018h,03ch,03ch,018h,018h,016h,000h	; 447a  ZZ~.<...<.<<....
	defb 084h,020h,020h,070h,020h,004h,070h,084h,0f8h,0f8h,0d8h,0d8h,080h,0a8h,058h,084h	; 448a  .  p .p.......X.
	defb 000h,014h,008h,014h,00bh,000h,089h,001h,06fh,001h,0ffh,01eh,00eh,007h,001h,007h	; 449a  ........o.......
	defb 008h,000h,085h,008h,008h,03fh,008h,008h,00ah,000h,089h,001h,07fh,001h,0ffh,01eh	; 44aa  .....?..........
	defb 00eh,007h,001h,007h,008h,000h,088h,0fch,000h,0f0h,088h,08ch,0feh,010h,0feh,018h	; 44ba  ................
	defb 000h,088h,0ech,000h,0f0h,088h,08ch,0feh,010h,0feh,014h,000h,084h,0e0h,07eh,07eh	; 44ca  ..............~~
	defb 0e0h,01dh,000h,08bh,0ffh,0c0h,0a0h,091h,08ah,084h,08ah,091h,0a0h,0c0h,0ffh,005h	; 44da  ................
	defb 000h,083h,0e0h,060h,0a0h,005h,020h,083h,0a0h,060h,0e0h,006h,000h,00ah,0ffh,005h	; 44ea  ...`.. ..`......
	defb 000h,00bh,0e0h,0b0h,004h,002h,001h,000h,041h,033h,00eh,00bh,007h,027h,085h,00fh	; 44fa  ........A3...'..
	defb 012h,020h,020h,040h,000h,000h,018h,0feh,0ffh,077h,0edh,03eh,0d9h,0b7h,0fbh,0efh	; 450a  .  @.....w.>....
	defb 05eh,0e6h,024h,018h,004h,018h,020h,040h,081h,0c2h,0ech,0b0h,0e0h,064h,0a2h,0f0h	; 451a  ^.$... @.....d..
	defb 048h,004h,004h,002h,011h,000h,0afh,001h,020h,012h,009h,007h,001h,003h,002h,021h	; 452a  H....... ......!
	defb 013h,00dh,000h,008h,011h,020h,000h,000h,009h,086h,0bfh,0f3h,0efh,0ffh,0beh,0dah	; 453a  ..... ..........
	defb 03fh,062h,008h,028h,021h,010h,000h,040h,000h,008h,090h,024h,0f8h,0e0h,0c0h,070h	; 454a  ?b.(!..@...$...p
	defb 0e0h,080h,040h,020h,030h,008h	; 455a

; ----------------------------------------------------------------------
; DATOS dibujos_del_terreno: Los cuatro dibujos que MONTA_EL_MAPA despliega en
;   el buffer: 0x4560 (dos veces, en 0xE8B6 y 0xEAB6), 0x456A, 0x45AC y
;   0x45A2.
;   0x4560..0x45e5  (133 bytes)
DATA_dibujos_del_terreno:
	defb 000h,041h,031h,030h,030h,021h,020h,020h,011h,001h,000h,004h,014h,024h,030h,030h	; 4560  .A100!  .....$00
	defb 021h,020h,020h,024h,030h,030h,034h,044h,050h,050h,041h,031h,030h,030h,030h,030h	; 4570  !  $004DPPA10000
	defb 021h,011h,001h,000h,004h,014h,020h,020h,024h,030h,030h,030h,030h,021h,011h,001h	; 4580  !.....  $0000!..
	defb 000h,004h,014h,024h,030h,030h,030h,030h,021h,020h,020h,024h,030h,030h,034h,044h	; 4590  ...$0000!  $004D
	defb 050h,050h,0ffh,043h,03bh,032h,030h,023h,022h,020h,013h,00bh,002h,005h,00eh,01eh	; 45a0  PP.C;20#" ......
	defb 026h,030h,023h,022h,020h,025h,026h,030h,035h,03eh,046h,050h,043h,03bh,032h,030h	; 45b0  &0#" %&05>FPC;20
	defb 030h,030h,023h,01bh,00bh,002h,005h,00eh,016h,020h,025h,026h,030h,030h,030h,023h	; 45c0  00#...... %&000#
	defb 01bh,00bh,002h,005h,00eh,01eh,026h,030h,030h,030h,023h,022h,020h,025h,026h,030h	; 45d0  ......&000#" %&0
	defb 035h,03eh,046h,050h,0ffh	; 45e0

; ----------------------------------------------------------------------
; DATOS receta_del_terreno: Lo que 0x4190 va leyendo para saber que dibujo
;   poner y cuantas veces: dos bits dicen la clase y el resto, el sitio.
;   0x45e5..0x4602  (29 bytes)
DATA_receta_del_terreno:
	defb 009h,014h,035h,040h,04dh,05eh,06dh,075h,094h,0a1h,0a9h,0cdh,0d5h,0e0h,0edh,000h	; 45e5  ..5@M^mu........
	defb 00dh,025h,049h,051h,06ch,079h,081h,0a5h,0adh,0c5h,0e9h,0f4h,000h	; 45f5  .%IQly.......

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_receta: Los dos flujos que la receta despliega: 0x4602
;   sobre 0xEAC0 y 0x461F sobre 0xEEC2.
;   0x4602..0x4626  (36 bytes)
DATA_dibujos_de_la_receta:
	defb 098h,099h,000h,09bh,000h,09dh,092h,093h,000h,095h,0ffh,0b8h,0b9h,000h,0bbh,0b2h	; 4602  ................
	defb 0b3h,0ffh,0a8h,0a9h,0aah,0abh,0ach,0adh,0a2h,0a3h,0a4h,0a5h,0ffh,0c8h,0c9h,0cah	; 4612  ................
	defb 0cbh,0c2h,0c3h,0ffh	; 4622

; ======================================================================
; CODIGO 0x4626..0x46ad  (135 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; El desplegador: lee un dibujo comprimido y lo escribe en la RAM
; ----------------------------------------------------------------------
DESPLIEGA:		; Escribe en el buffer de HL el dibujo comprimido de DE
	ld a,005h		;4626   ; IX se queda apuntando cinco bytes mas alla del destino
	call HL_MAS_A		;4628
	push hl			;462b
	pop ix		;462c
	inc de			;462e
	ld a,(de)			;462f   ; 0xFF cierra el dibujo
	cp 0ffh		;4630
	ret z			;4632
	cp 050h		;4633   ; 0x50 es un salto de linea: se vuelve arriba sin escribir nada
	jr z,DESPLIEGA		;4635
	and 007h		;4637
	jr nz,DESPLIEGA_MEDIA_FICHA		;4639
	bit 2,h		;463b
	jr nz,DESPLIEGA_UN_BYTE		;463d
DESPLIEGA_MEDIA_FICHA:
	add a,080h		;463f
DESPLIEGA_UN_BYTE:
	ld b,a			;4641   ; El byte siguiente del dibujo, sin los tres bits bajos
	ld a,(de)			;4642
	and 0f8h		;4643
	rra			;4645   ; Cuatro `rra`: el nibble alto es el dibujo
	rra			;4646
	rra			;4647
	rra			;4648
ESCRIBE_CON_LA_RUTINA_DE_LA_RAM:
	call 0e5f8h		;4649   ; `ld (IX+A),B` por la rutina de la RAM (ver 0x41DD): el Z80 no lo tiene
	jr nc,SIGUIENTE_COLUMNA		;464c
	inc a			;464e
	dec b			;464f
	call 0e5f8h		;4650
SIGUIENTE_COLUMNA:
	ld b,c			;4653
	inc a			;4654
	cp 005h		;4655   ; Cinco por vuelta, que es el ancho de la ficha
	jr z,DESPLIEGA		;4657
	or a			;4659
	jr ESCRIBE_CON_LA_RUTINA_DE_LA_RAM		;465a
DESPLIEGA_DESDE_AQUI:
	push de			;465c
	ex de,hl			;465d
	ld l,003h		;465e
	jr nc,SACA_LA_CUENTA		;4660
	dec l			;4662
SACA_LA_CUENTA:
	rra			;4663   ; Los seis bits bajos son la cuenta
	and 03fh		;4664
	ld b,a			;4666
	ld a,c			;4667   ; C queda con la altura de la ficha
	ld c,l			;4668
	push ix		;4669
	pop hl			;466b
VUELVE_AL_DESTINO:
	call HL_MAS_A		;466c   ; IX vuelve al principio del destino
	ld a,005h		;466f
	djnz VUELVE_AL_DESTINO		;4671
DESPLIEGA_UNA_FILA:
	push hl			;4673
DESPLIEGA_UNA_FICHA:
	ld b,c			;4674
DESPLIEGA_UN_PAR:
	ld a,(de)			;4675   ; 0xFF tambien cierra este tramo
	cp 0ffh		;4676
	jr z,DESPLIEGA_TERMINA		;4678
	ld (hl),a			;467a
	inc de			;467b
	inc hl			;467c
	ld a,(de)			;467d
	ld (hl),a			;467e
	inc de			;467f
	ld a,004h		;4680
	call HL_MAS_A		;4682
	djnz DESPLIEGA_UN_PAR		;4685
	pop hl			;4687
	dec h			;4688   ; Dos veces `dec h`: el buffer sube de dos en dos paginas
	dec h			;4689
	jr DESPLIEGA_UNA_FICHA		;468a
DESPLIEGA_TERMINA:
	pop de			;468c
	inc de			;468d
	ld a,(de)			;468e
	or a			;468f
	ret			;4690

; ----------------------------------------------------------------------
; El paso del juego: un fotograma
; ----------------------------------------------------------------------
UN_PASO:		; Cuenta el fotograma, elige el lector de mandos y despacha por el estado
	ld hl,0e003h		;4691   ; 0xE003 cuenta fotogramas y ademas es el indice del submodo (0x516C)
	inc (hl)			;4694
	ld a,(0e002h)		;4695   ; El bit 6 de 0xE002 es que hay partida en curso
	and 040h		;4698
	ld hl,049eah		;469a   ; Jugando, 0x49EA: hacer parpadear el rotulo del jugador
	jr nz,DESPACHA_POR_EL_ESTADO		;469d
	ld hl,0488bh		;469f   ; Y fuera de partida, leer las teclas del menu (0x488B)
DESPACHA_POR_EL_ESTADO:
	ld a,(0e000h)		;46a2   ; 0xE000 es el estado del juego: la entrada de la tabla de 0x46AD
	cp 008h		;46a5
	jr z,LLAMA_AL_DESPACHADOR		;46a7   ; El estado 8 es el unico que se salta el `push`: su `ret` vuelve al llamador
	push hl			;46a9   ; Este `push` NO es para el despachador: 0x4050 saca su retorno con `pop` y termina en `jp (hl)`, asi que lo que queda encima de la pila es esta direccion y el `ret` de la rutina del estado aterriza en el lector de mandos
LLAMA_AL_DESPACHADOR:
	call DESPACHA		;46aa

; ----------------------------------------------------------------------
; DATOS tabla_de_estados: Las quince palabras del despachador de 0x4050,
;   pegadas detras del `call` de 0x46AA. El indice es (0xE000).
;   0x46ad..0x46cb  (30 bytes)
DATA_tabla_de_estados:
	defb 0cbh,046h	; 46ad
	defb 0d6h,046h	; 46af
	defb 0e9h,046h	; 46b1
	defb 0eeh,046h	; 46b3
	defb 0f0h,046h	; 46b5
	defb 0f9h,046h	; 46b7
	defb 000h,047h	; 46b9
	defb 024h,047h	; 46bb
	defb 0b0h,047h	; 46bd
	defb 008h,047h	; 46bf
	defb 02fh,047h	; 46c1
	defb 04ah,047h	; 46c3
	defb 054h,047h	; 46c5
	defb 078h,047h	; 46c7
	defb 08ch,047h	; 46c9

; ======================================================================
; CODIGO 0x46cb..0x4830  (357 bytes)
; ======================================================================


ESTADO_00_ARRANQUE:		; Sube los registros del VDP y deja la pantalla puesta
	call SUBE_LOS_REGISTROS_DEL_VDP		;46cb
	call BORRA_LA_PANTALLA		;46ce
	call PREPARA_LOGOTIPO		;46d1
	jr AVANZA_ESTADO		;46d4   ; Y al estado siguiente por 0x4745
ESTADO_01_LOGOTIPO:		; Sube el KONAMI grande una fila cada dos fotogramas
	ld a,(0e003h)		;46d6   ; El bit 0 de 0xE003 al carry: solo se mueve en los fotogramas pares
	rra			;46d9
	ret nc			;46da
	call SUBE_LOGOTIPO		;46db   ; Mientras SUBE_LOGOTIPO no diga que ha terminado, no se sigue
	ret nz			;46de
	ld hl,04ba6h		;46df   ; Y ya arriba, el rotulo VIDEO CARTRIDGE
	call PINTA_DIBUJO		;46e2
	ld a,020h		;46e5   ; 0x20 fotogramas de espera antes del estado siguiente
	jr PONE_ESPERA_Y_AVANZA		;46e7
ESTADO_02_ESPERA:		; Descuenta 0xE004 y no hace nada mas
	ld hl,0e004h		;46e9
	dec (hl)			;46ec
	ret nz			;46ed
ESTADO_03_PASA:		; Pasa de largo al estado siguiente
	jr AVANZA_ESTADO		;46ee
ESTADO_04_PANTALLA:		; Limpia y monta la pantalla del titulo
	call BORRA_LA_PANTALLA		;46f0
	call PINTA_DOS_FILAS		;46f3
	xor a			;46f6   ; Sin espera: A vale 0 y ese es el temporizador que pone 0x4742
	jr PONE_ESPERA_Y_AVANZA		;46f7
ESTADO_05_ESPERA:		; Otra espera por 0xE004
	ld hl,0e004h		;46f9
	dec (hl)			;46fc
	ret nz			;46fd
	jr AVANZA_ESTADO		;46fe
ESTADO_06_MENU:		; Monta el menu de PLAY SELECT
	call BORRA_LA_PANTALLA		;4700
	call MONTA_EL_MENU		;4703
	jr AVANZA_ESTADO		;4706
ESTADO_09_VIDA_NUEVA:		; Descuenta una vida y anuncia de quien es el turno
	call BORRA_LA_PANTALLA		;4708
	ld hl,0e050h		;470b
	dec (hl)			;470e   ; Una vida menos en el marcador del jugador activo
	call PINTA_EL_MARCADOR		;470f
	ld a,(0e002h)		;4712   ; El bit 5 de 0xE002 dice si hay dos jugadores; con uno solo no se anuncia
	and 020h		;4715
	jr z,ESPERA_DEL_ANUNCIO		;4717
	ld hl,04b9bh		;4719   ; El rotulo PLAYER 1, que 0x47ED convierte en PLAYER 2 si toca
	call PINTA_ROTULO_DEL_JUGADOR		;471c
	ld a,04fh		;471f   ; 0x50 fotogramas leyendo el rotulo (0x4F y el `inc a` de 0x4721)
ESPERA_DEL_ANUNCIO:
	inc a			;4721
	jr PONE_ESPERA_Y_AVANZA		;4722
ESTADO_07_ELIGE:		; Espera a que el jugador elija en el menu
	call PASO_DE_LA_INTRO		;4724
	ld a,(0e00bh)		;4727   ; Hasta que 0xE00B no deja de ser cero, aqui se sigue
	and a			;472a
	ret z			;472b
ELEGIDO_EL_MODO:
	xor a			;472c
	jr PONE_ESTADO_13		;472d   ; Elegido, salta a 0x47A2: estado 13 con 0x20 fotogramas por delante
ESTADO_10_EMPIEZA:		; Borra el anuncio y suelta al jugador
	ld hl,0e004h		;472f
	dec (hl)			;4732   ; Hasta que no se acaba la espera del anuncio, nada
	ret nz			;4733
	ld hl,04b9bh		;4734   ; BORRA_DIBUJO sobre el mismo rotulo que se pinto: lo quita
	call BORRA_DIBUJO		;4737
	call EMPIEZA_LA_FASE		;473a
	ld hl,0e06fh		;473d   ; 0xE06F distinto de cero mientras el jugador siga vivo
	ld (hl),001h		;4740
PONE_ESPERA_Y_AVANZA:		; Deja A en 0xE004 y pasa al estado siguiente
	ld (0e004h),a		;4742
AVANZA_ESTADO:		; Sube 0xE000: el siguiente fotograma va otra rutina
	ld hl,0e000h		;4745
	inc (hl)			;4748
	ret			;4749
ESTADO_11_JUGANDO:		; El juego. Aqui se esta hasta que 0xE06F se apaga
	call PASO_DE_PARTIDA		;474a   ; 0x50C2 es un paso de partida entero
	ld a,(0e06fh)		;474d   ; Mientras 0xE06F no sea cero se sigue jugando; a cero, se avanza
	or a			;4750
	ret nz			;4751
	jr AVANZA_ESTADO		;4752
ESTADO_12_MUERTO:		; Mira si al jugador activo le quedan vidas
	ld a,(0e050h)		;4754   ; Si el marcador no esta a cero, aun le quedan: por 0x476E
	or a			;4757
	jr nz,MIRA_AL_OTRO_JUGADOR		;4758
	call BORRA_LA_PANTALLA		;475a
	ld hl,04b8eh		;475d   ; El rotulo GAME OVER
	call PINTA_ROTULO_DEL_JUGADOR		;4760
	call PINTA_EL_MARCADOR		;4763
	ld a,00dh		;4766
	ld (0e000h),a		;4768
	xor a			;476b
	jr PONE_ESPERA_Y_AVANZA		;476c
MIRA_AL_OTRO_JUGADOR:
	ld a,(0e080h)		;476e
	or a			;4771
	jr nz,AVANZA_ESTADO		;4772
SIGUE_EL_OTRO:
	ld a,009h		;4774
	jr PONE_ESTADO_13		;4776
ESTADO_13_CAMBIA_TURNO:		; Cambia los dos marcadores de sitio y de mando
	ld hl,0e050h		;4778   ; Los 32 bytes de 0xE050 y los de 0xE080 se cambian entre si...
	ld de,0e080h		;477b
	ld b,020h		;477e
	call INTERCAMBIA		;4780
	ld hl,0e002h		;4783
	ld a,(hl)			;4786
	xor 080h		;4787   ; ...y el bit 7 de 0xE002 tambien, que es el joystick que lee 0x4838
	ld (hl),a			;4789
	jr SIGUE_EL_OTRO		;478a
ESTADO_14_FIN:		; Fin de partida, salvo que el otro jugador siga vivo
	ld hl,0e004h		;478c
	dec (hl)			;478f
	ret nz			;4790
	ld a,(0e080h)		;4791   ; Si al otro le quedan vidas, se le devuelve el turno
	or a			;4794
	jr nz,VUELVE_AL_TURNO		;4795
	ld hl,0e002h		;4797
	ld a,(hl)			;479a
	and 0bfh		;479b   ; Se apaga el bit 6 de 0xE002 antes de volver al principio
	ld (hl),a			;479d
	jr ELEGIDO_EL_MODO		;479e
VUELVE_AL_TURNO:		; Estado 13 con 0x20 fotogramas de margen
	ld a,00dh		;47a0
PONE_ESTADO_13:
	ld (0e000h),a		;47a2
	ld a,020h		;47a5
	ld (0e004h),a		;47a7
	ret			;47aa
ARRANCA_LA_PARTIDA:
	call EMPIEZA_PARTIDA		;47ab
	jr AVANZA_ESTADO		;47ae
ESTADO_08_DEMO:		; El unico al que se entra sin `push`: su `ret` vuelve al llamador
	ld a,(0e001h)		;47b0
	or a			;47b3
	jr nz,CUENTA_Y_PARPADEA		;47b4
	call BORRA_LA_PANTALLA		;47b6
	call PINTA_DOS_FILAS		;47b9
	ld a,050h		;47bc
	ld (0e004h),a		;47be
	ld a,089h		;47c1   ; Un sonido antes de arrancar la demostracion
	call SUENA_ESTO		;47c3
	ld hl,0e001h		;47c6   ; 0xE001 lleva la cuenta de por donde va la demostracion
	inc (hl)			;47c9
	ret			;47ca
CUENTA_Y_PARPADEA:		; Descuenta 0xE004 y hace parpadear la linea elegida del menu
	ld hl,0e004h		;47cb
	dec (hl)			;47ce
	jr z,ARRANCA_LA_PARTIDA		;47cf
	ld a,(hl)			;47d1
	and 008h		;47d2   ; El bit 3 del temporizador: ocho fotogramas encendido y ocho apagado
	jp nz,PINTA_DOS_FILAS		;47d4
	ld a,(0e002h)		;47d7
	bit 4,a		;47da
	jr nz,LA_FILA_DEL_MENU		;47dc
	add a,040h		;47de   ; Sin el bit 4 de 0xE002 se suma 0x40: la otra pareja de lineas del menu
LA_FILA_DEL_MENU:
	and 060h		;47e0
	add a,a			;47e2
	ld e,a			;47e3
	ld d,03ah		;47e4   ; VRAM 0x3A00 y pico: la fila del menu, 32 bytes que se borran
	ld bc,00020h		;47e6
	xor a			;47e9
	jp LLENA_VRAM		;47ea
PINTA_ROTULO_DEL_JUGADOR:		; Pinta el dibujo de HL y, si juega el segundo, le cambia el 1 por el 2
	call PINTA_DIBUJO		;47ed
	ld a,(0e002h)		;47f0
	or a			;47f3
	ret p			;47f4   ; Con el bit 7 de 0xE002 apagado juega el primero y no hay nada que cambiar
	ld a,032h		;47f5   ; 0x32 es el '2' en ASCII, encima del '1' que acaba de pintar
	dec de			;47f7
	call VPOKE		;47f8
	ret			;47fb
ARRANCA_EL_SONIDO:		; Deja el PSG con su mezcla y borra la VRAM entera
	ld a,007h		;47fc   ; Registro 7 del PSG a 0xB8: los tres tonos abiertos y el ruido cerrado
	out (0a0h),a		;47fe
	ld a,0b8h		;4800
	out (0a1h),a		;4802
	ld a,0d0h		;4804   ; 0xD0 es el sonido del arranque
	call SUENA_ESTO		;4806
	ld de,00000h		;4809   ; 0x4000 bytes a cero: la VRAM entera, de golpe
	ld bc,04000h		;480c
	xor a			;480f
	call LLENA_VRAM		;4810
SUBE_LOS_REGISTROS_DEL_VDP:
	di			;4813   ; Los ocho registros del VDP a 0xE038 antes de subirlos
	ld hl,04830h		;4814
	ld de,0e038h		;4817
	ld bc,00008h		;481a   ; Ocho bytes, que son los ocho registros
	ldir		;481d
	ld hl,0e038h		;481f
	ld b,008h		;4822
	ld d,080h		;4824   ; D empieza en 0x80: el numero de registro con el bit 7 puesto
SUBE_UN_REGISTRO:
	ld e,(hl)			;4826   ; Los ocho registros, uno detras de otro
	call VDP_DIRECCION		;4827
	inc hl			;482a
	inc d			;482b   ; El numero de registro sube con cada vuelta
	djnz SUBE_UN_REGISTRO		;482c
	ei			;482e
	ret			;482f

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros del VDP. 0x4813 los copia a
;   0xE038 y los escribe uno a uno con `call 0x401A` subiendo D de 0x80 a
;   0x87: R0=0x02, R1=0xE2, R2=0x0E, R3=0x7F, R4=0x07, R5=0x76, R6=0x03,
;   R7=0xE1. Es SCREEN 2 con sprites de 16x16.
;   0x4830..0x4838  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 4830  .....v..

; ======================================================================
; CODIGO 0x4838..0x48ac  (116 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Los mandos: joystick por el PSG o teclado por el PPI, segun 0xE002
; ----------------------------------------------------------------------
PUERTO_DEL_JOYSTICK:		; Registro 15 del PSG: joystick 1 o joystick 2 segun el bit 7 de 0xE002
	di			;4838
	ld a,00fh		;4839
	out (0a0h),a		;483b
	ld a,08fh		;483d   ; 0x8F elige el joystick 1; con el bit 6 puesto (0xCF), el 2
	ld hl,0e002h		;483f
	bit 7,(hl)		;4842
	jr z,MANDA_EL_REGISTRO_15		;4844
	set 6,a		;4846
MANDA_EL_REGISTRO_15:
	out (0a1h),a		;4848
	ei			;484a
LEE_MANDOS:		; 0xE009 = lo pulsado ahora, 0xE008 = lo del fotograma anterior
	ld a,(0e002h)		;484b
	bit 4,a		;484e   ; El bit 4 de 0xE002 elige teclado (0x4863) en vez de joystick
	jr nz,LEE_TECLADO		;4850
	ld a,00eh		;4852   ; Registro 14 del PSG: el joystick que haya dejado elegido 0x4838
	out (0a0h),a		;4854
	in a,(0a2h)		;4856
	cpl			;4858
	and 03fh		;4859   ; Seis bits: cuatro direcciones y dos botones
GUARDA_LO_PULSADO:
	ld hl,0e009h		;485b   ; 0xE009 es lo pulsado ahora; 0xE008, lo del fotograma anterior
	ld c,(hl)			;485e   ; Lo que habia en 0xE009 se aparta antes de pisarlo...
	ld (hl),a			;485f
	dec hl			;4860
	ld (hl),c			;4861   ; ...y baja a 0xE008; asi se puede ver el flanco del boton y no si esta pulsado
	ret			;4862
LEE_TECLADO:		; Arma con las filas 7 y 8 del teclado el mismo byte que da el joystick
	ld bc,057aah		;4863   ; B = 0x57 y C = 0xAA: escribe la fila 7 en el puerto del PPI
	out (c),b		;4866   ; Con `out (c),b` porque el numero de fila esta en B
	in a,(0a9h)		;4868   ; Y la fila se lee del 0xA9
	cpl			;486a   ; Las teclas pulsadas vienen a cero: el `cpl` las pone a uno
	rrca			;486b
	and 020h		;486c   ; SELECT (bit 6 de la fila 7) al bit 5: el segundo boton
	ld e,a			;486e
	inc b			;486f   ; Y ahora la fila 8: espacio y las cuatro flechas
	out (c),b		;4870   ; Otra vez el mismo par de puertos
	in a,(0a9h)		;4872
	cpl			;4874
	rrca			;4875   ; Dos `rrca` colocan las flechas donde las pone el joystick
	rrca			;4876
	ld b,a			;4877
	and 004h		;4878   ; IZQUIERDA al bit 2
	or e			;487a
	ld c,a			;487b
	ld a,b			;487c   ; Se guarda lo que se lleva armado
	rrca			;487d
	rrca			;487e
	ld b,a			;487f
	and 018h		;4880   ; DERECHA al bit 3 y ESPACIO al bit 4
	or c			;4882
	ld c,a			;4883
	ld a,b			;4884   ; Y lo que queda por colocar
	rrca			;4885
	and 003h		;4886   ; ARRIBA al bit 0 y ABAJO al bit 1
	or c			;4888
	jr GUARDA_LO_PULSADO		;4889   ; Y a guardar en 0xE009/0xE008 por el mismo sitio que el joystick

; ----------------------------------------------------------------------
; La fila 0 del teclado, para las teclas que no son de jugar
; ----------------------------------------------------------------------
LEE_TECLAS_DE_MENU:		; Devuelve en A la tecla de la fila 0, ya convertida por la tabla de 0x48AC
	ld a,050h		;488b   ; Fila 0 del teclado: 0 a 7
	out (0aah),a		;488d
	in a,(0a9h)		;488f
	cpl			;4891
	and 01eh		;4892   ; Solo los bits 1 a 4, y se bajan uno: quedan las teclas 1, 2, 3 y 4
	rra			;4894
	dec a			;4895
	cp 008h		;4896   ; De 8 en adelante, nada que hacer
	ret nc			;4898
	ld hl,048ach		;4899   ; Y el numero se traduce por la tabla de 0x48AC
	call HL_MAS_A		;489c
	ld a,(hl)			;489f
	or a			;48a0
	ret z			;48a1
	ld (0e002h),a		;48a2
	ld hl,00008h		;48a5
	ld (0e000h),hl		;48a8
	ret			;48ab

; ----------------------------------------------------------------------
; DATOS tabla_de_teclas_de_menu: Las ocho teclas de la fila 0 del teclado,
;   traducidas: 0x4899 entra aqui con la tecla ya reducida a 0-7 y saca de
;   esta tabla lo que devuelve.
;   0x48ac..0x48b4  (8 bytes)
DATA_tabla_de_teclas_de_menu:
	defb 040h,060h,000h,050h,000h,000h,000h,070h	; 48ac  @`.P...p

; ======================================================================
; CODIGO 0x48b4..0x490d  (89 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Montar la pantalla del titulo
; ----------------------------------------------------------------------
MONTA_EL_TITULO:		; Sube la fuente, el logotipo grande y el rotulo de abajo
	ld de,04008h		;48b4
	ld a,070h		;48b7
	call SUBE_FUENTE_COLOR		;48b9
	call PINTA_LOGOTIPO		;48bc
	call SUBE_FUENTE		;48bf
	call MONTA_PANTALLA_TITULO		;48c2
	ld hl,04bbch		;48c5   ; VIDEO CARTRIDGE, el rotulo del pie
	call PINTA_ROTULO		;48c8
	ld de,04038h		;48cb   ; Ocho tandas de 0x1F8 bytes con el mismo 0x60 en la VRAM 0x4038: pinta de un color de golpe toda la tabla de color
	ld bc,001f8h		;48ce
	ld a,060h		;48d1
PINTA_UN_BYTE_DE_COLOR:
	call VPOKE		;48d3   ; Un byte por vuelta, 0x1F8 por tanda
	inc de			;48d6
	dec c			;48d7
	jr nz,PINTA_UN_BYTE_DE_COLOR		;48d8
	djnz PINTA_UN_BYTE_DE_COLOR		;48da   ; Ocho tandas: la tabla de color entera
	ret			;48dc

; ----------------------------------------------------------------------
; Empezar una partida: borrar la RAM del juego y repartir vidas
; ----------------------------------------------------------------------
EMPIEZA_PARTIDA:		; Borra de 0xE043 a 0xE7FF y deja a cada jugador con sus tres vidas
	ld hl,0e043h		;48dd   ; De 0xE043 en adelante: los marcadores y todo lo que hay debajo
	ld bc,007bch		;48e0   ; 0x7BC bytes, o sea hasta 0xE7FF; el record (0xE040) NO se borra
	ld d,h			;48e3
	ld e,l			;48e4
	inc e			;48e5
	ld (hl),000h		;48e6
	ldir		;48e8
	ld hl,0490dh		;48ea   ; Los dos bytes de 0x490D, `03 01`, al marcador del jugador activo: tres vidas
	ld de,0e050h		;48ed
	ld bc,00002h		;48f0
	ldir		;48f3
	call MONTA_EL_MAPA		;48f5
	call REPARTE_LOS_MARCADORES		;48f8
	ld a,(0e002h)		;48fb   ; El bit 5 de 0xE002 es que juegan dos...
	and 020h		;48fe
	ret z			;4900
	ld hl,0e050h		;4901   ; ...y entonces los 32 bytes del jugador se copian tal cual al segundo
	ld de,0e080h		;4904
	ld bc,00020h		;4907
	ldir		;490a
	ret			;490c

; ----------------------------------------------------------------------
; DATOS vidas_al_empezar: Los dos bytes con los que arranca cada jugador, `03
;   01`, que 0x48EA copia a 0xE050: tres vidas y el 1 de la primera zona.
;   0x490d..0x490f  (2 bytes)
DATA_vidas_al_empezar:
	defb 003h,001h	; 490d

; ======================================================================
; CODIGO 0x490f..0x4ae8  (473 bytes)
; ======================================================================


MONTA_EL_MENU:
	xor a			;490f
	ld (0e00bh),a		;4910
	call PINTA_EL_MARCADOR		;4913
	jp EMPIEZA_LA_INTRO		;4916
APAGA_LOS_SPRITES:		; Un 0xD0 en la primera ficha: el VDP deja de pintar de ahi para abajo
	ld de,03b00h		;4919
	ld a,0d0h		;491c
	jp VPOKE		;491e

; ----------------------------------------------------------------------
; Sumar puntos, dar vidas extra y llevar el record
; ----------------------------------------------------------------------
SUMA_PUNTOS:		; Suma DE al marcador del jugador, en BCD
	ld a,(0e002h)		;4921   ; El bit 6 de 0xE002, subido al 7 por el `add a,a`: sin el no se puntua, que es lo que pasa mientras corre la demostracion
	add a,a			;4924
	ret p			;4925
	ld hl,0e046h		;4926   ; El acarreo del `add a,a` trae el bit 7: 0xE043 el primer jugador, 0xE046 el segundo
	jr nc,SUMA_EL_BYTE_BAJO		;4929
	ld l,043h		;492b
SUMA_EL_BYTE_BAJO:
	ld a,(hl)			;492d
	add a,e			;492e   ; Byte bajo, y `daa` porque el marcador es BCD
	daa			;492f
	ld (hl),a			;4930
	ld e,a			;4931
	inc l			;4932
	ld a,(hl)			;4933
	adc a,d			;4934   ; Byte de en medio, con el acarreo
	daa			;4935
	ld (hl),a			;4936
	ld d,a			;4937
	inc hl			;4938
	jr nc,MIRA_EL_RECORD		;4939
	ld a,(hl)			;493b   ; Byte alto, que solo recibe el acarreo
	add a,001h		;493c
	daa			;493e
	ld (hl),a			;493f
	jr nc,MIRA_VIDA_EXTRA		;4940   ; Sin acarreo aqui no hay desbordamiento y se sigue por 0x494F
	ld bc,09999h		;4942   ; Pasado el 999999, lo que se planta en el maximo es EL RECORD
	ld (0e040h),bc		;4945   ; (0xE040-0xE042); los puntos del jugador dan la vuelta y siguen
	ld (0e041h),bc		;4949
	jr PINTA_EL_RECORD		;494d
MIRA_VIDA_EXTRA:		; 0xE052 es el proximo escalon: al alcanzarlo, una vida mas
	ld a,(0e052h)		;494f   ; Se compara el byte ALTO del marcador, asi que el escalon son decenas de millar
	cp (hl)			;4952
	jr nc,MIRA_EL_RECORD		;4953
	push de			;4955
	push hl			;4956
	add a,002h		;4957   ; El siguiente escalon, 2 mas en BCD: la vida extra cae cada 20.000 puntos
	daa			;4959
	jr nc,GUARDA_EL_ESCALON		;495a
	ld a,0ffh		;495c   ; Y al pasarse, 0xFF: ya no hay mas vidas extra en esa partida
GUARDA_EL_ESCALON:
	ld (0e052h),a		;495e
	ld hl,0e050h		;4961   ; La vida
	inc (hl)			;4964
	call PINTA_LAS_VIDAS		;4965
	ld a,005h		;4968   ; Y el sonido de haberla ganado
	call SUENA_ESTO		;496a
	pop hl			;496d
	pop de			;496e
MIRA_EL_RECORD:		; Si el marcador ha pasado al record, lo sustituye
	ld a,(0e042h)		;496f   ; Primero el byte alto de los dos
	ld b,(hl)			;4972
	sub b			;4973
	jr c,EL_RECORD_ES_ESTE		;4974
	jr nz,PINTA_LOS_DEL_JUGADOR		;4976   ; Si es distinto y no hay acarreo, el jugador va por delante y ya esta
	ld hl,(0e040h)		;4978   ; Iguales por arriba, hay que mirar los dos bytes de abajo
	sbc hl,de		;497b
	jr nc,PINTA_LOS_DEL_JUGADOR		;497d
EL_RECORD_ES_ESTE:
	ld (0e040h),de		;497f   ; Y el record pasa a ser el marcador de este jugador
	ld a,b			;4983
	ld (0e042h),a		;4984
	jr PINTA_EL_RECORD		;4987
PINTA_EL_MARCADOR:		; Sube a la pantalla los rotulos HI, ZONE, 1P y 2P
	ld hl,04ae8h		;4989
	call PINTA_DIBUJO		;498c
PINTA_MARCADOR_ENTERO:		; Los rotulos, los dos marcadores, el record, la zona y las vidas
	ld a,(0e002h)		;498f
	bit 5,a		;4992   ; El bit 5 de 0xE002: con un solo jugador no se pinta el marcador del otro
	jr z,PINTA_VIDAS_Y_ZONA		;4994
	ld hl,04afch		;4996
	call PINTA_DIBUJO		;4999
	ld a,(0e002h)		;499c
	xor 080h		;499f   ; Se le da la vuelta al bit del jugador para pintar el del contrario
	call PINTA_PUNTOS		;49a1
PINTA_VIDAS_Y_ZONA:
	call PINTA_LAS_VIDAS		;49a4
	call PINTA_LA_ZONA_EN_CURSO		;49a7
PINTA_EL_RECORD:
	ld hl,0e042h		;49aa   ; El record, 0xE040-0xE042, en la VRAM 0x3AD8
	ld de,03ad8h		;49ad
	call PINTA_BCD		;49b0
PINTA_LOS_DEL_JUGADOR:
	ld a,(0e002h)		;49b3
PINTA_PUNTOS:		; El marcador del jugador que diga el bit 7 de A
	ld de,03ac4h		;49b6
	ld hl,0e048h		;49b9
	add a,a			;49bc   ; El acarreo saca el bit 7: el primero en 0x3AC4, el segundo en 0x3ACE
	jr nc,PINTA_BCD		;49bd
	ld e,0ceh		;49bf
	ld hl,0e045h		;49c1
PINTA_BCD:		; Pinta B bytes BCD de HL hacia atras, en la VRAM DE
	ld b,003h		;49c4
	jr PINTA_UN_BYTE_BCD		;49c6
PINTA_LA_ZONA_EN_CURSO:
	ld de,03af0h		;49c8   ; La zona en curso, un solo byte, en la VRAM 0x3AF0
	ld hl,0e051h		;49cb
	ld b,001h		;49ce
PINTA_UN_BYTE_BCD:
	ld a,(hl)			;49d0
	and 00fh		;49d1   ; El nibble bajo se aparta en C...
	ld c,a			;49d3
	xor (hl)			;49d4   ; ...y el `xor` con el byte entero deja el alto, que cuatro `rra` bajan
	rra			;49d5
	rra			;49d6
	rra			;49d7
	rra			;49d8
	or 030h		;49d9   ; `or 0x30` convierte la cifra en su tile: los digitos empiezan en el 0x30
	call VPOKE		;49db
	inc de			;49de
	ld a,c			;49df
	or 030h		;49e0
	call VPOKE		;49e2
	dec hl			;49e5   ; Se avanza en la VRAM y se retrocede en la RAM: el BCD va al reves
	inc de			;49e6
	djnz PINTA_UN_BYTE_BCD		;49e7
	ret			;49e9
PARPADEA_EL_JUGADOR:		; Enciende y apaga el rotulo 1P/2P mientras se juega
	ld hl,(0e002h)		;49ea   ; L es 0xE002, las banderas, y H es 0xE003, el contador de fotogramas
	ld a,01fh		;49ed   ; Los cinco bits bajos a cero: esto solo pasa una vez cada 32 fotogramas
	and h			;49ef
	ret nz			;49f0
	ld c,a			;49f1
	bit 5,h		;49f2   ; Y el bit 5 del contador decide: C queda a 0 o a 0xFF...
	jr z,ELIGE_EL_ROTULO		;49f4
	dec c			;49f6
ELIGE_EL_ROTULO:
	bit 7,l		;49f7   ; El bit 7 de las banderas dice cual de los dos rotulos, 1P o 2P
	ld hl,04af6h		;49f9
	jr z,PINTA_O_BORRA		;49fc
	ld hl,04afch		;49fe
PINTA_O_BORRA:
	jp PINTA_TRAMO		;4a01   ; ...y se entra en el pintor por 0x406A, saltandose las dos puertas: con C a 0xFF pinta y con C a 0 borra. El parpadeo es la misma rutina
PINTA_LAS_VIDAS:		; Cinco huecos en la VRAM, de derecha a izquierda
	ld de,03ae7h		;4a04
	ld a,(0e050h)		;4a07   ; Las vidas que le quedan al jugador activo
	ld c,a			;4a0a
	ld b,005h		;4a0b
	ld a,09ch		;4a0d   ; 0x9C es el tile de la navecita del marcador
NAVE_O_HUECO:
	dec c			;4a0f   ; Gastadas las vidas, el resto de los huecos se pintan con el tile 0
	jp p,PINTA_UNA_VIDA		;4a10
	xor a			;4a13
PINTA_UNA_VIDA:
	call VPOKE		;4a14
	dec de			;4a17
	djnz NAVE_O_HUECO		;4a18
	ret			;4a1a
PINTA_DOS_FILAS:		; Dos filas de tiles seguidos, 0x0F cada una
	ld a,007h		;4a1b
	ld de,038a9h		;4a1d   ; VRAM 0x38A9, y la segunda en 0x38C9: una fila mas abajo
	ld c,002h		;4a20
LA_SEGUNDA_FILA:
	ld b,00fh		;4a22
PINTA_UN_TILE_DE_LA_FILA:
	call VPOKE		;4a24   ; Un tile por casilla, y el codigo sube con la columna
	inc de			;4a27
	inc a			;4a28
	djnz PINTA_UN_TILE_DE_LA_FILA		;4a29
	dec c			;4a2b   ; Hecha la primera fila, la segunda
	ld de,038c9h		;4a2c
	jr nz,LA_SEGUNDA_FILA		;4a2f
	ld de,038ech		;4a31   ; Y un tile suelto en la VRAM 0x38EC
	call VPOKE		;4a34
	ld hl,04b02h		;4a37
	jp PINTA_DIBUJO		;4a3a

; ----------------------------------------------------------------------
; Las rutinas de fondo del VDP
; ----------------------------------------------------------------------
VDP_ESCRITURA:		; Como VDP_DIRECCION, pero poniendo el bit 6: para escribir
	ex af,af'			;4a3d   ; A se guarda en A' para no pisarlo: la direccion se manda con DE
	set 6,d		;4a3e
	call VDP_DIRECCION		;4a40
	res 6,d		;4a43
	ex af,af'			;4a45
	ret			;4a46
BORRA_LA_PANTALLA:		; Apaga los sprites y deja a cero la tabla de nombres
	call APAGA_LOS_SPRITES		;4a47
	ld bc,00300h		;4a4a   ; 0x300 bytes desde la VRAM 0x7800: las 24 filas de los tres tercios
BORRA_LA_TABLA_DE_NOMBRES:
	ld de,07800h		;4a4d
	xor a			;4a50
LLENA_VRAM:		; BC bytes con el valor A, desde la VRAM DE
	di			;4a51
	call VDP_ESCRITURA		;4a52
MARGEN_DEL_VDP:
	ex af,af'			;4a55   ; Dos `ex af,af'` seguidos no cambian nada: son el margen que el VDP necesita entre escritura y escritura, gastado sin tocar registros
LLENA_UN_BYTE_DE_VRAM:
	ex af,af'			;4a56   ; El segundo `ex af,af'` deja A como estaba: solo se gasta tiempo
	out (098h),a		;4a57
	ex af,af'			;4a59
	dec bc			;4a5a   ; BC lleva la cuenta de lo que falta
	ld a,b			;4a5b
	or c			;4a5c
	jr nz,LLENA_UN_BYTE_DE_VRAM		;4a5d
	ei			;4a5f
	ret			;4a60
VUELCA_VRAM:		; Lo mismo, pero tomando cada byte de HL
	ld a,(hl)			;4a61
	inc hl			;4a62
	jr MARGEN_DEL_VDP		;4a63
VUELCA_UN_BYTE:
	di			;4a65
	call VDP_ESCRITURA		;4a66
VUELCA_ESTE_BYTE:
	ld a,(hl)			;4a69
	out (098h),a		;4a6a
	inc hl			;4a6c
CIERRA_EL_BUCLE_DE_VRAM:		; El final compartido de LLENA_VRAM y VUELCA_VRAM: descuenta BC y devuelve las interrupciones
	dec bc			;4a6d   ; Se descuenta y se sigue mientras quede
	ld a,b			;4a6e
	or c			;4a6f
	jr nz,VUELCA_ESTE_BYTE		;4a70
	ei			;4a72   ; Las interrupciones vuelven aqui, no antes
	ret			;4a73

; ----------------------------------------------------------------------
; Copiar de VRAM a VRAM, byte a byte
; ----------------------------------------------------------------------
COPIA_VRAM_A_VRAM:		; BC bytes de la VRAM DE a la VRAM HL
	call VPEEK		;4a74   ; Un byte de la VRAM DE...
	ex de,hl			;4a77
	call VPOKE		;4a78   ; ...a la VRAM HL; VPEEK y VPOKE mandan la direccion cada vez
	ex de,hl			;4a7b
	inc hl			;4a7c
	inc de			;4a7d
	dec bc			;4a7e
	ld a,c			;4a7f
	or b			;4a80
	jr nz,COPIA_VRAM_A_VRAM		;4a81
	ret			;4a83
REPITE_LOS_PATRONES:		; Copia el tercio de arriba de la tabla de patrones en los otros dos
	ld de,02000h		;4a84   ; De la VRAM 0x2000 a la 0x2800, y luego de la 0x2800 a la 0x3000
	ld hl,02800h		;4a87
EL_TERCER_TERCIO:
	ld bc,00800h		;4a8a
	call COPIA_VRAM_A_VRAM		;4a8d
	ld bc,00800h		;4a90
	jr COPIA_VRAM_A_VRAM		;4a93
REPITE_TERCIOS:		; Los patrones y, detras, la tabla de color
	call REPITE_LOS_PATRONES		;4a95
	ld de,00000h		;4a98   ; Y lo mismo con el color, que empieza en la VRAM 0x0000
	ld hl,00800h		;4a9b
	jr EL_TERCER_TERCIO		;4a9e

; ----------------------------------------------------------------------
; La fuente de las letras no esta en el cartucho: se copia de la BIOS
; ----------------------------------------------------------------------
SUBE_FUENTE:		; Sube 0x180 bytes de la fuente del MSX y les da color
	ld a,0f0h		;4aa0
	ld de,00180h		;4aa2
	ld c,080h		;4aa5
	jr LLENA_EL_COLOR_Y_SUBE		;4aa7
SUBE_FUENTE_COLOR:		; Igual, pero con el color y el desplazamiento ya puestos por el llamador
	ld c,088h		;4aa9
LLENA_EL_COLOR_Y_SUBE:
	push bc			;4aab
	ld bc,00180h		;4aac   ; Primero el color: 0x180 bytes seguidos desde la VRAM DE
	call LLENA_VRAM		;4aaf
	pop bc			;4ab2
	ld hl,(00004h)		;4ab3   ; La direccion 0x0004 de la ROM del BASIC es CGTBL, el puntero a la fuente del MSX. Las letras y las cifras de este juego son las de la maquina, no dibujos del cartucho
	ld b,001h		;4ab6   ; BC queda en 0x0180 o 0x0188: 0x180/8 = 48, o sea el caracter '0'
	add hl,bc			;4ab8
	ld a,020h		;4ab9   ; Y a D se le suman 0x20: DE pasa de la tabla de color a la de patrones
	add a,d			;4abb
	ld d,a			;4abc
	ld bc,00180h		;4abd   ; 0x180 bytes son 48 caracteres: del '0' al '_', cifras y mayusculas
	call VUELCA_UN_BYTE		;4ac0
	jp REPITE_TERCIOS		;4ac3

; ----------------------------------------------------------------------
; El interprete de los rotulos de 0x4AE8 y 0x5036
; ----------------------------------------------------------------------
PINTA_ROTULO:		; Lee la direccion de VRAM y va soltando tramos hasta el 0x00
	ld e,(hl)			;4ac6   ; Los dos primeros bytes de cada tramo son la direccion de la VRAM
	inc hl			;4ac7
	ld d,(hl)			;4ac8
	inc hl			;4ac9
PINTA_ROTULO_EN_DE:
	di			;4aca
	call VDP_ESCRITURA		;4acb
LEE_EL_BYTE_DE_MANDO:
	ld a,(hl)			;4ace   ; Del byte de mando se aparta lo que vale sin el bit 7, que es la cuenta
	and 07fh		;4acf
	ld c,a			;4ad1
	ld a,(hl)			;4ad2
	inc hl			;4ad3
	jr nz,PINTA_TRAMO_ROTULO		;4ad4   ; Cuenta distinta de cero: hay tramo que pintar, por 0x4ADB
	cp c			;4ad6   ; Y con la cuenta a cero, 0x00 cierra el rotulo y 0x80 abre otro tramo en otra direccion de la VRAM
	jr nz,PINTA_ROTULO		;4ad7
	ei			;4ad9
	ret			;4ada
PINTA_TRAMO_ROTULO:		; Con el bit 7, C bytes seguidos de la lista; sin el, C veces el mismo
	ld b,000h		;4adb
	cp c			;4add
	push af			;4ade
	call nz,VUELCA_ESTE_BYTE		;4adf   ; Con el bit 7 puesto se vuelcan C bytes DISTINTOS: 0x4A69 lee uno por vuelta...
	pop af			;4ae2
	call z,VUELCA_VRAM		;4ae3   ; ...y sin el se repite UNO C veces: 0x4A61 lee el byte una sola vez y 0x4A56 lo suelta en bucle
	jr LEE_EL_BYTE_DE_MANDO		;4ae6

; ----------------------------------------------------------------------
; DATOS rotulos_de_pantalla: Los rotulos con su direccion de VRAM delante: HI,
;   ZONE, 1P, 2P (0x4AE8), PLAY SELECT (0x4B04), las cuatro lineas del menu en
;   numeros de tile (0x4B10-0x4B7F), el logotipo pequeno con el ano en VRAM
;   0x390B (0x4B80), GAME OVER (0x4B90), PLAYER 1 (0x4B9D) y VIDEO CARTRIDGE
;   (0x4BAA). Ocho `ld hl,nn` los apuntan.
;   0x4ae8..0x4c8d  (421 bytes)
DATA_rotulos_de_pantalla:
	defb 0d5h,03ah,048h,049h,040h,0feh,0ebh,03ah,05ah,04fh,04eh,045h,040h,0feh,0c1h,03ah	; 4ae8  .:HI@..:ZONE@..:
	defb 031h,050h,040h,0ffh,0cbh,03ah,032h,050h,040h,0ffh,0abh,039h,050h,04ch,041h,059h	; 4af8  1P@..:2P@..9PLAY
	defb 000h,053h,045h,04ch,045h,043h,054h,0feh,004h,03ah,001h,010h,02ch,02dh,000h,001h	; 4b08  .SELECT..:..,-..
	defb 020h,01ch,011h,029h,015h,022h,000h,000h,02eh,02fh,000h,01ah,01fh,029h,023h,024h	; 4b18   ..).".../...)#$
	defb 019h,013h,01bh,0feh,044h,03ah,002h,010h,02ch,02dh,000h,002h,020h,01ch,011h,029h	; 4b28  ....D:..,-.. ..)
	defb 015h,022h,023h,000h,02eh,02fh,000h,01ah,01fh,029h,023h,024h,019h,013h,01bh,0feh	; 4b38  ."#../...)#$....
	defb 084h,03ah,003h,010h,02ch,02dh,000h,001h,020h,01ch,011h,029h,015h,022h,000h,000h	; 4b48  .:..,-.. ..)."..
	defb 02eh,02fh,000h,01bh,015h,029h,012h,01fh,011h,022h,014h,0feh,0c4h,03ah,004h,010h	; 4b58  ./...)..."...:..
	defb 02ch,02dh,000h,002h,020h,01ch,011h,029h,015h,022h,023h,000h,02eh,02fh,000h,01bh	; 4b68  ,-.. ..)."#../..
	defb 015h,029h,012h,01fh,011h,022h,014h,0feh,00bh,039h,03ah,03bh,03ch,03dh,03eh,03fh	; 4b78  .)..."...9:;<=>?
	defb 000h,031h,039h,038h,033h,0ffh,06bh,039h,047h,041h,04dh,045h,000h,000h,04fh,056h	; 4b88  .1983.k9GAME..OV
	defb 045h,052h,0feh,02ch,039h,050h,04ch,041h,059h,045h,052h,000h,031h,0ffh,066h,039h	; 4b98  ER.,9PLAYER.1.f9
	defb 040h,000h,056h,049h,044h,045h,04fh,000h,043h,041h,052h,054h,052h,049h,044h,047h	; 4ba8  @.VIDEO.CARTRIDG
	defb 045h,000h,040h,0ffh,038h,060h,090h,003h,00fh,01fh,01fh,01eh,01fh,01fh,00fh,0e0h	; 4bb8  E.@.8`..........
	defb 0f8h,0f8h,038h,008h,001h,0c1h,0f1h,005h,000h,003h,0c3h,005h,000h,083h,0bbh,0bfh	; 4bc8  ..8.............
	defb 0bfh,005h,000h,083h,0c0h,0f1h,0f1h,005h,000h,083h,078h,0feh,0ceh,005h,000h,083h	; 4bd8  ..........x.....
	defb 077h,07fh,07fh,008h,000h,090h,007h,01fh,03fh,07eh,078h,0f8h,0f0h,0f0h,0e0h,0f0h	; 4be8  w.......?~x.....
	defb 0f0h,010h,000h,001h,003h,003h,004h,000h,084h,078h,0feh,0ffh,0cfh,005h,038h,083h	; 4bf8  .........x....8.
	defb 03bh,03fh,03fh,005h,000h,083h,0c3h,0f3h,0f3h,005h,000h,083h,0b9h,0f9h,0f8h,005h	; 4c08  ;??.............
	defb 000h,083h,0fch,0feh,01eh,0b1h,003h,000h,000h,010h,01ch,01fh,01fh,00fh,0f9h,07dh	; 4c18  ...............}
	defb 03dh,03dh,07dh,0fch,0f8h,0e0h,0c3h,0c3h,0c3h,0c3h,0e7h,0ffh,0ffh,03bh,0bch,0b8h	; 4c28  ==}..........;..
	defb 0b8h,0b8h,0bch,0bfh,0bfh,0bbh,07bh,03bh,03bh,03bh,07bh,0f1h,0f1h,0c0h,087h,0ffh	; 4c38  ......{;;;{.....
	defb 0ffh,080h,0c1h,0ffh,0ffh,07eh,078h,007h,070h,008h,000h,088h,0f0h,0f0h,0f8h,078h	; 4c48  .....~x.p......x
	defb 07eh,03fh,01fh,007h,004h,007h,084h,013h,0f3h,0f1h,0e0h,004h,087h,096h,0cfh,0ffh	; 4c58  ~?..............
	defb 0feh,078h,0bch,0b8h,0b8h,0b8h,03ch,03fh,03fh,03bh,07bh,03bh,03bh,03bh,07bh,0f3h	; 4c68  .x....<??;{;;;{.
	defb 0f3h,0c3h,0c0h,081h,005h,083h,089h,081h,00eh,0feh,0feh,08eh,08eh,0feh,0feh,0efh	; 4c78  ................
	defb 005h,038h,003h,000h,000h	; 4c88

; ======================================================================
; CODIGO 0x4c8d..0x4cfa  (109 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Mas ayudas de VRAM
; ----------------------------------------------------------------------
LLENA_VRAM_HL:		; Como LLENA_VRAM, pero con la direccion en HL
	ex de,hl			;4c8d
	call LLENA_VRAM		;4c8e
	ex de,hl			;4c91
	ret			;4c92
COPIA_A_VRAM:		; Vuelca B bytes de HL en la VRAM DE y deja DE detras
	ld c,b			;4c93
	ld b,000h		;4c94
	push bc			;4c96
	call VUELCA_UN_BYTE		;4c97
	pop bc			;4c9a
	ex de,hl			;4c9b
	add hl,bc			;4c9c   ; DE se queda apuntando al final de lo copiado: se puede encadenar
	ex de,hl			;4c9d
	ret			;4c9e
PREPARA_LOGOTIPO:		; Deja el logotipo listo para subir: 0x11 filas y el cursor a cero
	ld a,011h		;4c9f   ; Diecisiete filas es lo que mide el KONAMI grande
	ld (0e00ah),a		;4ca1
	ld hl,00000h		;4ca4
	ld (0e00eh),hl		;4ca7
	ret			;4caa
PINTA_LOGOTIPO:		; Suelta el logotipo comprimido en la VRAM y le da color
	ld hl,04cfah		;4cab
	ld de,06300h		;4cae   ; VRAM 0x6300: los patrones del tercio de abajo
	call PINTA_ROTULO_EN_DE		;4cb1
	ld de,00300h		;4cb4   ; Y 0xD0 bytes de color 0xF0 detras
	ld bc,000d0h		;4cb7
	ld a,0f0h		;4cba
	jp LLENA_VRAM		;4cbc

; ----------------------------------------------------------------------
; El logotipo KONAMI grande, subido a la pantalla una fila por llamada
; ----------------------------------------------------------------------
SUBE_LOGOTIPO:		; Una fila del KONAMI grande por llamada, de abajo arriba
	ld hl,(0e00eh)		;4cbf   ; 0xE00E es el cursor: cuanto lleva subido el logotipo, en bytes de VRAM
	ld de,00020h		;4cc2   ; Una fila entera de la tabla de nombres son 32 bytes
	add hl,de			;4cc5
	ld (0e00eh),hl		;4cc6
	ex de,hl			;4cc9
	or a			;4cca
	ld hl,03aaah		;4ccb   ; Desde 0x3AAA hacia arriba; la primera vez sale 0x3A8A, fila 20 y columna 10
	sbc hl,de		;4cce
	ex de,hl			;4cd0
	ld a,060h		;4cd1   ; Los 26 tiles del logotipo van seguidos desde el 0x60
	ld b,003h		;4cd3   ; Tres tiles arriba, once en medio y doce abajo: asi esta partido el KONAMI grande
	call PINTA_TILES_SEGUIDOS		;4cd5
	ld bc,00b0ch		;4cd8
	call PINTA_TILES_SEGUIDOS		;4cdb
	ld b,c			;4cde
	call PINTA_TILES_SEGUIDOS		;4cdf
	xor a			;4ce2
	call LLENA_VRAM		;4ce3
	ld hl,0e00ah		;4ce6   ; 0xE00A cuenta las filas que quedan; el `dec` deja el z que mira el llamador
	dec (hl)			;4ce9
	ret			;4cea
PINTA_TILES_SEGUIDOS:		; B tiles consecutivos desde el A, en la VRAM DE; al salir, DE en la fila de debajo
	push de			;4ceb
PINTA_UN_TILE_SEGUIDO:
	call VPOKE		;4cec
	inc de			;4cef
	inc a			;4cf0   ; El codigo del tile sube con la columna
	djnz PINTA_UN_TILE_SEGUIDO		;4cf1
	pop de			;4cf3
	ld hl,00020h		;4cf4   ; Se recupera el principio de la fila y se le suman 32: DE baja una fila
	add hl,de			;4cf7
	ex de,hl			;4cf8
	ret			;4cf9

; ----------------------------------------------------------------------
; DATOS logo_konami_grande: El logotipo KONAMI de 26 tiles comprimido,
;   identico byte a byte al de Athletic Land 0x4BD8. Lo lee 0x4CAB.
;   0x4cfa..0x4d8d  (147 bytes)
DATA_logo_konami_grande:
	defb 00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,090h,01fh	; 4cfa  ...........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,005h	; 4d0a  ?............>>.
	defb 000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch	; 4d1a  ..............x.
	defb 0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h	; 4d2a  ....?...........
	defb 0bch,0feh,0dfh,005h,000h,08dh,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h	; 4d3a  ......x..`..`...
	defb 0f0h,03fh,03fh,006h,03eh,090h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh	; 4d4a  .??.>.....?...>>
	defb 03eh,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh	; 4d5a  >~..............
	defb 00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,008h,0e7h,008h,08fh	; 4d6a  ......?.........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 4d7a  .............h.(
	defb 010h,0e0h,000h	; 4d8a

; ======================================================================
; CODIGO 0x4d8d..0x4f58  (459 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La pantalla de la introduccion: la nave que llega a la base
; ----------------------------------------------------------------------
EMPIEZA_LA_INTRO:		; Limpia la fila de arriba y pone la nave en su sitio de salida
	ld hl,03a00h		;4d8d   ; VRAM 0x3A00, 0x20 tiles del 0x87: la fila que separa el marcador
	ld bc,00020h		;4d90
	ld a,087h		;4d93
	call LLENA_VRAM_HL		;4d95
	xor a			;4d98
	ld (0e54bh),a		;4d99   ; 0xE54B a cero: la nave viene volando
	ld hl,041e4h		;4d9c   ; Las cuatro fichas de 0x41E4 al buffer de sprites
	ld de,0e7d0h		;4d9f
	ld bc,00010h		;4da2
	ldir		;4da5
	ld a,060h		;4da7   ; 0x60 fotogramas de vuelo antes de que cambie nada
	ld (0e55ah),a		;4da9
	ret			;4dac
PASO_DE_LA_INTRO:		; Un fotograma de la llegada: la nave baja sola y avanza
	ld a,(0e003h)		;4dad
	push af			;4db0
	and 030h		;4db1   ; Dos bits del contador, subidos abajo: el reloj del decorado
	rrca			;4db3
	rrca			;4db4
	rrca			;4db5
	rrca			;4db6
	call PINTA_LAS_ESTRELLAS		;4db7   ; El decorado de la introduccion
	pop af			;4dba
	and 003h		;4dbb
	call z,MUEVE_LA_LLAMA		;4dbd   ; Y uno de cada cuatro fotogramas, lo de 0x4FA2
	ld hl,(0e7d0h)		;4dc0   ; La posicion de la nave
	dec l			;4dc3   ; Una fila menos: la nave viene bajando
	ld a,(0e54bh)		;4dc4
	cp 002h		;4dc7   ; Con 0xE54B a 2 la nave ya esta parada y no se mueve mas
	jr z,PINTA_CARTEL_INVADE		;4dc9
	or a			;4dcb
	push af			;4dcc
	jr nz,GUARDA_LA_NAVE_MOVIDA		;4dcd
	inc h			;4dcf   ; Volando avanza una columna; en las dos fases baja dos filas
	inc l			;4dd0
	inc l			;4dd1
GUARDA_LA_NAVE_MOVIDA:
	ld (0e7d0h),hl		;4dd2
	ld a,h			;4dd5   ; Y la segunda mitad de la nave, 0x10 columnas por detras
	add a,010h		;4dd6
	ld h,a			;4dd8
	ld (0e7d4h),hl		;4dd9
	ld hl,0e7d9h		;4ddc   ; Las dos fichas de detras
	pop af			;4ddf
	jr z,BAJA_LAS_ACOMPANANTES		;4de0
	dec hl			;4de2
BAJA_LAS_ACOMPANANTES:
	dec (hl)			;4de3   ; Una fila menos tambien
	ld a,l			;4de4
	add a,004h		;4de5
	ld l,a			;4de7
	dec (hl)			;4de8
	call VUELCA_LOS_SPRITES		;4de9   ; Y las fichas suben a la pantalla
	ld hl,0e55ah		;4dec   ; 0xE55A es lo que dura la fase de la llegada
	dec (hl)			;4def
	ret nz			;4df0
	ld hl,0e54bh		;4df1   ; Agotada, se pasa a la fase siguiente de 0xE54B
	inc (hl)			;4df4
	ld a,(hl)			;4df5   ; La fase nueva
	cp 002h		;4df6
	jr z,PINTA_CARTEL_INVADE		;4df8
	ld a,058h		;4dfa   ; La segunda fase dura 0x58 fotogramas
	ld (0e55ah),a		;4dfc
	ld a,004h		;4dff   ; 0xE7DF a 4: el dibujo del tren de aterrizaje
	ld (0e7dfh),a		;4e01
	ret			;4e04
PINTA_CARTEL_INVADE:		; Suelta el cartel INVADE THE BASE AND / CARRY AWAY BOOTY
	ld hl,041f4h		;4e05   ; El cartel de la introduccion
	call PINTA_DIBUJO		;4e08
	ld hl,0e558h		;4e0b   ; Y 0xE558 lleva lo que dura en pantalla
	dec (hl)			;4e0e
	jr nz,VUELCA_LOS_SPRITES		;4e0f
	ld a,001h		;4e11
	ld (0e00bh),a		;4e13
VUELCA_LOS_SPRITES:		; Los 0x10 bytes de fichas de 0xE7D0 a la VRAM 0x3B00
	ld hl,0e7d0h		;4e16   ; Cuatro fichas de cuatro bytes: las dos mitades de la nave y sus dos acompanantes
	ld de,03b00h		;4e19
	ld bc,00010h		;4e1c
	jp VUELCA_UN_BYTE		;4e1f
REINICIA_EL_TERRENO:		; Los cuatro punteros del terreno vuelven al principio del buffer
	ld hl,0e660h		;4e22   ; 0xE660 es donde empieza el terreno montado
	ld (0e540h),hl		;4e25   ; Cuatro punteros a la vez -0xE540, 42, 44 y 46-: cuatro lecturas distintas del mismo terreno
	ld (0e542h),hl		;4e28   ; El segundo
	ld (0e544h),hl		;4e2b   ; El tercero
	ld (0e546h),hl		;4e2e   ; Y el cuarto
	xor a			;4e31   ; A cero lo que viene detras
	ld l,020h		;4e32
	ld (hl),a			;4e34   ; En las dos paginas del buffer
	inc h			;4e35
	ld (hl),a			;4e36
	ld (0e51fh),a		;4e37   ; 0xE51F, 0xE50E, 0xE54B y 0xE530 a cero: nada reventando, nave volando
	ld (0e50eh),a		;4e3a
	ld (0e54bh),a		;4e3d
	ld (0e530h),a		;4e40
	ld hl,0e534h		;4e43   ; Cuatro bytes seguidos de 0xE534
	ld (hl),a			;4e46
	inc hl			;4e47
	ld (hl),a			;4e48
	inc hl			;4e49
	ld (hl),a			;4e4a
	inc hl			;4e4b
	ld (hl),a			;4e4c
	ld l,05fh		;4e4d   ; Y dos mas en 0xE55F
	ld (hl),a			;4e4f
	inc hl			;4e50
	ld (hl),a			;4e51
	inc a			;4e52
	ld (0e51eh),a		;4e53   ; 0xE51E y 0xE54F a uno
	ld (0e54fh),a		;4e56   ; 0xE54F a uno: hay que rehacer las fichas
	ld a,003h		;4e59   ; 0xE519 arranca en 3 y 0xE548 en 4
	ld (0e519h),a		;4e5b
	ld a,004h		;4e5e   ; Y 0xE548, que cuenta lo que puede salir
	ld (0e548h),a		;4e60
	call PINTA_LA_BASE		;4e63   ; El rotulo de la zona
	call REPONE_COMBUSTIBLE		;4e66   ; El deposito lleno
	jp SUBE_LOS_REGISTROS_DEL_VDP		;4e69   ; Y los registros del VDP
REPARTE_LOS_MARCADORES:		; Deja los dos marcadores y el escalon de la vida extra
	xor a			;4e6c
	ld (0e058h),a		;4e6d
	ld de,0e046h		;4e70
	ld hl,0e056h		;4e73
	ld (hl),003h		;4e76   ; 0xE056 a 3 y 0xE057 a 0x24
	inc hl			;4e78
	ld (hl),024h		;4e79
	ret			;4e7b
EMPIEZA_LA_FASE:		; Limpia la pantalla, el buffer del terreno y las fichas de sprite
	ld hl,03aa0h		;4e7c   ; VRAM 0x3AA0, 0x20 tiles del 0x87: la fila de separacion
	ld a,087h		;4e7f
	ld bc,00020h		;4e81
	call LLENA_VRAM_HL		;4e84
	call REINICIA_EL_TERRENO		;4e87
	ld hl,0e550h		;4e8a   ; Ocho bytes de 0xE550 a cero
	ld b,008h		;4e8d
	xor a			;4e8f
BORRA_UN_BYTE:
	ld (hl),a			;4e90
	inc hl			;4e91
	djnz BORRA_UN_BYTE		;4e92
	ld hl,000b1h		;4e94   ; 0xE50B arranca en 0xB1: lo que falta para llegar a la base
	ld (0e50bh),hl		;4e97
	ld hl,0e800h		;4e9a   ; Los cuatro tercios del buffer, 0xA0 bytes cada uno, a cero
	ld c,004h		;4e9d
BORRA_UN_TERCIO:
	ld b,0a0h		;4e9f
BORRA_UN_BYTE_DEL_BUFFER:
	ld (hl),a			;4ea1
	inc hl			;4ea2
	djnz BORRA_UN_BYTE_DEL_BUFFER		;4ea3
	ld l,a			;4ea5
	inc h			;4ea6
	inc h			;4ea7
	dec c			;4ea8
	jr nz,BORRA_UN_TERCIO		;4ea9
	ld hl,05036h		;4eab   ; Los diez y seis primeros bytes de 0x5036 a las fichas de 0xE7C8...
	ld de,0e7c8h		;4eae
	ld c,010h		;4eb1
	ldir		;4eb3
	ld a,00ah		;4eb5   ; ...y detras, diez tandas de cuatro bytes iguales: los sprites que todavia no se usan quedan todos con la misma ficha
REPITE_UNA_FICHA:
	push hl			;4eb7   ; Se guarda el principio de la tanda de cuatro
	ld c,004h		;4eb8
	ldir		;4eba
	pop hl			;4ebc
	dec a			;4ebd   ; Diez tandas iguales
	jr nz,REPITE_UNA_FICHA		;4ebe
MONTA_LAS_FICHAS:		; Deja puestas las fichas de sprite del marcador y del suelo
	ld hl,00724h		;4ec0
	ld (0e7eah),hl		;4ec3
	ld a,0d1h		;4ec6   ; 0xD1 es el tile que se planta en las dos fichas de 0xE7C8 y 0xE7CC
	ld (0e7c8h),a		;4ec8
	ld (0e7cch),a		;4ecb
	ld hl,0e7e8h		;4ece
	ld de,03b18h		;4ed1   ; 0x18 bytes a la VRAM 0x3B18: las seis fichas de la segunda mitad
	ld b,018h		;4ed4
	call COPIA_A_VRAM		;4ed6
	ld hl,0e7c8h		;4ed9
	ld b,008h		;4edc
	call COPIA_A_VRAM		;4ede
	ld hl,0e053h		;4ee1   ; 0xE053, la zona, es lo ultimo que se pinta
	jp PONE_FICHAS_DE_ZONA		;4ee4

; ----------------------------------------------------------------------
; Pasar una posicion a una direccion de la VRAM
; ----------------------------------------------------------------------
POSICION_A_NOMBRE:		; H columna y L fila pasan a la direccion de la tabla de nombres
	ld a,l			;4ee7   ; Nueve desplazamientos entre A y H: dividir los dos por ocho a la vez, que es pasar de pixeles a casillas
	rra			;4ee8
	rra			;4ee9
	rra			;4eea
	rra			;4eeb
	rr h		;4eec
	rra			;4eee
	rr h		;4eef
	rra			;4ef1
	rr h		;4ef2
	ld l,h			;4ef4
	and 003h		;4ef5   ; Y el resultado se monta sobre 0x3800, la tabla de nombres
	add a,038h		;4ef7
	ld h,a			;4ef9
	ret			;4efa
POSICION_A_PATRON:		; La misma posicion, pero como direccion dentro de la tabla de patrones
	ld b,a			;4efb
	and 007h		;4efc   ; Los tres bits bajos son el pixel dentro de la casilla
	rra			;4efe
	ld c,a			;4eff
	ld a,l			;4f00
	jr nc,MEDIA_CASILLA_MENOS		;4f01
	sub 020h		;4f03
MEDIA_CASILLA_MENOS:
	dec c			;4f05
	sub c			;4f06
	ld l,a			;4f07
POSICION_A_PIXEL:
	add hl,hl			;4f08   ; Tres `add hl,hl` es multiplicar por ocho: cada casilla son ocho bytes
	add hl,hl			;4f09
	add hl,hl			;4f0a
	ld a,h			;4f0b
	rla			;4f0c
	rla			;4f0d
	rla			;4f0e
	and 0f8h		;4f0f
	ld h,l			;4f11
	ld l,a			;4f12
	bit 3,b		;4f13   ; Con el bit 3 puesto, cuatro filas menos
	ret z			;4f15
	ld a,h			;4f16
	sub 004h		;4f17
	ld h,a			;4f19
	ret			;4f1a

; ----------------------------------------------------------------------
; El cielo. Las estrellas se encienden y se apagan por lista
; ----------------------------------------------------------------------
MUEVE_LAS_ESTRELLAS:		; Cambia de lista de estrellas cada cuatro veces
	ld a,(0e054h)		;4f1b   ; Con techo (0xE054) no hay estrellas: se esta dentro de una cueva, no bajo el cielo
	and a			;4f1e
	ret nz			;4f1f
	ld hl,0e519h		;4f20   ; 0xE519 cuenta hacia atras de 4 a 1 y vuelve a empezar
	dec (hl)			;4f23
	ld a,(hl)			;4f24
	jr nz,PINTA_LAS_ESTRELLAS		;4f25
	ld (hl),004h		;4f27
PINTA_LAS_ESTRELLAS:		; Enciende o apaga las estrellas de una de las dos listas
	ld c,005h		;4f29   ; El tile 5 es la estrella...
	rra			;4f2b
	jr nc,LA_PRIMERA_LISTA		;4f2c
	ld c,000h		;4f2e   ; ...y el 0, el cielo vacio: la misma rutina las pone y las quita
LA_PRIMERA_LISTA:
	ld de,04f58h		;4f30   ; Un bit elige lista: 0x4F58 o 0x4F61
	rra			;4f33
	push af			;4f34
	jr c,DESDE_EL_PRINCIPIO		;4f35
	ld de,04f61h		;4f37
DESDE_EL_PRINCIPIO:
	ld hl,03800h		;4f3a   ; Se recorre la tabla de nombres desde el principio
LEE_LA_CUENTA:
	ld a,(de)			;4f3d   ; El primer byte de la lista es cuantas estrellas, y los que siguen, cuanto se avanza hasta cada una
	ld b,a			;4f3e
PON_UNA_ESTRELLA:
	inc de			;4f3f
	ld a,(de)			;4f40
	call HL_MAS_A		;4f41
	ld a,c			;4f44
	call VPOKE_HL		;4f45   ; Y ahi se planta el tile, estrella o vacio
	djnz PON_UNA_ESTRELLA		;4f48
	ld l,0e0h		;4f4a   ; Con H impar ya se ha pasado del tercio: se acabo
	bit 0,h		;4f4c
	ret nz			;4f4e
	pop af			;4f4f
	inc de			;4f50
	jr c,LEE_LA_CUENTA		;4f51
	ld de,04f58h		;4f53   ; La otra lista, para la segunda pasada
	jr LEE_LA_CUENTA		;4f56

; ----------------------------------------------------------------------
; DATOS listas_de_estrellas: Las dos listas de sitios del cielo que recorre
;   0x4F29: la de 0x4F58 (desde 0x4F30 y 0x4F53) y la de 0x4F61 (desde
;   0x4F37). El primer byte de cada una dice cuantas estrellas vienen, y los
;   siguientes cuanto se avanza en la tabla de nombres desde la anterior.
;   0x4f58..0x4f70  (24 bytes)
DATA_listas_de_estrellas:
	defb 008h,001h,017h,035h,02dh,009h,027h,026h,02bh,00eh,00bh,019h,00bh,00ah,013h,010h	; 4f58  ...5-.'&+.......
	defb 006h,018h,019h,00ch,029h,016h,014h,009h	; 4f68  ....)...

; ======================================================================
; CODIGO 0x4f70..0x5036  (198 bytes)
; ======================================================================


REPONE_COMBUSTIBLE:		; Deja el deposito en 0x1F y suelta la nave
	and 050h		;4f70   ; Dos bits de A: no en cualquier momento
	ret nz			;4f72
	ld (0e560h),a		;4f73   ; 0xE560 a cero: la nave vuelve a obedecer al mando
	ld hl,0e51ch		;4f76
	ld a,(hl)			;4f79
	ld (hl),01fh		;4f7a   ; 0x1F es el deposito lleno
PINTA_COMBUSTIBLE:		; La barra del deposito, en la VRAM 0x3AF6
	ld hl,03af6h		;4f7c
	ld a,(0e51ch)		;4f7f
	ld c,a			;4f82
	rra			;4f83   ; Dividido entre cuatro: cuantas casillas van enteras
	rra			;4f84
	and 007h		;4f85
	jr z,LA_CASILLA_A_MEDIAS		;4f87
	ld b,a			;4f89
	ld a,0c4h		;4f8a   ; 0xC4 es la casilla llena del deposito
PINTA_CASILLA_LLENA:
	call VPOKE_HL		;4f8c
	inc hl			;4f8f
	djnz PINTA_CASILLA_LLENA		;4f90
LA_CASILLA_A_MEDIAS:
	ld a,c			;4f92   ; Y lo que sobra de la division, de 1 a 3, es la casilla a medias: 0xC4 mas el resto da los tres dibujos intermedios
	and 003h		;4f93
	jr z,BORRA_LA_DE_DETRAS		;4f95
	add a,0c4h		;4f97
	call VPOKE_HL		;4f99
	inc hl			;4f9c
BORRA_LA_DE_DETRAS:
	xor a			;4f9d   ; Detras, una casilla vacia que borra lo que hubiera antes
	call VPOKE_HL		;4f9e
	ret			;4fa1
MUEVE_LA_LLAMA:		; Cambia el dibujo de la llama del motor entre dos
	ld hl,0e7d2h		;4fa2
	ld de,0141ch		;4fa5   ; 0x14 y 0x1C, o 0x18 y 0x20: dos dibujos que se turnan
	ld a,(hl)			;4fa8
	cp d			;4fa9   ; Si ya esta en el primero, se pone el segundo, y al reves
	jr nz,GUARDA_LA_LLAMA		;4faa
	ld de,01820h		;4fac
GUARDA_LA_LLAMA:
	ld (hl),d			;4faf
	ld hl,0e7d6h		;4fb0
	ld (hl),e			;4fb3
	ret			;4fb4
MONTA_SPRITES_DE_ZONA:		; Rehace las fichas de sprite si ha cambiado la zona
	ld hl,0e54fh		;4fb5
	xor a			;4fb8   ; 0xE54F puesto es que hay que rehacerlas
	cp (hl)			;4fb9
	ret z			;4fba
	ld (hl),a			;4fbb
	ld hl,0e053h		;4fbc
PONE_FICHAS_DE_ZONA:		; Cuatro fichas sacadas de la tabla de 0x504A, segun la clase de zona
	ld a,(hl)			;4fbf
	and 003h		;4fc0   ; Los dos bits bajos de 0xE053: cuatro clases de zona
	push af			;4fc2
	add a,a			;4fc3   ; Por cuatro, que es lo que ocupa cada juego de fichas
	add a,a			;4fc4
	ld de,0e7d8h		;4fc5
	ld hl,0504ah		;4fc8
	call HL_MAS_A		;4fcb
	ld a,004h		;4fce
COPIA_UNA_FICHA:
	push hl			;4fd0
	ld bc,00004h		;4fd1   ; Cuatro fichas de cuatro bytes, una detras de otra
	ldir		;4fd4
	dec a			;4fd6
	pop hl			;4fd7
	jr nz,COPIA_UNA_FICHA		;4fd8
	pop af			;4fda
	dec a			;4fdb   ; En la clase 1, el dibujo de la tercera ficha es el 9
	jr nz,SUBE_LAS_CUATRO		;4fdc
	ld a,009h		;4fde
	ld (0e7dbh),a		;4fe0
SUBE_LAS_CUATRO:
	ld hl,0e7d8h		;4fe3
	ld de,03b08h		;4fe6   ; Y las cuatro fichas a la VRAM 0x3B08
	ld b,010h		;4fe9
	jp COPIA_A_VRAM		;4feb
APAGA_LAS_FICHAS:		; Deja las catorce fichas de sprite en el dibujo 0xD1
	ld hl,0e7c8h		;4fee
	ld b,00eh		;4ff1
APAGA_FICHAS_DESDE_HL:
	ld (hl),0d1h		;4ff3   ; 0xD1 de cuatro en cuatro: solo se toca el dibujo de cada ficha
	ld a,004h		;4ff5
	add a,l			;4ff7
	ld l,a			;4ff8
	djnz APAGA_FICHAS_DESDE_HL		;4ff9
	ld hl,0e7c8h		;4ffb
	ld de,03b30h		;4ffe
	ld b,008h		;5001
	call COPIA_A_VRAM		;5003
	ld e,000h		;5006   ; Y de la 0x3B30 en adelante, 0x30 bytes mas
	ld b,030h		;5008
	jp COPIA_A_VRAM		;500a
PINTA_LA_BASE:		; Suelta en el buffer el dibujo de 0x4614
	ld de,04614h		;500d
	jr DESPLIEGA_EN_EL_BUFFER		;5010
PINTA_EL_ROTULO_DE_FASE:		; Lo mismo con el rotulo de 0x506D
	ld de,0506dh		;5012
DESPLIEGA_EN_EL_BUFFER:
	ld hl,0eb31h		;5015   ; 0xEB31 dentro del buffer del decorado
	ld c,003h		;5018
	push de			;501a
	jp DESPLIEGA_UNA_FILA		;501b   ; Se entra a DESPLIEGA por dentro, en 0x4673, con la cuenta ya puesta

; ----------------------------------------------------------------------
; Los puntos que se ganan, unos fijos y otros por sorteo
; ----------------------------------------------------------------------
PUNTOS_DE_PREMIO:		; Cincuenta puntos, o una cantidad sorteada
	ld hl,00050h		;501e   ; 0x0050 son cincuenta puntos en BCD
	and 050h		;5021
	jr nz,PREMIO_SORTEADO		;5023
	ld a,r		;5025   ; El registro R del Z80 -el contador de refresco de la memoria- vale aqui de dado: sus dos bits bajos dan 0, 1, 2 o 3...
	and 003h		;5027
	ld h,a			;5029   ; ...y eso se sube al byte alto, asi que el premio es 0, 100, 200 o 300
	ld l,000h		;502a
PREMIO_SORTEADO:
	ex de,hl			;502c
SUMA_ESTE_PREMIO:
	jp SUMA_PUNTOS		;502d
PUNTOS_ACUMULADOS:		; Suma lo que se haya ido juntando en 0xE55B
	ld de,(0e55bh)		;5030
	jr SUMA_ESTE_PREMIO		;5034

; ----------------------------------------------------------------------
; DATOS rotulos_de_fase: Rotulos con direccion de VRAM, entre ellos 900 MILES
;   CLEARED en VRAM 0x3929 (0x505A). Los leen 0x4EAB, 0x524C, 0x4FC8, 0x5091 y
;   0x5012, y 0x4A06 lee un byte suelto de 0x503A con `ld a,(nn)`.
;   0x5036..0x5078  (66 bytes)
DATA_rotulos_de_fase:
	defb 098h,0ffh,028h,00fh,098h,0ffh,02ch,00bh,040h,004h,014h,00fh,040h,014h,01ch,00fh	; 5036  ..(...,.@...@...
	defb 0d1h,000h,000h,00dh,0d1h,000h,004h,009h,0d1h,000h,008h,00ah,0d1h,000h,00ch,00ah	; 5046  ................
	defb 0d1h,000h,010h,008h,029h,039h,030h,030h,000h,04dh,049h,04ch,045h,053h,000h,043h	; 5056  ....)900.MILES.C
	defb 04ch,045h,041h,052h,045h,044h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 5066  LEARED..........
	defb 000h,0ffh	; 5076

; ======================================================================
; CODIGO 0x5078..0x516f  (247 bytes)
; ======================================================================


PINTA_LA_ZONA:		; El numero de zona en la VRAM 0x3927
	ld hl,0e051h		;5078
	ld de,03927h		;507b
	ld b,001h		;507e   ; Un solo byte en BCD
	call PINTA_UN_BYTE_BCD		;5080
	ld a,(0e051h)		;5083
	cp 010h		;5086   ; Por debajo de la zona 16 se borra la cifra de las decenas
	jr nc,EL_ROTULO_DE_LA_ZONA		;5088
	ld de,03927h		;508a
	xor a			;508d
	call VPOKE		;508e
EL_ROTULO_DE_LA_ZONA:
	ld hl,0505ah		;5091   ; Y el rotulo de 0x505A al lado
	jp PINTA_DIBUJO		;5094
LA_NAVE_SE_PARA:		; Deja la nave quieta y suena el aviso
	ld a,002h		;5097   ; 0xE54B a 2: MUEVE_LA_NAVE deja de hacer caso al mando
	ld (0e54bh),a		;5099
	ld a,08bh		;509c
	jp SUENA_ESTO		;509e
MIRA_SI_ATERRIZA:		; La nave contra el deposito del final
	ld a,(0e54ah)		;50a1   ; Con 0xE54A a cero no hay deposito que tocar
	or a			;50a4
	jr z,SUBE_LAS_FICHAS_DE_LA_NAVE		;50a5
	ld hl,05648h		;50a7   ; Los margenes del deposito
	ld bc,(0e7c8h)		;50aa
	call HAY_CHOQUE		;50ae
	jr nc,SUBE_LAS_FICHAS_DE_LA_NAVE		;50b1
	xor a			;50b3
	ld (0e54ah),a		;50b4   ; Tocado: 0xE54A se apaga y 0xE54B pasa a 1, que es aterrizando
	inc a			;50b7
	ld (0e54bh),a		;50b8
	ld a,004h		;50bb
	ld (0e7cfh),a		;50bd   ; Y la ficha se queda con el dibujo 4
	jr SUBE_LAS_FICHAS_DE_LA_NAVE		;50c0

; ----------------------------------------------------------------------
; Un fotograma de partida, de principio a fin
; ----------------------------------------------------------------------
PASO_DE_PARTIDA:		; Mueve la nave, la dibuja, mira los choques y corre el decorado
	ld a,(0e50eh)		;50c2   ; 0xE50E distinto de cero es que la nave esta reventando: por 0x5BE5
	and a			;50c5
	jp nz,PASO_DEL_REVENTON		;50c6
	ld hl,(0e7d0h)		;50c9   ; 0xE7D0 lleva la posicion de la nave: H la columna, L la fila
	call MUEVE_LA_NAVE		;50cc
	ld e,l			;50cf
	ld d,h			;50d0
	ld (0e7d0h),hl		;50d1   ; Se guarda ya movida...
	ld a,h			;50d4
	add a,010h		;50d5
	ld h,a			;50d7
	ld (0e7d4h),hl		;50d8   ; ...y 0xE7D4 es la misma con 0x10 mas en la columna: el segundo sprite, que es la mitad de atras de la nave
	ld a,(0e54bh)		;50db   ; 0xE54B es en que anda la nave: 0 volando, 1 aterrizando, 2 quieta
	dec a			;50de
	jp m,MIRA_SI_ATERRIZA		;50df
	jp nz,LLEGA_A_LA_BASE		;50e2
	ld de,0fc0ch		;50e5   ; 0xFC0C sumado: doce filas mas arriba y cuatro columnas a la izquierda
	add hl,de			;50e8
	ld (0e7c8h),hl		;50e9
	ld (0e7cch),hl		;50ec
	ld a,079h		;50ef   ; Pasada la columna 0x79 el disparo ya no cabe en pantalla
	cp l			;50f1
	jr nc,LA_NAVE_SE_PARA		;50f2
SUBE_LAS_FICHAS_DE_LA_NAVE:
	ld hl,0e7c8h		;50f4
	ld de,03b30h		;50f7   ; VRAM 0x3B30: las fichas de sprite, ocho bytes por tanda
	ld b,008h		;50fa
	call COPIA_A_VRAM		;50fc
	ld e,b			;50ff
	ld b,008h		;5100
	call COPIA_A_VRAM		;5102
	ld hl,0e012h		;5105
	bit 7,(hl)		;5108   ; El bit 7 de 0xE012 apaga el zumbido del motor
	jr nz,CUENTA_EL_FOTOGRAMA		;510a
	ld a,(0e51ch)		;510c   ; Por debajo de 0x10 de combustible (0xE51C), el aviso
	cp 010h		;510f
	ld a,007h		;5111
	jr c,SUENA_SI_HA_CAMBIADO		;5113
	ld a,(0e053h)		;5115   ; Los dos bits bajos de 0xE053 reparten el sonido entre fotogramas
	and 003h		;5118
	cp 001h		;511a
	ld a,006h		;511c
	jr z,SUENA_SI_HA_CAMBIADO		;511e
	ld a,048h		;5120
SUENA_SI_HA_CAMBIADO:
	cp (hl)			;5122
	call nz,SUENA_ESTO		;5123   ; Solo se manda el sonido si ha CAMBIADO: si no, se estaria reiniciando el mismo efecto sesenta veces por segundo
CUENTA_EL_FOTOGRAMA:
	ld hl,0e514h		;5126   ; 0xE514 cuenta los fotogramas de la fase
	inc (hl)			;5129
	ld a,(0e7d0h)		;512a   ; Entre las columnas 0x99 y 0xA1 no se miran choques: es el paso de fase
	sub 099h		;512d
	cp 008h		;512f
	jp c,MIRA_SI_HA_CHOCADO		;5131
	ld a,(hl)			;5134
	cp 002h		;5135
	jr c,EL_TERCER_CHOQUE		;5137
	call CHOQUE_CON_EL_DECORADO		;5139   ; Tres comprobaciones de choque en cadena; a la primera que da carry, se corta
	jr c,MIRA_SI_HA_CHOCADO		;513c
	call CHOQUE_CON_LO_QUE_VUELA		;513e
	jr c,MIRA_SI_HA_CHOCADO		;5141
EL_TERCER_CHOQUE:
	call CHOQUE_CON_LO_QUE_DISPARAN		;5143
MIRA_SI_HA_CHOCADO:
	jp c,LA_NAVE_REVIENTA		;5146   ; Con carry, la nave ha chocado: por 0x5BD6
	call DISPARA_O_BOMBEA		;5149
	ld a,(0e003h)		;514c
	rra			;514f
	jr nc,EL_RESTO_DEL_FOTOGRAMA		;5150
	ld hl,0e620h		;5152   ; Los dos buffers del decorado, 0xE620 y 0xE720, uno por fotograma alterno
	call MUEVE_EL_DISPARO		;5155
	ld hl,0e720h		;5158
	call MUEVE_EL_DISPARO		;515b
	call MUEVE_LOS_DISPAROS		;515e
EL_RESTO_DEL_FOTOGRAMA:
	call MUEVE_LA_BOMBA		;5161
	call VUELCA_LAS_EXPLOSIONES		;5164
	ld a,(0e003h)		;5167
	and 007h		;516a   ; Los tres bits bajos del contador de fotogramas: ocho submodos que se van turnando, uno por fotograma
	call DESPACHA		;516c

; ----------------------------------------------------------------------
; DATOS tabla_de_submodos: Las ocho palabras del despachador de 0x4050,
;   pegadas detras del `call` de 0x516C. El indice es (0xE003) and 7, o sea
;   que los ocho submodos se turnan uno por fotograma. La tabla acaba en
;   0x517E: lo que hay en 0x517F ya es codigo, la rutina que mueve la nave, y
;   la llama 0x50CC.
;   0x516f..0x517f  (16 bytes)
DATA_tabla_de_submodos:
	defb 00fh,052h	; 516f
	defb 005h,053h	; 5171
	defb 075h,052h	; 5173
	defb 091h,052h	; 5175
	defb 078h,052h	; 5177
	defb 0b4h,052h	; 5179
	defb 075h,052h	; 517b
	defb 0cdh,052h	; 517d

; ======================================================================
; CODIGO 0x517f..0x55d7  (1112 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Mover la nave con el mando
; ----------------------------------------------------------------------
MUEVE_LA_NAVE:		; Aplica el mando a HL: H es la columna y L la fila
	ld a,(0e54bh)		;517f   ; Con 0xE54B a 2 la nave esta quieta y el mando no la mueve
	cp 002h		;5182
	ret z			;5184
	ld a,(0e560h)		;5185   ; Y con 0xE560 puesto baja sola, sin mando
	or a			;5188
	jr z,LEE_EL_MANDO		;5189
	inc l			;518b
	ret			;518c
LEE_EL_MANDO:
	ld a,(0e009h)		;518d   ; 0xE009 es lo que se esta pulsando ahora, ya venga del joystick o del teclado
	rra			;5190   ; Bit 0, arriba: una fila menos
	jr nc,MIRA_ABAJO		;5191
	dec l			;5193
MIRA_ABAJO:
	rra			;5194   ; Bit 1, abajo: una fila mas
	jr nc,MIRA_IZQUIERDA		;5195
	inc l			;5197
MIRA_IZQUIERDA:
	rra			;5198   ; Bit 2, izquierda: una columna menos
	jr nc,MIRA_DERECHA		;5199
	dec h			;519b
MIRA_DERECHA:
	rra			;519c   ; Bit 3, derecha: una columna mas
	jr nc,TOPE_DE_COLUMNA		;519d
	inc h			;519f
TOPE_DE_COLUMNA:
	ld a,h			;51a0   ; Los topes se ponen deshaciendo el paso que se acaba de dar
	cp 078h		;51a1   ; La columna no pasa de 0x77...
	jr c,TOPE_POR_LA_IZQUIERDA		;51a3
	dec h			;51a5
TOPE_POR_LA_IZQUIERDA:
	cp 003h		;51a6   ; ...ni baja de 3
	jr nc,TOPE_DE_FILA		;51a8
	inc h			;51aa
TOPE_DE_FILA:
	ld a,l			;51ab   ; Y la fila nunca llega a 0: en la de arriba esta el marcador
	and a			;51ac
	jr nz,LA_NAVE_YA_ESTA_PUESTA		;51ad
	inc l			;51af
LA_NAVE_YA_ESTA_PUESTA:
	ret			;51b0

; ----------------------------------------------------------------------
; Disparar y soltar la bomba, mirando el FLANCO del boton
; ----------------------------------------------------------------------
DISPARA_O_BOMBEA:		; Suelta el disparo o la bomba cuando se ACABA de pulsar
	ld hl,0e008h		;51b1   ; 0xE008 es lo del fotograma anterior y 0xE009 lo de ahora: el `cpl` y los dos `and` dejan pasar solo el fotograma en que el boton pasa de suelto a pulsado. Sin esto, tener el boton apretado dispararia sesenta veces por segundo
	ld a,(hl)			;51b4
	inc hl			;51b5
	cpl			;51b6
	and 010h		;51b7
	and (hl)			;51b9
	ret z			;51ba
	ld hl,0e620h		;51bb   ; Se busca hueco en 0xE620 o en la pagina de al lado
	xor a			;51be
	cp (hl)			;51bf
	jr z,OCUPA_EL_HUECO		;51c0
	inc h			;51c2
	cp (hl)			;51c3
	jr nz,SUELTA_LA_BOMBA		;51c4
OCUPA_EL_HUECO:
	inc (hl)			;51c6
	ld a,(0e7d0h)		;51c7   ; Los tres bits bajos de la fila deciden hacia donde sale
	and 007h		;51ca
	ld de,00043h		;51cc   ; 0x43 o 0x23 de alcance, segun hacia donde salga
	jr nz,EL_DIBUJO_DEL_DISPARO		;51cf
	ld e,023h		;51d1
EL_DIBUJO_DEL_DISPARO:
	add a,0f0h		;51d3   ; 0xF0 mas eso: el dibujo del disparo
	inc hl			;51d5
	ld (hl),a			;51d6   ; El dibujo, en el segundo byte del hueco
	push hl			;51d7
	ld hl,(0e7d0h)		;51d8   ; La posicion de la nave
	call POSICION_A_NOMBRE		;51db   ; Se mira el tile de donde iria a parar
	add hl,de			;51de
	call VPEEK_HL		;51df   ; Se lee el tile de donde iria
	ex de,hl			;51e2
	pop hl			;51e3
	cp 006h		;51e4   ; Por debajo del tile 6 es cielo: el disparo cabe
	jr nc,DEJA_EL_HUECO_LIBRE		;51e6
	inc hl			;51e8
	ld (hl),e			;51e9   ; Y ahi se guarda, en los dos bytes del hueco
	inc hl			;51ea
	ld (hl),d			;51eb
	ld a,(0e7d0h)		;51ec   ; Quince pixeles por delante de la nave
	add a,00fh		;51ef
	inc hl			;51f1
	ld (hl),a			;51f2
	ld a,041h		;51f3   ; 0x41 es el sonido de disparar
	call SUENA_ESTO		;51f5
	jr SUELTA_LA_BOMBA		;51f8
DEJA_EL_HUECO_LIBRE:
	dec hl			;51fa   ; Y si no cabe, el hueco se deja libre
	ld (hl),000h		;51fb
SUELTA_LA_BOMBA:		; Da de alta la bomba, doce pixeles por delante de la nave
	ld hl,0e51fh		;51fd   ; 0xE51F puesto es que ya hay una bomba cayendo
	ld a,(hl)			;5200
	or a			;5201
	ret nz			;5202
	inc (hl)			;5203
	ld hl,(0e7d4h)		;5204   ; Doce pixeles por delante de la segunda mitad de la nave
	ld de,0000ch		;5207
	add hl,de			;520a
	ld (0e7e8h),hl		;520b
	ret			;520e
SUBMODO_0_VUELCA:		; Cambia de buffer y sube el decorado a la pantalla
	call SUBMODO_4		;520f
	ld hl,0e50dh		;5212   ; 0xE50D es que buffer toca: se le da la vuelta cada vez
	ld a,(hl)			;5215   ; Se le da la vuelta al bit
	xor 001h		;5216
	ld (hl),a			;5218
	add a,a			;5219   ; 0 da 0xE800 y 1 da 0xEA00: la pagina del buffer que ahora se lee
	add a,0e8h		;521a
	ld h,a			;521c   ; La pagina, ya montada en H
	ld l,000h		;521d
	ld de,03a00h		;521f   ; VRAM 0x3A00, 0xA0 bytes: las cinco filas de decorado
	ld b,0a0h		;5222
	call COPIA_A_VRAM		;5224   ; Y de ahi a la VRAM
	ld c,0e8h		;5227
	call CORRE_EL_BUFFER		;5229   ; Detras, correr el buffer una columna
	ld a,(0e053h)		;522c   ; Los dos bits bajos de 0xE053 dicen que clase de zona es esta
	and 003h		;522f
	sub 003h		;5231   ; La clase 3 es la unica que sigue
	jr nz,REMATA_EL_ROTULO		;5233
	ld hl,0e056h		;5235   ; 0xE056 tiene que valer uno
	inc a			;5238
	cp (hl)			;5239
	ex de,hl			;523a
	jr nz,REMATA_EL_ROTULO		;523b
	ld hl,(0e50bh)		;523d   ; 0xE50B contra 0xBB: la nave esta en el sitio exacto donde se pasa de fase
	ld bc,000bbh		;5240   ; 0xBB es la columna exacta del cambio
	sbc hl,bc		;5243
	jr nz,REMATA_EL_ROTULO		;5245
	ex de,hl			;5247
	inc (hl)			;5248   ; Se apunta que ya se ha pasado
	ld (0e54ah),a		;5249
	ld hl,05036h		;524c   ; Los ocho bytes de 0x5036 al buffer de fichas: el rotulo de la fase
	ld de,0e7c8h		;524f
	ld bc,00008h		;5252
	ldir		;5255
	call PINTA_EL_ROTULO_DE_FASE		;5257   ; Y se pinta el rotulo
REMATA_EL_ROTULO:
	ld de,0e54ah		;525a   ; 0xE54A puesto es que hay algo que rematar en el rotulo
	ld a,(de)			;525d   ; Con 0xE54A a cero no hay nada mas
	or a			;525e
	ret z			;525f
	ld hl,0e7c9h		;5260   ; La columna del deposito
	ld a,(hl)			;5263
	sub 004h		;5264   ; Cuatro columnas antes
	ld b,a			;5266
	jr nc,PLANTA_LAS_DOS_PIEZAS		;5267
	xor a			;5269   ; Si se ha pasado, se deja a cero
	ld (de),a			;526a
	ld b,0d1h		;526b   ; 0xD1 es el tile que se planta arriba y cuatro filas mas abajo
	dec l			;526d
PLANTA_LAS_DOS_PIEZAS:
	ld (hl),b			;526e   ; 0xD1 es el tile que se planta
	ld a,004h		;526f
	add a,l			;5271   ; Y cuatro filas mas abajo, otro
	ld l,a			;5272
	ld (hl),b			;5273
	ret			;5274
SUBMODO_2_Y_6:		; Mueve la llama del motor y luego lo que vuela; le toca dos veces de cada ocho
	call MUEVE_LA_LLAMA		;5275
SUBMODO_4:		; La entrada del submodo 4, tres instrucciones mas adentro: mueve lo que vuela SIN tocar la llama del motor. Es la unica entrada de la tabla de 0x516F que no cae en el principio de una rutina
	ld hl,0e7e4h		;5278
	ld b,004h		;527b
	ld a,(0e053h)		;527d
	and 003h		;5280
	ld b,004h		;5282   ; Estas dos instrucciones repiten las dos de 0x5278: B ya valia 4 y HL ya valia 0xE7E4, y en medio solo hay lecturas. Cinco bytes que no cambian nada, se entre por donde se entre
	ld hl,0e7e4h		;5284
	jp z,MUEVE_LAS_FICHAS		;5287   ; Zona de clase 0: por 0x58E6
	dec a			;528a
	jp nz,MUEVE_LAS_FICHAS_2		;528b   ; Clase 1: por 0x593A; las demas, por 0x59BB
	jp MUEVE_LAS_FICHAS_1		;528e
SUBMODO_3_COMBUSTIBLE:		; Gasta combustible y, al acabarse, suelta la nave
	ld a,(0e053h)		;5291
	cp 003h		;5294
	call nc,SUELTA_DE_LAS_ZONAS_ALTAS		;5296   ; De la fase 3 en adelante hay ademas lo que monta 0x5851
	ld a,(0e058h)		;5299   ; Con 0xE058 puesto no se gasta: la partida esta detenida
	or a			;529c
	ret nz			;529d
	ld a,(0e003h)		;529e   ; Los bits 2 a 5 del contador de fotogramas a cero: una vez cada 64
	and 03ch		;52a1
	ret nz			;52a3
	ld hl,0e51ch		;52a4   ; 0xE51C es el combustible que queda
	dec (hl)			;52a7
	jp p,Y_A_PINTAR_LA_BARRA		;52a8   ; Si el `dec` no ha pasado de cero, no hay nada mas que hacer
	inc (hl)			;52ab   ; Se devuelve el byte a cero -no se deja en 0xFF- y...
	ld a,001h		;52ac   ; ...0xE560 a 1, que en 0x5185 es lo que hace bajar la nave sola
	ld (0e560h),a		;52ae
Y_A_PINTAR_LA_BARRA:
	jp PINTA_COMBUSTIBLE		;52b1
SUBMODO_5_DISPAROS:		; Suelta lo que dispara el decorado
	ld a,(0e058h)		;52b4
	or a			;52b7   ; Con la partida detenida, nada
	jr nz,REHACE_LAS_FICHAS		;52b8
	ld a,(0e003h)		;52ba
	and 03ah		;52bd   ; Tres bits del contador: no en todos los fotogramas que le tocan
	jr nz,REHACE_LAS_FICHAS		;52bf
	call MUEVE_LAS_ESTRELLAS		;52c1
	ld de,00010h		;52c4
	call SUMA_PUNTOS		;52c7
REHACE_LAS_FICHAS:
	jp MONTA_SPRITES_DE_ZONA		;52ca
SUBMODO_7_DIFICULTAD:		; Lo que sale a por la nave, y cada vez antes
	call PUNTOS_ACUMULADOS		;52cd
	ld hl,00000h		;52d0
	ld (0e55bh),hl		;52d3   ; 0xE55B a cero
	ld a,(0e003h)		;52d6
	and 018h		;52d9   ; Dos bits del contador de fotogramas: el reloj de esta comprobacion
	ld b,a			;52db
	ld a,(0e053h)		;52dc   ; De la fase 3 en adelante la cuenta sube; antes de la 3, es cero
	sub 003h		;52df
	jr nc,TOPE_DE_DIFICULTAD		;52e1
	xor a			;52e3
TOPE_DE_DIFICULTAD:
	cp 00ch		;52e4   ; Y de la fase 15 no pasa: 0x0C es el tope de la dificultad
	jr c,EL_DOBLE_CONTRA_EL_RELOJ		;52e6
	ld a,00ch		;52e8
EL_DOBLE_CONTRA_EL_RELOJ:
	add a,a			;52ea   ; El doble de eso contra el reloj: cuanto mas avanzada la fase, mas veces sale
	cp b			;52eb
	ret c			;52ec
	ld hl,(0e7d0h)		;52ed
	ld de,03a40h		;52f0
	ld c,0b0h		;52f3
	ld a,(0e053h)		;52f5   ; Y otra vez la clase de zona reparte el trabajo entre tres rutinas
	and 003h		;52f8
	jp z,SUELTA_EN_ZONA_0		;52fa
	cp 002h		;52fd
	jp nc,SUELTA_EN_ZONA_2		;52ff
	jp MUEVE_LO_DE_ZONA_1		;5302

; ----------------------------------------------------------------------
; El submodo 1: el gemelo del submodo 0 para la mitad de arriba
; ----------------------------------------------------------------------
SUBMODO_1_TECHO:		; Lo mismo que el submodo 0, pero con el par de buffers de arriba (0xEC00/0xEE00) sobre la VRAM 0x3820
	ld hl,0e054h		;5305   ; 0xE054 manda aqui, y en esta version no lo enciende nadie: en los 8192 bytes no hay ni un `ld (0E054h),a`, y el unico sitio que puede escribirlo es el `ld (hl),a` de 0x530D, tres instrucciones mas abajo del `ret z`
	xor a			;5308
	cp (hl)			;5309
	ret z			;530a   ; Con 0xE054 a cero se vuelve por aqui, que es lo que pasa siempre en esta version
	inc a			;530b
	cp (hl)			;530c
	ld (hl),a			;530d
	ret nz			;530e
	ld a,(0e50dh)		;530f   ; Y esto es lo que no llega a hacerse: 0xE50D elige pagina, 0xEC00 o 0xEE00
	add a,a			;5312
	add a,0ech		;5313   ; 0xEC00 o 0xEE00, que MONTA_EL_MAPA si monta (0x4147 y 0x4162)
	ld h,a			;5315
	ld l,000h		;5316
	ld de,03820h		;5318   ; 0xA0 bytes a la VRAM 0x3820, la mitad de ARRIBA de la pantalla; el submodo 0 vuelca el otro par de buffers a 0x3A00, la de abajo
	ld b,0a0h		;531b
	call COPIA_A_VRAM		;531d
	ld c,0ech		;5320
CORRE_EL_BUFFER:
	ld a,(0e50dh)		;5322   ; La misma pagina otra vez, ahora como origen y como destino
	add a,a			;5325
	add a,c			;5326
	ld d,a			;5327
	ld e,000h		;5328
	ld h,a			;532a
	ld l,001h		;532b
	ld a,005h		;532d   ; Cinco filas, y entre una y otra 0x1F bytes
CORRE_UNA_FILA:
	ld bc,0001fh		;532f   ; Cinco tandas de 0x1F bytes, cada una corrida un sitio: asi se desplaza el decorado entero una columna
	ldir		;5332
	inc l			;5334
	inc e			;5335
	dec a			;5336
	jr nz,CORRE_UNA_FILA		;5337
	ld e,01fh		;5339
	ld hl,(0e50bh)		;533b   ; 0xE50B es lo que falta para llegar a la base
	ld b,d			;533e
	add hl,bc			;533f
	ex de,hl			;5340
	ld b,005h		;5341   ; Cinco filas, y entre fila y fila 0x20 bytes: una columna de arriba abajo
METE_LA_COLUMNA_NUEVA:
	ld a,(de)			;5343   ; Cinco filas de decorado, una detras de otra
	ld (hl),a			;5344
	inc de			;5345
	ld a,l			;5346
	add a,020h		;5347   ; 0x20 bytes de una fila a la de abajo
	ld l,a			;5349
	djnz METE_LA_COLUMNA_NUEVA		;534a
	ld a,d			;534c   ; La resta deja en D cuanto se ha movido
	sub h			;534d
	ld d,a			;534e
	bit 1,h		;534f
	ret nz			;5351
	bit 2,h		;5352
	jr nz,MIRA_SI_SE_ACABA_LA_ZONA		;5354
	ld a,(0e054h)		;5356   ; Y aqui se corta si hay techo: la cuenta de columnas que queda para el final de la zona la lleva el submodo 0, no los dos
	or a			;5359
	ret nz			;535a
MIRA_SI_SE_ACABA_LA_ZONA:
	ld hl,0e058h		;535b
	xor a			;535e
	cp (hl)			;535f
	jr z,PREPARA_LA_ZONA		;5360
	dec hl			;5362   ; Una columna menos para la base
	dec (hl)			;5363
	ld a,(hl)			;5364
	cp 027h		;5365   ; Pasado el 0x27 se enciende 0xE55E
	ld a,000h		;5367
	jr c,MARCA_EL_TRAMO_FINAL		;5369
	inc a			;536b
MARCA_EL_TRAMO_FINAL:
	ld (0e55eh),a		;536c   ; 0xE55E marca que la nave ha llegado al tramo final
	ld a,(0e053h)		;536f
	and 003h		;5372
	cp 003h		;5374
	jr z,ZONA_SUPERADA		;5376
	ld a,(hl)			;5378   ; A falta de 0x12 columnas suena el aviso de llegada
	cp 012h		;5379   ; Y a falta de 0x12 columnas suena el aviso de que se llega
	exx			;537b
	push af			;537c
	ld a,08bh		;537d
	call z,SUENA_ESTO		;537f
	pop af			;5382
	jr nc,ZONA_SUPERADA		;5383
	call PINTA_LA_ZONA		;5385   ; Y mas cerca todavia, lo de 0x5078
ZONA_SUPERADA:
	exx			;5388

; ----------------------------------------------------------------------
; Zona superada: sube el numero, cambia el decorado y paga
; ----------------------------------------------------------------------
	ld a,(hl)			;5389   ; Llegado a cero, la zona esta superada
	or a			;538a
	ret nz			;538b
	inc hl			;538c
	ld (hl),a			;538d   ; Se apaga lo que quedara pendiente
	ld (0e55eh),a		;538e
	exx			;5391
	ld c,a			;5392
	inc a			;5393
	ld (0e54fh),a		;5394   ; 0xE54F a uno: hay que rehacer las fichas de sprite de la zona nueva
	ld hl,0e051h		;5397   ; 0xE051 es el numero de zona que se PINTA, y va en BCD
	ld a,(hl)			;539a
	add a,001h		;539b
	daa			;539d
	ld (hl),a			;539e
	inc hl			;539f
	inc hl			;53a0
	inc (hl)			;53a1   ; 0xE053 es el numero de verdad, que no se pinta y sirve de indice
	ld a,(hl)			;53a2
	inc hl			;53a3
	sub 002h		;53a4   ; Menos dos y los dos bits bajos: cada cuatro zonas el ciclo vuelve a empezar
	and 003h		;53a6
	jr nz,CADA_CUATRO_ZONAS		;53a8
	ld c,002h		;53aa
CADA_CUATRO_ZONAS:
	ld (hl),c			;53ac
	ld bc,00200h		;53ad   ; 0x200 bytes de VRAM limpios antes del decorado nuevo
	call BORRA_LA_TABLA_DE_NOMBRES		;53b0
	call PINTA_EL_MARCADOR		;53b3   ; El marcador otra vez
	ld de,01500h		;53b6   ; Y 1500 puntos por haber pasado la zona
	call SUMA_ESTE_PREMIO		;53b9
	exx			;53bc
	jp SUBE_LOS_REGISTROS_DEL_VDP		;53bd   ; Y los registros del VDP, que el decorado nuevo puede cambiarlos
PREPARA_LA_ZONA:		; Deja la longitud de la zona nueva y su cuenta atras
	ld a,d			;53c0
	cp 002h		;53c1
	jr nz,GUARDA_LA_LONGITUD		;53c3
	ld de,000b6h		;53c5   ; 0xB6 columnas de largo tiene la zona
	dec hl			;53c8
	dec hl			;53c9
	dec (hl)			;53ca   ; Y cada tres zonas se reponen los 0x28
	jr nz,GUARDA_LA_LONGITUD		;53cb
	ld (hl),003h		;53cd
	inc hl			;53cf
	ld (hl),028h		;53d0
	inc hl			;53d2
	ld (hl),001h		;53d3
	ld e,0b6h		;53d5
GUARDA_LA_LONGITUD:
	ld (0e50bh),de		;53d7
	ret			;53db

; ----------------------------------------------------------------------
; Chocar es que dos rectangulos se pisen en los dos ejes
; ----------------------------------------------------------------------
HAY_CHOQUE:		; Con carry, B,C y D,E se estan pisando; los tamanos, en (HL)
	ld a,b			;53dc   ; Se resta la posicion del otro y el ancho, y se le suma el ancho propio: si eso no se desborda, en este eje no se tocan y no hay nada mas que mirar
	sub d			;53dd
	sub (hl)			;53de
	inc hl			;53df
	add a,(hl)			;53e0
	ret nc			;53e1
	ld a,c			;53e2   ; Y lo mismo en el otro eje: solo hay choque si se pisan en los dos
	sub e			;53e3
	inc hl			;53e4
	sub (hl)			;53e5
	inc hl			;53e6
	add a,(hl)			;53e7
	ret			;53e8
CHOQUE_CON_LO_QUE_VUELA:		; La nave contra las fichas de 0xE7D8
	ld hl,0e7d8h		;53e9
LEE_LA_FICHA:
	ld e,(hl)			;53ec   ; Cada ficha son dos bytes de posicion
	inc hl			;53ed
	ld d,(hl)			;53ee
	inc hl			;53ef
	ld a,d			;53f0
	cp 098h		;53f1   ; De 0x98 para arriba la ficha esta fuera de la pantalla
	jr nc,SIGUIENTE_FICHA		;53f3
	push hl			;53f5
	ld bc,(0e7d0h)		;53f6
	ld hl,05607h		;53fa   ; Los tamanos salen de 0x5607, cuatro bytes por clase de zona
	ld a,(0e053h)		;53fd
	and 003h		;5400
	add a,a			;5402
	add a,a			;5403
	call HL_MAS_A		;5404
	call HAY_CHOQUE		;5407
	pop hl			;540a
	jr c,LA_FICHA_REVIENTA		;540b
SIGUIENTE_FICHA:
	ld a,l			;540d
	cp 0e6h		;540e   ; 0xE6 es el final de la lista de fichas
	ret z			;5410
	inc hl			;5411
	inc hl			;5412
	jr LEE_LA_FICHA		;5413
LA_FICHA_REVIENTA:
	ld (hl),000h		;5415   ; Hay choque: la ficha se pone en el dibujo 0x0D, el de reventar
	inc hl			;5417
	ld (hl),00dh		;5418
	ld hl,0e7d8h		;541a
	ld de,03b08h		;541d
	ld b,010h		;5420
	call COPIA_A_VRAM		;5422
	scf			;5425   ; Y el carry es lo que avisa al que llamo
	ret			;5426
CHOQUE_CON_LO_QUE_DISPARAN:		; La nave contra las cuatro fichas de 0xE551
	ld hl,0e551h		;5427
	ld b,004h		;542a
MIRA_ESTE_DISPARO:
	ld a,(hl)			;542c
	cp 038h		;542d   ; Por debajo de la fila 0x38 la ficha no cuenta
	jr c,SIGUIENTE_DISPARO		;542f
	push hl			;5431
	ld d,a			;5432   ; Los dos bytes del disparo
	dec hl			;5433
	ld e,(hl)			;5434
	ld hl,(0e7d0h)		;5435   ; Y la posicion de la nave
	ex de,hl			;5438
	call POSICION_A_PIXEL		;5439   ; 0x4F08 esta dentro de POSICION_A_PATRON: pasa a pixeles
	ld a,l			;543c
	sub e			;543d
	sub 010h		;543e   ; Los margenes: 0x10 y 0x0C de ancho, 0x0E y 0x11 de alto
	add a,00ch		;5440
	jr nc,NO_HA_CHOCADO		;5442
	add a,00eh		;5444
	ld c,a			;5446   ; Se guarda el margen del primer eje
	ld a,h			;5447
	sub d			;5448
	sub c			;5449
	add a,011h		;544a   ; Y se mira el otro
	jr nc,NO_HA_CHOCADO		;544c
	pop hl			;544e
	ret			;544f
NO_HA_CHOCADO:
	pop hl			;5450
SIGUIENTE_DISPARO:
	inc hl			;5451   ; Dos bytes por disparo
	inc hl			;5452
	djnz MIRA_ESTE_DISPARO		;5453
	or a			;5455   ; Sin carry: no ha chocado con ninguna
	ret			;5456
CHOQUE_CON_EL_DECORADO:		; La nave contra el terreno, leyendo los tiles de la VRAM
	ld hl,(0e7d0h)		;5457
	exx			;545a
	ld de,08683h		;545b   ; Dos parejas de tiles con las que se choca, y su lista
	ld bc,05629h		;545e
	exx			;5461
	ld a,(0e054h)		;5462   ; Con techo y por encima de la fila 0x28 se mira la pagina 0xEC -la del techo- y la otra lista de formas, la de seis tiles: la nave puede chocar por ARRIBA
	or a			;5465
	ld a,l			;5466
	jr z,MEDIA_CASILLA_MAS		;5467
	cp 028h		;5469
	jr nc,MEDIA_CASILLA_MAS		;546b
	ld b,0ech		;546d
	exx			;546f
	dec d			;5470
	dec e			;5471
	ld bc,05617h		;5472
	exx			;5475
MEDIA_CASILLA_MAS:
	ld a,008h		;5476
	add a,l			;5478
	ld l,a			;5479
	call POSICION_A_NOMBRE		;547a   ; Se pasa la posicion de la nave a casilla de la tabla de nombres
	ex de,hl			;547d
	ld c,002h		;547e
	ld hl,0e520h		;5480   ; 0xE520 guarda las ocho casillas que rodean a la nave: cuatro de ancho por dos de alto, leidas de la VRAM una a una
LEE_CUATRO_CASILLAS:
	ld b,004h		;5483
LEE_UNA_CASILLA:
	call VPEEK		;5485
	ld (hl),a			;5488
	inc hl			;5489
	inc de			;548a
	djnz LEE_UNA_CASILLA		;548b
	ld a,01ch		;548d   ; 0x1C es lo que hay que sumar para bajar a la fila siguiente
	call DE_MAS_A		;548f
	dec c			;5492
	jr nz,LEE_CUATRO_CASILLAS		;5493
	xor a			;5495
	ld (0e524h),a		;5496
	ld hl,(0e7d0h)		;5499
	ld a,h			;549c
	cp 008h		;549d   ; Por delante de la columna 8 no se mira el decorado
	jr nc,REDONDEA_A_CASILLA		;549f
	xor a			;54a1
	ld (0e520h),a		;54a2
	ld (0e524h),a		;54a5
REDONDEA_A_CASILLA:
	ld b,h			;54a8   ; La posicion de la nave redondeada a casilla, que es como se compara
	ld c,l			;54a9
	ld a,l			;54aa   ; La posicion redondeada a casilla, que es como se compara
	and 0f8h		;54ab   ; Los tres bits bajos fuera: eso es el pixel dentro de la casilla
	add a,008h		;54ad
	ld e,a			;54af
	ld a,h			;54b0
	and 0f8h		;54b1
	ld d,a			;54b3
	exx			;54b4
	ld hl,0e520h		;54b5
MIRA_LA_PRIMERA:
	ld a,(hl)			;54b8   ; Y se empieza por la primera de las ocho casillas leidas
	cp 080h		;54b9
	jr c,AVANZA_EN_LA_LISTA		;54bb
	jp z,LA_NAVE_HA_TOCADO		;54bd
MIRA_LA_CASILLA:		; Un tile del decorado contra la nave
	cp d			;54c0   ; Los dos tiles de la pareja que le paso el llamador
	jr z,AVANZA_EN_LA_LISTA		;54c1
	cp e			;54c3   ; Y con el otro de la pareja
	jr z,AVANZA_EN_LA_LISTA		;54c4
	cp 087h		;54c6   ; 0x87 es el tile lleno: contra ese siempre se choca
	jr z,AVANZA_EN_LA_LISTA		;54c8
	jr nc,MIRA_CASILLA_GRANDE		;54ca   ; Por encima del 0x87 son los tiles grandes, que van por otro sitio
	sub 081h		;54cc   ; Del 0x81 en adelante, y por tres: cada tile tiene tres bytes de forma
	push bc			;54ce
	exx			;54cf
	ld l,a			;54d0
	add a,a			;54d1
	add a,l			;54d2
	pop hl			;54d3
	call HL_MAS_A		;54d4   ; La entrada de la tabla de formas
	ld a,c			;54d7   ; Se resta la posicion y se le suma el margen del tile; sin desbordarse, por ahi no se toca
	sub e			;54d8
	add a,(hl)			;54d9
	jr nc,SIGUIENTE_CASILLA		;54da
	ld a,b			;54dc   ; En este eje no se tocan
	sub (hl)			;54dd
	inc hl			;54de
	add a,(hl)			;54df
	ret c			;54e0
SIGUIENTE_CASILLA:
	exx			;54e1
AVANZA_EN_LA_LISTA:
	inc hl			;54e2
	ld a,l			;54e3
	exx			;54e4
	cp 028h		;54e5   ; 0x28 casillas recorridas: se acabo
	ret z			;54e7
	cp 024h		;54e8   ; 0x24 casillas: el ancho que se mira
	jr z,BAJA_UNA_FILA		;54ea
	ld a,d			;54ec   ; Se baja ocho pixeles y se sigue por la casilla de al lado
	add a,008h		;54ed
	ld d,a			;54ef
	exx			;54f0
	jr MIRA_LA_PRIMERA		;54f1
BAJA_UNA_FILA:
	ld a,e			;54f3   ; Ocho pixeles a un lado y 0x18 al otro: la casilla de la fila de abajo
	add a,008h		;54f4
	ld e,a			;54f6
	ld a,d			;54f7
	sub 018h		;54f8
	ld d,a			;54fa
	exx			;54fb   ; Y a mirar esa
	jr MIRA_LA_PRIMERA		;54fc
MIRA_CASILLA_GRANDE:		; Los tiles del 0x87 para arriba, que ocupan mas de una casilla
	exx			;54fe
	push de			;54ff
	ld l,a			;5500
	bit 0,l		;5501   ; El bit 0 del tile corre el margen ocho pixeles a un lado...
	jr z,MEDIO_TILE_A_UN_LADO		;5503
	ld a,e			;5505   ; Ocho pixeles a un lado
	sub 008h		;5506
	ld e,a			;5508
MEDIO_TILE_A_UN_LADO:
	ld a,d			;5509
	bit 1,l		;550a   ; ...el bit 1, ocho por el otro...
	jr z,MEDIO_TILE_DE_VUELTA		;550c
	sub 008h		;550e   ; Y ocho por el otro
	ld d,a			;5510
MEDIO_TILE_DE_VUELTA:
	bit 3,l		;5511   ; ...y el bit 3, cuatro de vuelta
	jr z,LOS_MARGENES_DEL_TILE		;5513
	add a,004h		;5515   ; O cuatro de vuelta
	ld d,a			;5517
LOS_MARGENES_DEL_TILE:
	ld a,l			;5518
	push hl			;5519
	ld hl,05634h		;551a   ; La tabla de 0x5634, de cuatro en cuatro
	rra			;551d
	rra			;551e
	and 01ch		;551f
	call HL_MAS_A		;5521   ; La entrada de la tabla
	call HAY_CHOQUE		;5524   ; Y la prueba de siempre
	pop hl			;5527
	pop de			;5528
	jr nc,SIGUIENTE_CASILLA		;5529
	ld a,001h		;552b   ; 0xE51D a uno: la nave ha tocado el terreno
	ld (0e51dh),a		;552d   ; 0xE51D a uno: la nave ha tocado
	ex de,hl			;5530
	push hl			;5531
	call POSICION_A_NOMBRE		;5532   ; De la posicion sale la casilla
	ld a,e			;5535
	push af			;5536
	call ABRE_BOQUETE		;5537   ; Y con eso se enciende la explosion
	pop af			;553a
	pop hl			;553b
	call COLOCA_EXPLOSION		;553c   ; Y las fichas suben a la pantalla
	call VUELCA_LAS_EXPLOSIONES		;553f
LA_NAVE_HA_TOCADO:
	scf			;5542
	ret			;5543
CHOQUE_DEL_DISPARO:		; El disparo de la nave contra lo que vuela
	ld a,l			;5544
	and 01fh		;5545   ; Los cinco bits bajos por ocho: la casilla en pixeles
	rlca			;5547
	rlca			;5548
	rlca			;5549
	ld b,a			;554a
	inc de			;554b
	ld a,(de)			;554c
	ld c,a			;554d
	ld hl,0e7d8h		;554e
MIRA_ESTA_FICHA:
	push hl			;5551
	ld a,0d1h		;5552   ; 0xD1 es la ficha apagada: ahi se acaba la lista
	cp (hl)			;5554
	jr z,LA_SIGUIENTE_FICHA		;5555
	ld e,(hl)			;5557
	inc hl			;5558
	ld d,(hl)			;5559
	inc hl			;555a
	ld a,(hl)			;555b
	exx			;555c
	ld c,a			;555d
	exx			;555e
	ld hl,055f3h		;555f   ; Los margenes salen de 0x55F3, segun el dibujo de la ficha
	call HL_MAS_A		;5562
	call HAY_CHOQUE		;5565
	exx			;5568
	ld a,c			;5569
	exx			;556a
	jp c,REVIENTA_LO_TOCADO		;556b   ; Con carry, tocado
LA_SIGUIENTE_FICHA:
	pop hl			;556e
	ld a,004h		;556f
	add a,l			;5571
	cp 0e8h		;5572   ; De cuatro en cuatro hasta la 0xE8: diez fichas
	ret z			;5574
	ld l,a			;5575
	jr MIRA_ESTA_FICHA		;5576
CHOQUE_DE_LA_BOMBA:		; La bomba de 0xE7E8 contra lo que vuela
	ld bc,(0e7e8h)		;5578
	ld hl,0e7d8h		;557c
MIRA_ESTA_CON_LA_BOMBA:
	push hl			;557f   ; Se guarda el principio de la lista para poder volver
	ld a,0d1h		;5580
	cp (hl)			;5582
	jr z,LA_SIGUIENTE_CON_LA_BOMBA		;5583
	ld e,(hl)			;5585   ; Los dos bytes de posicion de la ficha
	inc hl			;5586
	ld d,(hl)			;5587
	inc hl			;5588
	ld a,(hl)			;5589
	exx			;558a
	ld c,a			;558b
	exx			;558c
	ld hl,055e3h		;558d   ; Los mismos margenes, pero los de 0x55E3
	call HL_MAS_A		;5590   ; Y los margenes, segun el dibujo que lleve
	call HAY_CHOQUE		;5593
	exx			;5596
	ld a,c			;5597
	exx			;5598
	jp c,REVIENTA_LO_TOCADO		;5599
LA_SIGUIENTE_CON_LA_BOMBA:
	pop hl			;559c   ; Cuatro bytes por ficha, hasta la 0xE8
	ld a,004h		;559d
	add a,l			;559f
	cp 0e8h		;55a0
	ret z			;55a2
	ld l,a			;55a3
	jr MIRA_ESTA_CON_LA_BOMBA		;55a4
CHOQUE_CON_LA_BASE:		; La bomba contra el deposito de 0xE7C8
	ld bc,(0e7e8h)		;55a6
	ld de,(0e7c8h)		;55aa
	ld hl,0564ch		;55ae
	call HAY_CHOQUE		;55b1
	ret nc			;55b4
	xor a			;55b5
	ld (0e54ah),a		;55b6   ; 0xE54A y 0xE54B a cero
	ld (0e54bh),a		;55b9
	ld hl,(0e7c8h)		;55bc
	call PONE_EXPLOSION		;55bf
	ld a,0d1h		;55c2   ; Y las dos fichas del deposito se apagan con el dibujo 0xD1
	ld (0e7c8h),a		;55c4
	ld (0e7cch),a		;55c7
	ld hl,0e7c8h		;55ca
	ld de,03b30h		;55cd
	ld b,008h		;55d0
	call COPIA_A_VRAM		;55d2
	scf			;55d5
	ret			;55d6

; ----------------------------------------------------------------------
; DATOS margenes_de_la_bomba (tramo): Los cuatro bytes por familia de tile con
;   los que 0x5B29 llama a HAY_CHOQUE; el indice es el nibble alto del tile y
;   siete. Como las tablas de 0x566B y 0x58D6, arranca DENTRO del codigo: sus
;   cuatro primeros bytes son los del `call 0x4C93` y el `scf`/`ret` de
;   0x55D2, asi que la familia 0 no puede leerla de verdad.
;   0x55d7..0x55e3  (12 bytes)  de 0x55d3..0x55e3 (16 bytes)
DATA_55D3_55D7:
	defb 00ch,010h,00ch,00bh	; 55d7
	defb 00eh,012h,00bh,00fh	; 55db
	defb 003h,00bh,00bh,00dh	; 55df

; ----------------------------------------------------------------------
; DATOS margenes_de_la_bomba: Los margenes con los que CHOQUE_DE_LA_BOMBA
;   llama a HAY_CHOQUE, indexados por el dibujo de la ficha (0x558D).
;   0x55e3..0x55f3  (16 bytes)
DATA_55E3:
	defb 006h,00bh,008h,00eh,005h,00bh,00ch,009h,00eh,013h,00ch,00bh,006h,00bh,008h,00eh	; 55e3  ................

; ----------------------------------------------------------------------
; DATOS margenes_del_disparo: Los margenes con los que CHOQUE_DEL_DISPARO
;   llama a HAY_CHOQUE, indexados por el dibujo de la ficha (0x555F).
;   0x55f3..0x5607  (20 bytes)
DATA_margenes_del_disparo:
	defb 003h,00bh,00bh,00dh,006h,00eh,011h,009h,00eh,014h,011h,00bh,010h,020h,00dh,00dh	; 55f3  ............. ..
	defb 010h,020h,010h,00ch	; 5603

; ----------------------------------------------------------------------
; DATOS margenes_de_lo_que_vuela: Los rectangulos con los que 0x53E9 llama a
;   HAY_CHOQUE: cuatro bytes por clase de zona, y el indice es (0xE053) and 3
;   por cuatro.
;   0x5607..0x5617  (16 bytes)
DATA_margenes_de_lo_que_vuela:
	defb 001h,015h,006h,00bh	; 5607
	defb 00ch,020h,006h,00dh	; 560b
	defb 006h,01ah,003h,00fh	; 560f
	defb 004h,019h,005h,010h	; 5613

; ----------------------------------------------------------------------
; DATOS formas_de_tile_del_techo: Seis tiles de tres bytes, del 0x81 al 0x86:
;   por donde se pasa por cada saliente del techo. Las lee 0x5472, o sea la
;   rama de 0xE054.
;   0x5617..0x5629  (18 bytes)
DATA_formas_de_tile_del_techo:
	defb 008h,001h,00fh	; 5617
	defb 000h,000h,000h	; 561a
	defb 008h,004h,012h	; 561d
	defb 008h,008h,012h	; 5620
	defb 000h,000h,000h	; 5623
	defb 008h,008h,014h	; 5626

; ----------------------------------------------------------------------
; DATOS formas_de_tile_del_suelo: Tres tiles de tres bytes, del 0x81 al 0x83:
;   la forma de las cuestas del suelo, que es lo unico contra lo que se choca
;   en el juego publicado (0x545E).
;   0x5629..0x5632  (9 bytes)
DATA_formas_de_tile_del_suelo:
	defb 00ch,008h,012h	; 5629
	defb 00ch,008h,014h	; 562c
	defb 000h,000h,000h	; 562f

; ----------------------------------------------------------------------
; DATOS dos_bytes_sin_dueno_5632: `0C 00`, entre las formas del suelo (tres
;   tiles de tres bytes) y las de los tiles grandes (cinco de cuatro). No hay
;   en toda la ROM ningun `ld hl,05632h` ni nada que caiga aqui, y no encajan
;   ni con las filas de tres de arriba ni con las de cuatro de abajo. Ver la
;   pagina de preguntas abiertas.
;   0x5632..0x5634  (2 bytes)
DATA_dos_bytes_sin_dueno_5632:
	defb 00ch,000h	; 5632

; ----------------------------------------------------------------------
; DATOS formas_de_tile_grande: Los margenes de los tiles del 0x87 para arriba,
;   de cuatro en cuatro (0x551A).
;   0x5634..0x5648  (20 bytes)
DATA_formas_de_tile_grande:
	defb 00eh,00ch,002h,010h	; 5634
	defb 00bh,01fh,008h,00fh	; 5638
	defb 00dh,020h,008h,014h	; 563c
	defb 004h,019h,007h,012h	; 5640
	defb 006h,01ah,005h,011h	; 5644

; ----------------------------------------------------------------------
; DATOS margenes_del_deposito: Los cuatro bytes con los que MIRA_SI_ATERRIZA
;   (0x50A7) llama a HAY_CHOQUE: el rectangulo del deposito del final de zona,
;   sobre el que la nave aterriza.
;   0x5648..0x564c  (4 bytes)
DATA_margenes_del_deposito:
	defb 00eh,006h,00ch,006h	; 5648

; ----------------------------------------------------------------------
; DATOS margenes_de_la_base: Los cuatro bytes con los que CHOQUE_CON_LA_BASE
;   llama a HAY_CHOQUE (0x55AE).
;   0x564c..0x5650  (4 bytes)
DATA_margenes_de_la_base:
	defb 00bh,011h,00ch,00eh	; 564c

; ======================================================================
; CODIGO 0x5650..0x566d  (29 bytes)
; ======================================================================


REVIENTA_LO_TOCADO:		; Apaga la ficha, coloca la explosion y paga cien puntos
	pop hl			;5650
	ld (hl),0d1h		;5651   ; 0xD1 apaga la ficha que se acaba de tocar
	ld hl,0566bh		;5653   ; La tabla de 0x566B dice cuanto se corre la explosion respecto a la ficha
	rrca			;5656
	call HL_MAS_A		;5657
	ld a,(hl)			;565a
	inc hl			;565b
	ld b,(hl)			;565c
	add a,e			;565d
	ld l,a			;565e
	ld a,d			;565f
	sub b			;5660
	ld h,a			;5661
	exx			;5662
	ld de,00100h		;5663   ; Cien puntos por lo que se acaba de reventar
	call SUMA_ESTE_PREMIO		;5666
	exx			;5669
	jp PONE_EXPLOSION		;566a   ; Y este `jp` es la ultima instruccion del bloque: sus dos bytes de operando son ya los dos primeros de la tabla de arriba

; ----------------------------------------------------------------------
; DATOS desplazamientos_de_la_explosion (tramo): Pares (columna, fila) que
;   0x5653 suma a la ficha reventada para poner ahi la explosion; el indice
;   llega dividido por dos con un `rrca`. La tabla arranca en 0x566B, que son
;   los dos bytes del operando del `jp 0x5B85` de 0x566A: las dos primeras
;   entradas caen encima del propio codigo, asi que el indice nunca puede
;   valer 0 ni 1. Los diez bytes de 0x566D en adelante son los que se usan de
;   verdad.
;   0x566d..0x5675  (8 bytes)  de 0x566b..0x5675 (10 bytes)
DATA_desplazamientos_de_la_explosion_566D:
	defb 005h,005h	; 566d
	defb 004h,000h	; 566f
	defb 0feh,004h	; 5671
	defb 002h,005h	; 5673

; ======================================================================
; CODIGO 0x5675..0x58d8  (611 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; El boquete: una bomba se lleva un trozo de terreno
; ----------------------------------------------------------------------
ABRE_BOQUETE:		; Borra del buffer las casillas que se lleva la explosion y las sube a la VRAM
	cp 092h		;5675   ; Por debajo de 0x92 y por encima de 0xEF no hay terreno que romper
	ret c			;5677
	cp 0f0h		;5678
	ret nc			;567a
ABRE_BOQUETE_AQUI:
	push de			;567b
	ld d,a			;567c
	and 007h		;567d   ; Los tres bits bajos dicen si el boquete cae en media casilla
	rra			;567f
	ld c,a			;5680
	ld a,l			;5681
	jr nc,CORRE_MEDIA_CASILLA		;5682
	sub 020h		;5684
CORRE_MEDIA_CASILLA:
	sub c			;5686
	ld l,a			;5687
	push hl			;5688
	bit 1,h		;5689   ; El bit 1 de la fila elige la pagina del buffer: 0xE800 o esa mas 0x3E0
	ld h,0e8h		;568b
	jr nz,LIMPIA_LA_FILA		;568d
	ld bc,003e0h		;568f
	add hl,bc			;5692
LIMPIA_LA_FILA:
	push hl			;5693
	ld c,000h		;5694
	ld (hl),c			;5696   ; Dos casillas a cero
	inc hl			;5697
	ld (hl),c			;5698
	ld a,l			;5699
	add a,01eh		;569a   ; 0x1E mas abajo es la fila siguiente del buffer
	ld l,a			;569c
	ld b,(hl)			;569d
	inc hl			;569e
	ld (hl),c			;569f
	inc hl			;56a0
	ld (hl),c			;56a1
	inc hl			;56a2
	ld c,(hl)			;56a3
	bit 3,d		;56a4
	jr z,LA_FILA_DE_ABAJO		;56a6
	dec l			;56a8
LA_FILA_DE_ABAJO:
	inc h			;56a9
	inc h			;56aa
	ld a,d			;56ab
	cp 0b0h		;56ac   ; Por debajo de la fila 0xB0 no se toca el borde
	jr nc,LIMPIA_EN_MEDIO		;56ae
	xor a			;56b0
	cp c			;56b1
	jr z,PONE_LA_CUESTA		;56b2
	ld a,083h		;56b4   ; 0x83 y 0x86 son las cuestas: el borde del boquete no queda recto,
PONE_LA_CUESTA:
	ld (hl),a			;56b6
LIMPIA_EN_MEDIO:
	dec hl			;56b7
	xor a			;56b8
	ld (hl),a			;56b9
	dec hl			;56ba
	cp b			;56bb
	jr z,LA_OTRA_CUESTA		;56bc
	ld a,086h		;56be   ; se le pone la pieza que corresponde a cada lado
LA_OTRA_CUESTA:
	ld (hl),a			;56c0   ; 0x86 cierra el boquete por el otro lado
	ld a,l			;56c1
	sub 020h		;56c2   ; Y otra fila mas arriba, que tambien se limpia
	ld l,a			;56c4
	xor a			;56c5   ; La fila de encima tambien se limpia
	ld (hl),a			;56c6
	inc l			;56c7
	ld (hl),a			;56c8
	ld a,d			;56c9
	cp 0b0h		;56ca
	jr nc,EL_BOQUETE_A_LA_VRAM		;56cc
	inc l			;56ce   ; Y por debajo de la fila 0xB0 una casilla mas
	ld (hl),000h		;56cf
EL_BOQUETE_A_LA_VRAM:
	pop de			;56d1
	dec de			;56d2
	pop hl			;56d3
	set 6,h		;56d4   ; El bit 6 puesto en H: la direccion de la VRAM es de escritura
	bit 3,a		;56d6
	jr z,MANDA_LA_DIRECCION		;56d8
	inc d			;56da
	inc d			;56db
MANDA_LA_DIRECCION:
	push de			;56dc
	ld c,002h		;56dd
ESCRIBE_EN_LA_VRAM:
	di			;56df   ; Aqui se escribe en la VRAM a pelo, sin pasar por VPOKE: cuatro bytes seguidos por fila y dos filas, que es todo el boquete
	ld a,l			;56e0
	out (099h),a		;56e1
	ld a,h			;56e3
	out (099h),a		;56e4
	ld b,004h		;56e6
UN_BYTE_DEL_BOQUETE:
	ld a,(de)			;56e8
	out (098h),a		;56e9
	inc de			;56eb
	ld a,e			;56ec
	and 01fh		;56ed   ; Al llegar al final de la fila de la tabla de nombres se corta
	cp 01fh		;56ef
	jr z,LA_SEGUNDA_FILA_DEL_BOQUETE		;56f1
	djnz UN_BYTE_DEL_BOQUETE		;56f3
LA_SEGUNDA_FILA_DEL_BOQUETE:
	dec c			;56f5
	jr z,EL_BOQUETE_ESTA_HECHO		;56f6
	pop de			;56f8
	ld a,e			;56f9   ; 0x20 bytes mas: la fila de debajo
	add a,020h		;56fa
	ld e,a			;56fc
	ld a,020h		;56fd
	call HL_MAS_A		;56ff
	jr ESCRIBE_EN_LA_VRAM		;5702
EL_BOQUETE_ESTA_HECHO:
	res 6,h		;5704
	pop de			;5706
	or a			;5707
	ei			;5708
	ret			;5709
SUELTA_EN_ZONA_0:		; Lo que dispara el terreno en las zonas de clase 0
	push hl			;570a
	push de			;570b
	ld a,l			;570c
	cp 058h		;570d   ; Por debajo de la fila 0x58 se mira una cosa y por encima otra
	ld a,r		;570f   ; El registro R de dado: tres bits, y sobre 0x30
	and 038h		;5711
	add a,030h		;5713
	jr nc,APUNTA_A_LA_NAVE		;5715
	ld a,l			;5717
	jr nc,LA_SEGUNDA_TANDA		;5718
	add a,a			;571a
	ld c,a			;571b
	ld a,0b0h		;571c   ; 0xB0 menos el doble: se dispara hacia donde esta la nave
	sub c			;571e
APUNTA_A_LA_NAVE:
	add a,h			;571f
	ld h,a			;5720
	ld c,0b0h		;5721
	call BUSCA_EN_EL_TERRENO		;5723   ; 0x57F6 dice si en esa casilla hay de donde disparar
	jr nc,LA_SEGUNDA_TANDA		;5726
	ld c,002h		;5728
	call ARRANCA_UN_DISPARO		;572a
LA_SEGUNDA_TANDA:
	pop de			;572d
	pop hl			;572e
SUELTA_EN_ZONA_1:		; Lo mismo, con otro alcance, si la zona no es la primera
	push hl			;572f
	push de			;5730
	ld a,(0e053h)		;5731   ; En la zona 0 no dispara nadie: es la de aprender
	or a			;5734
	jr z,LA_TERCERA_TANDA		;5735
	ld c,0b0h		;5737
	ld a,050h		;5739   ; 0x50 menos la fila: cuanto se adelanta el disparo
	sub l			;573b
	ld b,a			;573c
	jr nc,ADELANTA_EL_DISPARO		;573d
	ld b,010h		;573f
ADELANTA_EL_DISPARO:
	ld a,h			;5741
	sub b			;5742
	jr nc,GUARDA_LA_COLUMNA		;5743
	ld a,010h		;5745
GUARDA_LA_COLUMNA:
	ld h,a			;5747
	call BUSCA_EN_EL_TERRENO		;5748
	jr nc,LA_TERCERA_TANDA		;574b
	ld c,001h		;574d   ; Con clase 1 el disparo es de otro tipo
	call ARRANCA_UN_DISPARO		;574f
LA_TERCERA_TANDA:
	pop de			;5752   ; Se recuperan la posicion y el destino
	pop hl			;5753
	ld a,(0e514h)		;5754   ; El bit 6 del contador de la fase: la tercera tanda no va siempre
	bit 6,a		;5757
	ret nz			;5759
	ld a,050h		;575a
	sub l			;575c
	jr c,POR_EL_OTRO_LADO		;575d
	add a,h			;575f   ; Hacia donde queda la nave respecto de la torre
	ld h,a			;5760
	jr BUSCA_DE_DONDE_SALE		;5761
POR_EL_OTRO_LADO:
	ld a,h			;5763
	cp 030h		;5764
	jr nc,BUSCA_DE_DONDE_SALE		;5766
	add a,098h		;5768   ; Pasada la columna 0x30 se le suman 0x98: se da la vuelta por el otro lado
	ld h,a			;576a
BUSCA_DE_DONDE_SALE:
	ld c,0b0h		;576b
	call BUSCA_EN_EL_TERRENO		;576d
	ret nc			;5770
	ld c,000h		;5771
ARRANCA_UN_DISPARO:		; Da de alta el disparo numero 0xE549 y lo hace sonar
	ld a,(0e549h)		;5773   ; 0xE549 es cual de los huecos toca
	ld b,a			;5776
	add a,03ch		;5777   ; 0x3C mas el hueco: donde se apunta de que clase es
	ld l,a			;5779
	ld h,0e5h		;577a
	ld (hl),c			;577c
	ld a,b			;577d
	add a,a			;577e   ; El doble mas 0x40: dos bytes por hueco para la posicion
	add a,040h		;577f
	ld l,a			;5781
	ld (hl),060h		;5782   ; 0x60 y 0xE6: donde arranca dentro del buffer
	inc hl			;5784
	ld (hl),0e6h		;5785
	ld a,004h		;5787   ; Y el sonido de que algo ha salido
	jp SUENA_ESTO		;5789
MUEVE_LO_DE_ZONA_1:		; Las cuatro fichas de 0xE7E4 en las zonas de clase 1
	ld a,(0e058h)		;578c
	or a			;578f   ; Con la partida detenida, nada
	ret nz			;5790
	ld hl,0e548h		;5791   ; 0xE548 cuenta hacia atras y se queda en cero, sin pasarse
	dec (hl)			;5794
	jp p,RECORRE_LAS_CUATRO		;5795
	inc (hl)			;5798
RECORRE_LAS_CUATRO:
	ld hl,0e7e4h		;5799   ; Las cuatro fichas de 0xE7E4 y sus cuatro cuentas de 0xE53B
	ld de,0e53bh		;579c
	ld b,004h		;579f
	ld a,(0e053h)		;57a1   ; En la zona 1 hay una ficha menos
	dec a			;57a4   ; En la zona 1 hay una ficha menos
	jr nz,BUSCA_UNA_LIBRE		;57a5
	dec b			;57a7
	dec de			;57a8
	ld a,l			;57a9   ; Cuatro bytes hacia atras por ficha
	sub 004h		;57aa
	ld l,a			;57ac
BUSCA_UNA_LIBRE:
	ld a,0d1h		;57ad   ; 0xD1 es la ficha libre: la primera que se encuentre se usa
	cp (hl)			;57af
	jr z,PONE_FICHA_AL_AZAR		;57b0
	ld a,l			;57b2
	sub 004h		;57b3
	ld l,a			;57b5
	dec de			;57b6
	djnz BUSCA_UNA_LIBRE		;57b7   ; Y si estan todas ocupadas, no sale nada
	ret			;57b9
PONE_FICHA_AL_AZAR:		; Coloca la ficha en una columna cualquiera
	ld a,r		;57ba   ; Seis bits del registro R: la columna donde aparece
	and 03fh		;57bc
	ld (hl),a			;57be
	inc hl			;57bf
	ld (hl),0fch		;57c0   ; 0xFC es la fila de salida, casi abajo del todo
	ld a,r		;57c2   ; Y un bit mas de R decide entre las dos clases
	and 001h		;57c4
	ld (de),a			;57c6
	ret			;57c7
SUELTA_EN_ZONA_2:		; Lo que sale en las zonas de clase 2 y siguientes
	ld hl,(0e7d0h)		;57c8
	jr nz,CUANTO_LLEVA_LA_FASE		;57cb
	ld de,03880h		;57cd   ; VRAM 0x3880, y 0xC0 es el nibble que se busca en el terreno
	ld c,0c0h		;57d0
CUANTO_LLEVA_LA_FASE:
	ld a,(0e514h)		;57d2   ; El contador de la fase, doblado: cuanto mas dura, mas lejos aparecen
	add a,a			;57d5
	cp 070h		;57d6
	jr c,COLUMNA_AL_AZAR		;57d8
	cp 0b0h		;57da
	jr c,GUARDA_LA_COLUMNA_2		;57dc
COLUMNA_AL_AZAR:
	ld a,r		;57de   ; Cuatro bits del registro R: la columna, en saltos de cuatro
	and 03ch		;57e0
	add a,h			;57e2
GUARDA_LA_COLUMNA_2:
	ld h,a			;57e3
	call BUSCA_EN_EL_TERRENO		;57e4
	ret nc			;57e7
	ld a,l			;57e8
	rrca			;57e9   ; Dos `rrca` y menos 0x82: de la fila sale el hueco de 0xE5xx
	rrca			;57ea
	sub 082h		;57eb
	ld l,a			;57ed
	ld h,0e5h		;57ee
	ld a,r		;57f0   ; Y un bit de R decide de que clase es
	and 001h		;57f2
	ld (hl),a			;57f4
	ret			;57f5

; ----------------------------------------------------------------------
; Buscar en el propio decorado de que sitios sale algo
; ----------------------------------------------------------------------
BUSCA_EN_EL_TERRENO:		; Mira dos casillas de la VRAM: con carry, ahi hay de donde salir
	ld b,002h		;57f6   ; Dos casillas, no mas
	ld a,h			;57f8   ; Tres `rra` y los cinco bits: la columna pasada a casilla
	rra			;57f9
	rra			;57fa
	rra			;57fb
	and 01fh		;57fc
	add a,e			;57fe
	ld e,a			;57ff
	ex de,hl			;5800
LEE_ESTA_CASILLA:
	call VPEEK_HL		;5801   ; Se lee el tile de la VRAM
	ld d,a			;5804
	and 0f0h		;5805   ; Solo importa el nibble alto: es la familia del tile
	cp c			;5807
	jr z,BUSCA_FICHA_LIBRE		;5808
	inc hl			;580a
	djnz LEE_ESTA_CASILLA		;580b
	or a			;580d   ; Sin carry: en esas dos casillas no hay nada
	ret			;580e
BUSCA_FICHA_LIBRE:		; El primer hueco libre de 0xE7D8, y con la zona 8 uno mas
	ld a,d			;580f
	push hl			;5810
	push af			;5811
	call POSICION_A_PATRON		;5812
	ex de,hl			;5815
	ld hl,0e7d8h		;5816
	ld b,003h		;5819   ; Tres fichas a la vez...
	ld a,(0e053h)		;581b
	cp 008h		;581e   ; De la zona 8 en adelante caben cuatro a la vez en vez de tres
	jr c,MIRA_SI_ESTA_LIBRE		;5820
	inc b			;5822
MIRA_SI_ESTA_LIBRE:
	ld a,0d1h		;5823   ; 0xD1 es el dibujo de la ficha libre
	cp (hl)			;5825
	jr z,DA_DE_ALTA_LA_FICHA		;5826
	ld a,004h		;5828
	add a,l			;582a
	ld l,a			;582b
	djnz MIRA_SI_ESTA_LIBRE		;582c
	pop af			;582e   ; Sin ninguna libre, se vuelve sin carry
	pop hl			;582f
	ret			;5830
DA_DE_ALTA_LA_FICHA:		; Pone la ficha en su sitio y le abre el hueco en el terreno
	ld a,l			;5831   ; Dos `rrca` y menos 0x36 dan el numero de hueco, que se guarda en 0xE549
	rrca			;5832
	rrca			;5833
	sub 036h		;5834
	ld (0e549h),a		;5836
	ld (hl),e			;5839
	inc hl			;583a
	ld (hl),d			;583b
	exx			;583c
	pop af			;583d
	pop hl			;583e
	call ABRE_BOQUETE_AQUI		;583f   ; 0x567B esta dentro de ABRE_BOQUETE: se lleva el trozo de terreno
	exx			;5842
	ld a,l			;5843   ; Menos 0xD1: de la direccion de la ficha sale su sitio en la VRAM 0x3B00
	sub 0d1h		;5844
	ld e,a			;5846
	ld d,03bh		;5847
	ld b,002h		;5849
	dec hl			;584b
	call COPIA_A_VRAM		;584c
	scf			;584f
	ret			;5850

; ----------------------------------------------------------------------
; Lo que dispara el terreno en las zonas altas
; ----------------------------------------------------------------------
SUELTA_DE_LAS_ZONAS_ALTAS:		; De la zona 3 en adelante, lo que sale de las torres
	ld a,(0e50dh)		;5851   ; Con 0xE50D a cero todavia no toca
	or a			;5854
	ret z			;5855
	ld a,(0e054h)		;5856
	ld c,a			;5859
	ld a,(0e053h)		;585a
	cp 010h		;585d   ; De la zona 16 en adelante ya no sube: el tope es 12
	jr c,CUANTOS_CABEN		;585f
	ld a,00ch		;5861
CUANTOS_CABEN:
	ld hl,058d6h		;5863   ; Cuantos pueden salir a la vez, segun la zona
	call HL_MAS_A		;5866
	ld b,(hl)			;5869
	ld a,(0e053h)		;586a
	and 003h		;586d
	dec a			;586f
	jr z,LA_POSICION_DE_LA_NAVE		;5870
	ld a,(0e7d0h)		;5872   ; Cuatro `rra` y cuatro bits: la columna de la nave pasada a casilla
	rra			;5875
	rra			;5876
	rra			;5877
	rra			;5878
	and 00fh		;5879
	dec c			;587b
	jr z,HACIA_EL_OTRO_LADO		;587c
	sub 003h		;587e
	jr nc,SUMA_EL_ALCANCE		;5880
	jr LA_POSICION_DE_LA_NAVE		;5882
HACIA_EL_OTRO_LADO:
	neg		;5884
	add a,005h		;5886
	jr nc,LA_POSICION_DE_LA_NAVE		;5888
SUMA_EL_ALCANCE:
	add a,b			;588a
	ld b,a			;588b
	ld a,(0e7d0h)		;588c
	cp 068h		;588f   ; Pasada la columna 0x68 solo salen dos
	jr c,LA_POSICION_DE_LA_NAVE		;5891
	ld b,002h		;5893
LA_POSICION_DE_LA_NAVE:
	ld hl,(0e7d0h)		;5895
	ld a,078h		;5898   ; 0x78 menos la fila: hacia donde queda la nave
	sub l			;589a
	jr c,PASA_A_CASILLA		;589b
	add a,038h		;589d
	add a,h			;589f
	jr nc,DIVIDE_ENTRE_OCHO		;58a0
	ld l,01eh		;58a2
	jr LA_PAGINA_DEL_BUFFER		;58a4
PASA_A_CASILLA:
	ld a,h			;58a6
	add a,038h		;58a7
DIVIDE_ENTRE_OCHO:
	rra			;58a9
	rra			;58aa
	rra			;58ab
	and 01fh		;58ac
	ld l,a			;58ae
LA_PAGINA_DEL_BUFFER:
	ld h,0eah		;58af   ; 0xEAxx: la pagina del buffer donde se mira el terreno
MIRA_SI_ES_TORRE:
	ld a,(hl)			;58b1
	cp 098h		;58b2   ; 0x98 es el tile del que salen: si no, se prueba la casilla de al lado
	jr z,BUSCA_HUECO_DE_DISPARO		;58b4
	dec l			;58b6
	ld a,l			;58b7
	cp 006h		;58b8   ; Y de la casilla 6 no se pasa
	ret c			;58ba
	djnz MIRA_SI_ES_TORRE		;58bb
	ret			;58bd
BUSCA_HUECO_DE_DISPARO:		; El primer hueco libre de las cuatro fichas de 0xE551
	ex de,hl			;58be
	ld hl,0e551h		;58bf
	ld b,004h		;58c2
MIRA_ESTE_HUECO:
	ld a,(hl)			;58c4
	cp 038h		;58c5   ; Por debajo de la fila 0x38 el hueco esta libre
	jr c,ARRANCA_EL_DISPARO		;58c7
	inc l			;58c9
	inc l			;58ca
	djnz MIRA_ESTE_HUECO		;58cb
	ret			;58cd
ARRANCA_EL_DISPARO:		; Pone el dibujo 0xBA y lo hace sonar
	ld (hl),0bah		;58ce   ; 0xBA es el dibujo del disparo que sube
	dec l			;58d0
	inc e			;58d1
	ld (hl),e			;58d2
	ld a,003h		;58d3   ; Y el sonido 3, el de que alguien dispara
	jp SUENA_ESTO		;58d5

; ----------------------------------------------------------------------
; DATOS cuantos_salen_por_zona (tramo): Lo que 0x5863 lee con la zona (0xE053)
;   de indice, con tope 12. Como la tabla de 0x566B, arranca DENTRO del `jp
;   0x5C96` de 0x58D5: sus dos primeras entradas son los bytes 0x96 y 0x5C de
;   ese operando, asi que las zonas 0 y 1 no pueden leerla de verdad. De la 2
;   en adelante los valores suben en escalera de 1 a 5.
;   0x58d8..0x58e6  (14 bytes)  de 0x58d6..0x58e6 (16 bytes)
DATA_cuantos_salen_por_zona_58D8:
	defb 001h,002h,001h,001h,002h,003h,002h,001h,003h,004h,003h,002h,004h,005h	; 58d8  ..............

; ======================================================================
; CODIGO 0x58e6..0x5c28  (834 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Mover lo que vuela en las zonas de clase 0
; ----------------------------------------------------------------------
MUEVE_LAS_FICHAS:		; Recorre las fichas de 0xE547 hacia atras y mueve cada una
	exx			;58e6
	ld hl,0e547h		;58e7
	ld bc,0e53fh		;58ea
	exx			;58ed
RECORRE_LAS_FICHAS:
	ld a,0d1h		;58ee   ; 0xD1 es la ficha libre: ahi se acaba
	cp (hl)			;58f0
	jr z,ATRAS_EN_LAS_DOS_LISTAS		;58f1
	inc hl			;58f3
	exx			;58f4
	ld a,(bc)			;58f5
	exx			;58f6
	ld c,002h		;58f7   ; Segun la clase, la fila sube 2, baja 2 (0xFE) o sube 4
	or a			;58f9
	jr z,APLICA_EL_PASO		;58fa
	ld c,0feh		;58fc
	cp 001h		;58fe
	jr z,APLICA_EL_PASO		;5900
	ld c,004h		;5902
APLICA_EL_PASO:
	ld a,(hl)			;5904   ; El paso que toca esta vez
	sub c			;5905
	ld (hl),a			;5906
	ld e,(hl)			;5907   ; Se guarda ya movida
	dec hl			;5908
	exx			;5909   ; De 0xE53F sale el paso de esta ficha en la otra direccion
	ld d,(hl)			;590a   ; Los dos bytes de la otra lista
	dec hl			;590b
	ld e,(hl)			;590c
	inc (hl)			;590d   ; El paso se guarda ya subido: al fotograma siguiente sera otro
	inc hl			;590e
	ld a,(de)			;590f
	exx			;5910
	ld c,a			;5911
	add a,(hl)			;5912   ; Y se suma al sitio de la ficha
	ld (hl),a			;5913
	bit 7,c		;5914   ; Con el bit 7 del paso puesto no se mira el terreno
	jr nz,ATRAS_EN_LAS_DOS_LISTAS		;5916
	push hl			;5918   ; Se guarda la ficha antes de mirar el terreno
	ld h,e			;5919
	add a,010h		;591a
	ld l,a			;591c
	call POSICION_A_NOMBRE		;591d   ; Se pasa a casilla y se lee el tile de la VRAM
	call VPEEK_HL		;5920
	pop hl			;5923
	add a,010h		;5924   ; Y se compara con el borde de abajo
	cp 090h		;5926   ; Pasada la fila 0x90 la ficha se apaga con el 0xD1
	jr c,ATRAS_EN_LAS_DOS_LISTAS		;5928
	ld (hl),0d1h		;592a
ATRAS_EN_LAS_DOS_LISTAS:
	exx			;592c   ; Se retrocede en las dos listas a la vez
	dec hl			;592d
	dec hl			;592e
	dec bc			;592f
	exx			;5930
	ld a,l			;5931   ; Cuatro bytes por ficha, de atras adelante
	sub 004h		;5932
	ld l,a			;5934
	djnz RECORRE_LAS_FICHAS		;5935
	jp VUELCA_LAS_CATORCE_FICHAS		;5937   ; Y al acabar, las fichas suben a la pantalla

; ----------------------------------------------------------------------
; Mover lo que vuela en las zonas de clase 1: aqui te siguen
; ----------------------------------------------------------------------
MUEVE_LAS_FICHAS_1:		; Como 0x58E6, pero mirando el terreno y persiguiendo a la nave
	ld de,0e53bh		;593a
RECORRE_LAS_FICHAS_1:
	ld a,0d1h		;593d
	cp (hl)			;593f   ; 0xD1, ficha libre: no hay mas que mover
	jr z,ATRAS_EN_LA_LISTA		;5940
	inc hl			;5942
	ld a,(hl)			;5943
	sub 002h		;5944   ; Dos columnas por fotograma, siempre hacia la izquierda
	ld (hl),a			;5946
	dec hl			;5947
	ld c,a			;5948
	jr c,APAGA_ESTA_FICHA		;5949   ; Y al desbordarse por la izquierda, la ficha se apaga
	push hl			;594b
	push de			;594c
	ld a,(de)			;594d
	ld e,a			;594e
	ld d,003h		;594f   ; El paso de subida arranca en 3...
	ld a,(0e053h)		;5951
	cp 006h		;5954   ; ...y de la zona 6 en adelante, en 4: mas deprisa
	jr c,EL_PASO_DE_SUBIDA		;5956
	inc d			;5958
EL_PASO_DE_SUBIDA:
	ld a,d			;5959
	ld d,008h		;595a
	dec e			;595c
	jr nz,GUARDA_EL_PASO		;595d
	ld d,0f8h		;595f   ; Con el otro sentido, 0xF8: se baja en vez de subir
	neg		;5961
	dec a			;5963
GUARDA_EL_PASO:
	ld e,a			;5964
	ld a,l			;5965
	cp 0e0h		;5966
	jr c,APLICA_EL_PASO_1		;5968
	inc e			;596a
APLICA_EL_PASO_1:
	ld a,(hl)			;596b
	add a,e			;596c
	ld (hl),a			;596d
	add a,008h		;596e   ; Se mira dos casillas por delante, no la de encima
	add a,008h		;5970
	jr c,DEJA_LA_FICHA_LIBRE		;5972   ; Desbordado, la ficha se ha salido de la pantalla
	add a,d			;5974
	ld l,a			;5975
	ld h,c			;5976
	call POSICION_A_NOMBRE		;5977
	call VPEEK_HL		;597a
	pop de			;597d
	cp 006h		;597e   ; Tile por debajo del 6: aire, se puede seguir
	jr c,RECUPERA_LA_FICHA		;5980
	ld a,(de)			;5982   ; Y si no, se le da la vuelta al sentido y sube en vez de bajar
	or a			;5983
	ld a,001h		;5984
	jr z,DA_LA_VUELTA_AL_SENTIDO		;5986
	xor a			;5988
DA_LA_VUELTA_AL_SENTIDO:
	ld (de),a			;5989
RECUPERA_LA_FICHA:
	pop hl			;598a
ATRAS_EN_LA_LISTA:
	dec de			;598b
	ld a,l			;598c
	sub 004h		;598d
	ld l,a			;598f
	djnz RECORRE_LAS_FICHAS_1		;5990
MIRA_DONDE_ESTA_LA_NAVE:		; Deja en 0xE538 hacia que lado queda la nave
	ld hl,0e7d8h		;5992
	ld a,(hl)			;5995
	cp 090h		;5996   ; Por encima de la fila 0x90 no se persigue
	jr nc,Y_A_SUBIR_LAS_FICHAS		;5998
	ld a,(0e7d0h)		;599a
	ld c,a			;599d
	sub (hl)			;599e
	sub 019h		;599f   ; 0x19 de margen: dentro de eso ya se le da por encima
	add a,031h		;59a1
	jr c,Y_A_SUBIR_LAS_FICHAS		;59a3
	ld a,c			;59a5
	ld c,001h		;59a6
	sub (hl)			;59a8   ; 0xE538 a 1 si la nave queda a un lado y a 0 si al otro
	jr c,GUARDA_EL_LADO		;59a9
	dec c			;59ab
GUARDA_EL_LADO:
	ld a,c			;59ac
	ld (0e538h),a		;59ad
Y_A_SUBIR_LAS_FICHAS:
	jp VUELCA_LAS_CATORCE_FICHAS		;59b0
APAGA_ESTA_FICHA:		; El 0xD1 que la deja libre
	ld (hl),0d1h		;59b3
	jr ATRAS_EN_LA_LISTA		;59b5
DEJA_LA_FICHA_LIBRE:
	pop de			;59b7
	xor a			;59b8
	jr DA_LA_VUELTA_AL_SENTIDO		;59b9

; ----------------------------------------------------------------------
; Mover lo que vuela en las zonas de clase 2 y siguientes
; ----------------------------------------------------------------------
MUEVE_LAS_FICHAS_2:		; Con cuenta atras propia y paso de media casilla
	ld a,0d1h		;59bb
	cp (hl)			;59bd
	jr z,LA_FICHA_DE_ANTES		;59be
	inc hl			;59c0
	dec (hl)			;59c1   ; Cada ficha lleva su cuenta; al llegar a cero se acabo
	ex af,af'			;59c2
	dec hl			;59c3
	ex af,af'			;59c4
	jr z,SE_HA_SALIDO		;59c5
	ld c,0fah		;59c7   ; 0xFA de paso, o 0xF8 si el hueco de 0xE533 esta marcado
	ld a,b			;59c9
	add a,033h		;59ca
	ld e,a			;59cc
	ld d,0e5h		;59cd
	ld a,(de)			;59cf
	or a			;59d0
	jr z,MITAD_DE_VELOCIDAD		;59d1
	ld c,0f8h		;59d3
MITAD_DE_VELOCIDAD:
	ld a,(0e054h)		;59d5
	ld d,a			;59d8
	ld a,c			;59d9
	bit 0,d		;59da   ; Con el bit 0 de 0xE054 el paso se invierte...
	jr z,APLICA_EL_PASO_2		;59dc
	neg		;59de
	srl a		;59e0   ; ...y un `srl` lo deja a la mitad: se mueve mas despacio
APLICA_EL_PASO_2:
	add a,(hl)			;59e2
	ld (hl),a			;59e3
	cp 0d0h		;59e4   ; Pasado el 0xD0 se ha salido por abajo
	jr nc,SE_HA_SALIDO		;59e6
	dec d			;59e8
	jr nz,LA_FICHA_DE_ANTES		;59e9
	inc hl			;59eb
	ld d,(hl)			;59ec
	dec hl			;59ed
	push hl			;59ee
	ld h,d			;59ef
	add a,010h		;59f0
	ld l,a			;59f2
	call POSICION_A_NOMBRE		;59f3   ; Se mira el tile del sitio nuevo
	call VPEEK_HL		;59f6
	pop hl			;59f9
	add a,010h		;59fa
	cp 020h		;59fc   ; Por debajo del tile 0x20 hay aire; si no, la ficha se apaga
	jr c,LA_FICHA_DE_ANTES		;59fe
SE_HA_SALIDO:
	ld (hl),0d1h		;5a00
LA_FICHA_DE_ANTES:
	ld a,l			;5a02
	sub 004h		;5a03
	ld l,a			;5a05
	djnz MUEVE_LAS_FICHAS_2		;5a06
VUELCA_LAS_CATORCE_FICHAS:		; Las catorce fichas de 0xE7D8 a la VRAM 0x3B08
	ld b,00eh		;5a08
	ld hl,0e7d8h		;5a0a
	ld de,03b08h		;5a0d
	jp COPIA_A_VRAM		;5a10

; ----------------------------------------------------------------------
; Los disparos que suben del terreno
; ----------------------------------------------------------------------
MUEVE_LOS_DISPAROS:		; Las cuatro fichas de 0xE551 suben y se pintan en la tabla de nombres
	ld b,004h		;5a13
	ld hl,0e551h		;5a15
MIRA_ESTE_HUECO_2:
	ld a,(hl)			;5a18
	cp 038h		;5a19   ; Por debajo de la fila 0x38 el hueco esta libre
	jr c,EL_SIGUIENTE_HUECO		;5a1b   ; Por debajo de la fila 0x38 no hay disparo aqui
	push hl			;5a1d
	ld d,(hl)			;5a1e   ; Se aparta la fila
	dec l			;5a1f
	ld a,(hl)			;5a20
	sub 021h		;5a21   ; 0x21 de subida por fotograma: dos filas y pico
	ld e,a			;5a23
	jr nc,PINTA_EL_DISPARO		;5a24
	dec d			;5a26
PINTA_EL_DISPARO:
	ld (hl),e			;5a27   ; El tile del disparo, en su sitio nuevo
	inc l			;5a28
	bit 7,d		;5a29
	ex af,af'			;5a2b
	res 7,d		;5a2c
	ld (hl),037h		;5a2e   ; 0x37 es el tile del disparo
	ex de,hl			;5a30
	ld a,l			;5a31   ; Al borde de la fila se corta
	and 01fh		;5a32   ; Al llegar al borde de la fila se corta
	cp 01fh		;5a34
	jr z,REPONE_LO_QUE_HABIA		;5a36
	ld a,h			;5a38   ; Y por encima de la fila 0x38 tampoco se pinta
	cp 038h		;5a39
	jr c,REPONE_LO_QUE_HABIA		;5a3b
	call VPEEK_HL		;5a3d
	sub 080h		;5a40   ; Menos 0x80: solo se pisa lo que sea cielo
	cp 04ch		;5a42
	jr c,REPONE_LO_QUE_HABIA		;5a44
	ld a,h			;5a46   ; Aqui se planta el tile
	ld (de),a			;5a47
	ld a,006h		;5a48
	call VPOKE_HL		;5a4a
	ex af,af'			;5a4d   ; El `ex af,af'` recupera si hay que borrar detras
	jr nz,RECUPERA_EL_HUECO		;5a4e
REPONE_LO_QUE_HABIA:
	ld a,021h		;5a50   ; Y por donde paso se repone el tile 0x21, o el cielo vacio
	call HL_MAS_A		;5a52
	xor a			;5a55
	call VPOKE_HL		;5a56
RECUPERA_EL_HUECO:
	pop hl			;5a59
EL_SIGUIENTE_HUECO:
	inc l			;5a5a
	inc l			;5a5b
	djnz MIRA_ESTE_HUECO_2		;5a5c
	ret			;5a5e

; ----------------------------------------------------------------------
; El disparo de la nave, y la bomba
; ----------------------------------------------------------------------
MUEVE_EL_DISPARO:		; Lo mueve, mira contra que choca y reparte las consecuencias
	xor a			;5a5f   ; Con el primer byte a cero no hay disparo en el aire
	cp (hl)			;5a60
	ret z			;5a61
	inc hl			;5a62   ; El primer byte de la ficha es el paso
	ld b,(hl)			;5a63   ; Y los dos siguientes, donde esta
	inc hl			;5a64
	ld e,(hl)			;5a65
	inc hl			;5a66
	ld d,(hl)			;5a67
	ex de,hl			;5a68
	dec hl			;5a69   ; Una casilla atras: de donde se borra
	call VPOKE_HL		;5a6a   ; Se borra de donde estaba...
	inc hl			;5a6d
	call VPEEK_HL		;5a6e   ; ...y se mira el tile de donde va
	cp 006h		;5a71   ; Por debajo del tile 6 es cielo: sigue volando
	jr nc,EL_DISPARO_TOCA_TERRENO		;5a73
	ld a,l			;5a75   ; Los cinco bits bajos son la columna dentro de la fila
	and 01fh		;5a76
	cp 01eh		;5a78   ; Y al llegar al borde de la fila, se acabo
	jr nc,BORRA_EL_DISPARO		;5a7a
	inc hl			;5a7c   ; La casilla de al lado tambien
	call VPEEK_HL		;5a7d
	cp 006h		;5a80   ; Tambien tiene que ser cielo
	jr nc,EL_DISPARO_TOCA_TERRENO		;5a82
	dec hl			;5a84
	push hl			;5a85   ; Se guarda todo antes de mirar los choques
	push de			;5a86
	push bc			;5a87
	call CHOQUE_DEL_DISPARO		;5a88   ; Antes de nada, si le da a algo que vuela
	pop bc			;5a8b
	pop de			;5a8c
	pop hl			;5a8d
	jr c,BORRA_EL_DISPARO		;5a8e   ; Con carry ya ha dado a algo: nada mas que hacer
	ld a,b			;5a90   ; Sigue volando: se pinta en el sitio nuevo
	call VPOKE_HL		;5a91
	ex de,hl			;5a94
	dec hl			;5a95   ; Y se avanza una casilla en el sentido que lleve
	inc (hl)			;5a96
	ret			;5a97
EL_DISPARO_TOCA_TERRENO:		; Abre el boquete, y si era un deposito repone y paga
	push de			;5a98
	push hl			;5a99
	ld d,a			;5a9a
	call ABRE_BOQUETE		;5a9b   ; El boquete en el terreno
	pop hl			;5a9e
	jr c,DA_DE_BAJA_EL_DISPARO		;5a9f
	ld a,d			;5aa1
	push af			;5aa2
	push hl			;5aa3
	call REPONE_COMBUSTIBLE		;5aa4   ; Si lo que ha reventado era un deposito, el combustible se llena
	ld a,d			;5aa7
	call PUNTOS_DE_PREMIO		;5aa8   ; Y los puntos de premio, fijos o sorteados
	pop hl			;5aab
	pop af			;5aac
	call POSICION_A_PATRON		;5aad
	bit 3,a		;5ab0   ; Sin el bit 3, cuatro filas mas abajo: la explosion se centra
	jr nz,COLOCA_LA_EXPLOSION		;5ab2
	inc h			;5ab4
	inc h			;5ab5
	inc h			;5ab6
	inc h			;5ab7
COLOCA_LA_EXPLOSION:
	call COLOCA_EXPLOSION		;5ab8
DA_DE_BAJA_EL_DISPARO:
	pop de			;5abb
BORRA_EL_DISPARO:
	ld l,020h		;5abc   ; Y el disparo queda dado de baja
	ld h,d			;5abe
	ld (hl),000h		;5abf
	ret			;5ac1

; ----------------------------------------------------------------------
; La bomba: cae, mira contra que da y se lleva el terreno por delante
; ----------------------------------------------------------------------
MUEVE_LA_BOMBA:		; La bomba de 0xE7E8, con sus choques y su explosion
	ld a,(0e51fh)		;5ac2   ; Con 0xE51F a cero no hay bomba en el aire
	or a			;5ac5
	ret z			;5ac6
	call CHOQUE_DE_LA_BOMBA		;5ac7   ; Primero, si le ha dado a algo que vuela
	jp c,BAJA_LA_BOMBA		;5aca
	ld a,(0e54ah)		;5acd   ; Y si 0xE54A esta puesto, tambien contra el deposito
	or a			;5ad0
	jr z,LEE_LAS_CASILLAS_DE_LA_BOMBA		;5ad1
	call CHOQUE_CON_LA_BASE		;5ad3
	jp c,BAJA_LA_BOMBA		;5ad6
LEE_LAS_CASILLAS_DE_LA_BOMBA:
	ld hl,(0e7e8h)		;5ad9
	call POSICION_A_NOMBRE		;5adc
	call VPEEK_HL		;5adf   ; Cuatro casillas de la VRAM a 0xE520: la de la bomba, la de al lado y las dos de debajo. La segunda de cada par se lee con `in a,(098h)` a secas, aprovechando que el VDP avanza solo la direccion
	ld de,0e520h		;5ae2
	ld (de),a			;5ae5
	inc de			;5ae6
	in a,(098h)		;5ae7
	ld (de),a			;5ae9
	inc de			;5aea
	ld bc,00020h		;5aeb
	add hl,bc			;5aee
	call VPEEK_HL		;5aef
	ld (de),a			;5af2
	sub 084h		;5af3   ; Del tile 0x84 al 0x86: cuestas, y ahi se para
	cp 003h		;5af5
	jr c,LA_CUARTA_CASILLA		;5af7
	ld a,(de)			;5af9
	sub 080h		;5afa   ; Del 0x80 al 0x87: terreno
	cp 008h		;5afc
	jr c,LA_BOMBA_SE_ESTRELLA		;5afe
LA_CUARTA_CASILLA:
	inc de			;5b00
	in a,(098h)		;5b01
	ld (de),a			;5b03
	ld b,004h		;5b04
MIRA_LAS_CUATRO:
	ld a,(de)			;5b06
	sub 090h		;5b07   ; Del 0x90 al 0xCB: tambien
	cp 03ch		;5b09
	jr c,COLOCA_EL_CHOQUE		;5b0b
	dec de			;5b0d
	djnz MIRA_LAS_CUATRO		;5b0e
	jr SUBE_LA_FICHA_APAGADA		;5b10
COLOCA_EL_CHOQUE:
	ld a,e			;5b12
	rra			;5b13
	jr nc,MEDIA_CASILLA_DE_LA_BOMBA		;5b14
	inc hl			;5b16
MEDIA_CASILLA_DE_LA_BOMBA:
	rra			;5b17
	jr c,MIRA_CONTRA_QUE_DA		;5b18
	ld b,000h		;5b1a
	sbc hl,bc		;5b1c
MIRA_CONTRA_QUE_DA:
	push hl			;5b1e   ; Se guardan la casilla y la posicion
	push de			;5b1f
	ld a,(de)			;5b20
	call POSICION_A_PATRON		;5b21   ; De la posicion sale el pixel
	ld (0e52eh),hl		;5b24   ; 0xE52E guarda donde poner la explosion
	ld a,(de)			;5b27   ; Y el tile es el que elige los margenes
	ex de,hl			;5b28
	ld hl,055d3h		;5b29   ; Los margenes salen de la tabla de 0x55D3, cuatro bytes por familia de tile: el indice es el nibble alto y siete
	rra			;5b2c
	rra			;5b2d
	rra			;5b2e
	rra			;5b2f
	and 007h		;5b30
	add a,a			;5b32   ; Por cuatro: cuatro bytes por familia
	add a,a			;5b33
	call HL_MAS_A		;5b34
	ld bc,(0e7e8h)		;5b37   ; La posicion de la bomba
	call HAY_CHOQUE		;5b3b   ; Y a mirar si se pisan
	pop de			;5b3e
	pop hl			;5b3f
	jr nc,SUBE_LA_FICHA_APAGADA		;5b40   ; Sin choque, la bomba sigue cayendo
	push hl			;5b42   ; Se guarda todo otra vez
	push de			;5b43
	ld a,(de)			;5b44
	call REPONE_COMBUSTIBLE		;5b45   ; Y si lo que ha reventado era un deposito, se llena el combustible
	ld a,(de)			;5b48
	call PUNTOS_DE_PREMIO		;5b49   ; Los puntos
	pop de			;5b4c   ; Se recupera para el boquete
	pop hl			;5b4d
	ld a,(de)			;5b4e
	call ABRE_BOQUETE		;5b4f   ; El boquete en el terreno
	ld hl,(0e52eh)		;5b52   ; Y la explosion va donde se apunto
	ld a,(de)			;5b55
LA_EXPLOSION_DE_LA_BOMBA:
	call COLOCA_EXPLOSION		;5b56
BAJA_LA_BOMBA:		; Deja la bomba dada de baja y apaga su ficha
	xor a			;5b59
	ld (0e51fh),a		;5b5a
	ld hl,0e7e8h		;5b5d
	ld (hl),0d1h		;5b60   ; 0xD1 la apaga
SUBE_LA_FICHA_APAGADA:
	ld hl,0e7e8h		;5b62
	inc (hl)			;5b65
	ld de,03b18h		;5b66
	ld b,002h		;5b69
	jp COPIA_A_VRAM		;5b6b
LA_BOMBA_SE_ESTRELLA:		; Cuando cae sin darle a nada
	ld hl,(0e7e8h)		;5b6e
	ld bc,00405h		;5b71
	sbc hl,bc		;5b74
	ld a,001h		;5b76
	ld (0e55fh),a		;5b78   ; 0xE55F a uno: la explosion sonara distinta
	jr LA_EXPLOSION_DE_LA_BOMBA		;5b7b

; ----------------------------------------------------------------------
; Poner una explosion donde sea
; ----------------------------------------------------------------------
COLOCA_EXPLOSION:		; Sube ocho pixeles si hace falta y busca hueco de explosion
	cp 0aeh		;5b7d   ; Pasada la fila 0xAE, la explosion se sube ocho pixeles para que se vea
	jr c,PONE_EXPLOSION		;5b7f
	ld a,h			;5b81
	sub 008h		;5b82
	ld h,a			;5b84
PONE_EXPLOSION:		; Ocupa uno de los cuatro huecos de explosion y la hace sonar
	ex de,hl			;5b85
	ld hl,0e52fh		;5b86
	ld b,004h		;5b89   ; Cuatro huecos; el primero que este a cero
	xor a			;5b8b
BUSCA_HUECO_DE_EXPLOSION:
	inc hl			;5b8c
	cp (hl)			;5b8d
	jr z,OCUPA_EL_HUECO_2		;5b8e
	djnz BUSCA_HUECO_DE_EXPLOSION		;5b90
	ld l,040h		;5b92   ; Si estan los cuatro ocupados, se pisa el primero
OCUPA_EL_HUECO_2:
	ld (hl),009h		;5b94   ; 9 es lo que dura la explosion
	ld a,l			;5b96
	and 003h		;5b97
	add a,a			;5b99
	add a,a			;5b9a
	ld hl,0e7f0h		;5b9b   ; La posicion va a 0xE7F0, de cuatro en cuatro
	call HL_MAS_A		;5b9e
	ld (hl),e			;5ba1
	inc hl			;5ba2
	ld (hl),d			;5ba3
	ld hl,0e55fh		;5ba4   ; 0xE55F distingue las dos explosiones: la normal y la de la bomba
	xor a			;5ba7
	cp (hl)			;5ba8
	ld (hl),a			;5ba9
	ld a,042h		;5baa   ; 0x42 es el sonido del reventon
	call z,SUENA_ESTO		;5bac
	scf			;5baf
	ret			;5bb0
VUELCA_LAS_EXPLOSIONES:		; Las fichas de 0xE7F0 a la VRAM 0x3B20, y las que se apagan
	ld hl,0e7f0h		;5bb1   ; Las catorce fichas de explosion a la VRAM 0x3B20
	ld de,03b20h		;5bb4
	ld b,00eh		;5bb7
	call COPIA_A_VRAM		;5bb9
	ld de,0e7f0h		;5bbc
	ld hl,0e530h		;5bbf   ; Cada una con su cuenta atras en 0xE530
	ld b,004h		;5bc2
MIRA_ESTA_EXPLOSION:
	ld a,(hl)			;5bc4   ; Cada explosion lleva su cuenta atras en 0xE530
	or a			;5bc5
	jr z,LA_SIGUIENTE_EXPLOSION		;5bc6
	dec (hl)			;5bc8
	jr nz,LA_SIGUIENTE_EXPLOSION		;5bc9
	ld a,0d1h		;5bcb   ; Al llegar a cero, la ficha se apaga con el 0xD1
	ld (de),a			;5bcd
LA_SIGUIENTE_EXPLOSION:
	ld a,004h		;5bce   ; Cuatro bytes por ficha
	add a,e			;5bd0
	ld e,a			;5bd1
	inc hl			;5bd2   ; Y la cuenta de al lado
	djnz MIRA_ESTA_EXPLOSION		;5bd3
	ret			;5bd5

; ----------------------------------------------------------------------
; La nave revienta
; ----------------------------------------------------------------------
LA_NAVE_REVIENTA:		; Enciende la explosion de la nave y la hace sonar
	ld a,001h		;5bd6
	ld (0e50eh),a		;5bd8   ; 0xE50E puesto es lo que desvia el paso de partida a 0x5BE5
	ld a,060h		;5bdb   ; 0x60 fotogramas dura el reventon
	ld (0e004h),a		;5bdd
	ld a,0cdh		;5be0   ; 0xCD es el sonido de la nave estrellandose
	jp SUENA_ESTO		;5be2
PASO_DEL_REVENTON:		; Un fotograma de la nave reventada
	ld hl,0e004h		;5be5
	dec (hl)			;5be8
	jr z,$+67		;5be9
	bit 2,(hl)		;5beb   ; El bit 2 de la cuenta: los dibujos se turnan cada cuatro fotogramas
	ld hl,00a38h		;5bed   ; Dos parejas de dibujos, 0x38/0x0A y 0x30/0x0A
	jr z,GUARDA_LOS_DIBUJOS		;5bf0
	ex af,af'			;5bf2
	ld l,030h		;5bf3
GUARDA_LOS_DIBUJOS:
	ld (0e7d2h),hl		;5bf5
	ld a,004h		;5bf8
	add a,l			;5bfa
	ld l,a			;5bfb
	ld (0e7d6h),hl		;5bfc
	ld hl,0e7d0h		;5bff
	ld de,03b00h		;5c02
	ld b,008h		;5c05
	call COPIA_A_VRAM		;5c07
	ld a,(0e54bh)		;5c0a
	dec a			;5c0d   ; Solo si 0xE54B vale 1 hay que retocar las otras dos fichas
	ret nz			;5c0e
	ld de,03b32h		;5c0f
	ld hl,05c28h		;5c12   ; Y los dos dibujos de 0x5C28, cambiados de sitio segun el fotograma
	ex af,af'			;5c15
	jr nz,LOS_OTROS_DOS_DIBUJOS		;5c16
	inc hl			;5c18
	inc hl			;5c19
LOS_OTROS_DOS_DIBUJOS:
	ld b,002h		;5c1a   ; Dos bytes por dibujo
	call COPIA_A_VRAM		;5c1c
	ld b,002h		;5c1f   ; Y los otros dos, dos casillas mas alla
	dec hl			;5c21
	dec hl			;5c22
	inc de			;5c23
	inc de			;5c24
	jp COPIA_A_VRAM		;5c25

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_nave_rota: Los dos pares de dibujos con los que 0x5C12
;   pinta la nave estrellada: el 6 y el 7, que se turnan segun el fotograma.
;   0x5c28..0x5c2c  (4 bytes)
DATA_dibujos_de_la_nave_rota:
	defb 000h,006h	; 5c28
	defb 000h,007h	; 5c2a

; ======================================================================
; CODIGO 0x5c2c..0x5e55  (553 bytes)
; ======================================================================


SE_ACABA_EL_REVENTON:		; Apaga las fichas y avisa de que el jugador ha muerto
	call APAGA_LAS_FICHAS		;5c2c
	xor a			;5c2f
	ld (0e06fh),a		;5c30   ; 0xE06F a cero: ESTADO_11 deja de jugar y pasa al siguiente
	ld hl,0e55eh		;5c33   ; Si la nave habia llegado ya al final, 0xE55E lo dice y no se pierde vida
	cp (hl)			;5c36
	ret z			;5c37
	ld (0e058h),a		;5c38
	ld (hl),a			;5c3b
	inc a			;5c3c
	ld (0e056h),a		;5c3d
	ret			;5c40

; ----------------------------------------------------------------------
; Llegar a la base: el final de la fase
; ----------------------------------------------------------------------
LLEGA_A_LA_BASE:		; Limpia lo que quede volando, felicita y paga
	ld a,001h		;5c41
	ld (0e056h),a		;5c43
	ld b,004h		;5c46
	ld hl,0e551h		;5c48   ; Los cuatro disparos que hubiera en el aire se borran uno a uno
BORRA_ESTE_DISPARO:
	ld a,(hl)			;5c4b   ; Por debajo de la fila 0x38 el hueco esta libre y no hay que borrarlo
	cp 038h		;5c4c
	jr c,EL_SIGUIENTE_A_BORRAR		;5c4e
	ld d,a			;5c50
	dec hl			;5c51
	ld e,(hl)			;5c52
	ex de,hl			;5c53
	xor a			;5c54   ; Se borra de la pantalla poniendo el tile 0
	call VPOKE_HL		;5c55
	ex de,hl			;5c58
	inc hl			;5c59   ; Tres bytes por hueco
	ld (hl),a			;5c5a
EL_SIGUIENTE_A_BORRAR:
	inc hl			;5c5b
	inc hl			;5c5c
	djnz BORRA_ESTE_DISPARO		;5c5d
	ld a,(0e012h)		;5c5f   ; 0xE012 distingue si hay que pintar o borrar el cartel
	and a			;5c62
	ld hl,0421dh		;5c63   ; INVASION SUCCEEDED
	jp nz,PINTA_DIBUJO		;5c66
	ld hl,0e7c8h		;5c69
	ld a,0d1h		;5c6c   ; Las dos fichas del deposito se apagan
	ld (hl),a			;5c6e
	ld (0e7cch),a		;5c6f
	ld hl,0e7d8h		;5c72
	ld b,00ah		;5c75
	call APAGA_FICHAS_DESDE_HL		;5c77
	call PINTA_LA_BASE		;5c7a
	ld hl,0421dh		;5c7d   ; Y aqui el mismo cartel se BORRA, entrando por 0x4064 en vez de 0x4068
	call BORRA_DIBUJO		;5c80
VUELVE_A_MONTAR_EL_DECORADO:
	call SUBMODO_0_VUELCA		;5c83
	ld a,(0e053h)		;5c86
	and 003h		;5c89
	jr nz,VUELVE_A_MONTAR_EL_DECORADO		;5c8b
	ld de,01500h		;5c8d   ; 1500 puntos por haber llegado
	call SUMA_PUNTOS		;5c90
	jp REINICIA_EL_TERRENO		;5c93
SUENA_ESTO:		; Manda sonar el sonido A, guardando todos los registros
	di			;5c96   ; Sin interrupciones: la interrupcion tambien toca el sonido
	push hl			;5c97
	push de			;5c98
	push bc			;5c99
	push af			;5c9a
	ld d,000h		;5c9b   ; D a cero: se respeta lo que ya este sonando
	call SONIDO_ARRANCA		;5c9d
	pop af			;5ca0
	pop bc			;5ca1
	pop de			;5ca2
	pop hl			;5ca3
	ei			;5ca4
	ret			;5ca5
SONIDO_ARRANCA:		; Reparte el sonido A entre los canales que le tocan
	ld c,a			;5ca6
	ld b,002h		;5ca7
	ld hl,0e012h		;5ca9
	cp 089h		;5cac   ; Aqui se reparten los canales: por debajo del 0x89 el sonido se lleva UNO, del 0x89 al 0x8C DOS y del 0x8D en adelante TRES, y las pistas salen de palabras seguidas de la tabla
	jr c,LOS_SONIDOS_CORTOS		;5cae
	cp 08dh		;5cb0
	jr c,SIN_MIRAR_PRIORIDAD		;5cb2
	inc b			;5cb4   ; El `inc b` es el que sube de dos canales a tres
	jr SIN_MIRAR_PRIORIDAD		;5cb5
LOS_SONIDOS_CORTOS:
	and 03fh		;5cb7   ; Los seis bits bajos son el numero de sonido de verdad
	dec b			;5cb9
	cp 006h		;5cba   ; Por debajo del 6, los sonidos cortos: prioridad en 0xE01C o 0xE026
	jr nc,SONIDO_PISTAS		;5cbc
	cp 003h		;5cbe
	ld hl,0e01ch		;5cc0
	jr nc,SIN_MIRAR_PRIORIDAD		;5cc3
	ld hl,0e026h		;5cc5
SIN_MIRAR_PRIORIDAD:
	dec d			;5cc8   ; Con D a 1 -desde el bucle- no se mira la prioridad
	jr z,SONIDO_PISTAS		;5cc9
	ld a,c			;5ccb
	cp (hl)			;5ccc   ; Si lo que suena vale mas que esto, no se pisa
	ret c			;5ccd
	cp 0cdh		;5cce
	jr c,SONIDO_PISTAS		;5cd0
	and 07fh		;5cd2
	ld c,a			;5cd4
SONIDO_PISTAS:		; Busca la pista en la tabla de 0x5E5F y arranca los canales
	and 03fh		;5cd5   ; El numero y 0x3F, por dos: una palabra por canal, seguidas
	add a,a			;5cd7
	ld de,05e5fh		;5cd8   ; 0x5E5F es la base de la tabla, y cae dos bytes ANTES de la primera palabra: la entrada 0 se monta sobre los dos ultimos periodos de nota y apunta a 0x383C, fuera del cartucho. El sonido numero 0 no se puede pedir, y no lo pide nadie
	call DE_MAS_A		;5cdb
	dec hl			;5cde
	dec hl			;5cdf
ARRANCA_UN_CANAL:
	ld (hl),001h		;5ce0   ; Un fotograma de nota y duracion 1: al primer paso ya se lee el evento
	inc hl			;5ce2
	ld (hl),001h		;5ce3
	inc hl			;5ce5
	ld (hl),c			;5ce6   ; El numero de sonido, que es lo que mira la prioridad
	inc hl			;5ce7
	ld a,(de)			;5ce8
	ld (hl),a			;5ce9
	inc hl			;5cea
	inc de			;5ceb
	ld a,(de)			;5cec
	ld (hl),a			;5ced
	ld a,005h		;5cee   ; Cinco mas: el byte de la envolvente del canal siguiente
	add a,l			;5cf0
	ld l,a			;5cf1
	ld (hl),000h		;5cf2
	inc hl			;5cf4
	inc de			;5cf5
	djnz ARRANCA_UN_CANAL		;5cf6
	ret			;5cf8
SONIDO_ENCADENADO:		; Al acabarse un sonido, arranca el que lleve apuntado en +9
	inc hl			;5cf9   ; +9 es el sonido que va encadenado detras de este
	ld a,(ix+009h)		;5cfa
	inc a			;5cfd
	cp (hl)			;5cfe
	jp z,CANAL_APAGA		;5cff
	jp m,ARRANCA_EL_ENCADENADO		;5d02
	dec a			;5d05
ARRANCA_EL_ENCADENADO:
	ex af,af'			;5d06
	ld a,(ix+002h)		;5d07   ; Se arranca con D a 1: sin mirar prioridades
	push bc			;5d0a
	ld d,001h		;5d0b   ; D a 1: este no mira prioridades
	call SONIDO_ARRANCA		;5d0d
	pop bc			;5d10
	ex af,af'			;5d11
	ld (ix+009h),a		;5d12
	ret			;5d15
PSG_MEZCLA:		; Abre o cierra el tono del canal C en el registro 7 del PSG
	ld a,007h		;5d16   ; El registro 7 es el de la mezcla: que canales suenan y cuales no
	out (0a0h),a		;5d18
	in a,(0a2h)		;5d1a
	ld e,a			;5d1c
	ld a,c			;5d1d
	cp 001h		;5d1e
	jr z,COLOCA_EL_BIT_DEL_CANAL		;5d20
	dec a			;5d22
COLOCA_EL_BIT_DEL_CANAL:
	rlca			;5d23   ; Tres `rlca` colocan el bit del canal en su sitio
	rlca			;5d24
	rlca			;5d25
	dec d			;5d26   ; Con D a cero se abre el canal, y si no se cierra
	jr z,ABRE_EL_CANAL		;5d27
	cpl			;5d29
	and e			;5d2a
	jr MANDA_LA_MEZCLA		;5d2b
ABRE_EL_CANAL:
	or e			;5d2d
MANDA_LA_MEZCLA:
	out (0a1h),a		;5d2e
	ret			;5d30
SUENA:		; Un fotograma de los tres canales
	ld c,001h		;5d31   ; IX recorre los canales desde 0xE010, diez bytes cada uno
	ld ix,0e010h		;5d33
	exx			;5d37
	ld b,003h		;5d38
	ld de,0000ah		;5d3a
EL_CANAL_SIGUIENTE:
	exx			;5d3d
	ld a,(ix+002h)		;5d3e
	or a			;5d41
	call nz,SUENA_CANAL		;5d42
	inc c			;5d45   ; Dos `inc c` porque cada canal ocupa dos registros del PSG
	inc c			;5d46
	exx			;5d47
	add ix,de		;5d48
	djnz EL_CANAL_SIGUIENTE		;5d4a
	ret			;5d4c
SUENA_CANAL:		; Un paso del canal que apunta IX
	bit 6,a		;5d4d   ; El bit 6 del sonido decide si el canal lleva tono o solo ruido
	ld d,001h		;5d4f
	call z,PSG_MEZCLA		;5d51
	ld a,(ix+002h)		;5d54
	or a			;5d57
	jp m,SUENA_MUSICA		;5d58   ; Con el bit 7 puesto es musica, y va por otro sitio
	dec (ix+000h)		;5d5b   ; Se descuenta la nota; hasta que no llega a cero no se lee nada
	ret nz			;5d5e
SIGUIENTE_EVENTO:		; Lee el evento siguiente de la pista
	ld l,(ix+003h)		;5d5f
	ld h,(ix+004h)		;5d62
	ld a,(hl)			;5d65
	cp 0feh		;5d66   ; 0xFE: la pista vuelve a empezar
	jr z,SONIDO_ENCADENADO		;5d68
	jr nc,CANAL_APAGA		;5d6a   ; 0xFF: se apaga el canal
	bit 7,(ix+002h)		;5d6c
	jp nz,MUSICA_EVENTO		;5d70
	and 0f0h		;5d73   ; 0x2n: cambia la duracion de las notas del efecto
	cp 020h		;5d75
	jr nz,EVENTO_DE_RUIDO		;5d77
	ld a,(hl)			;5d79
	and 00fh		;5d7a
	ld (ix+001h),a		;5d7c
	inc hl			;5d7f
EVENTO_DE_RUIDO:
	ld a,(hl)			;5d80   ; 0x1n en la pista: el registro 6 del PSG, el periodo del ruido
	and 0f0h		;5d81
	cp 010h		;5d83   ; 0x1n: el registro 6 del PSG, el periodo del ruido
	jr nz,EL_VOLUMEN_DEL_EFECTO		;5d85
	ld a,006h		;5d87   ; Los cinco bits bajos son ese periodo
	out (0a0h),a		;5d89
	ld a,(hl)			;5d8b
	and 01fh		;5d8c
	out (0a1h),a		;5d8e
	ld d,000h		;5d90   ; Y con D a cero se abre el canal en la mezcla
	call PSG_MEZCLA		;5d92
	inc hl			;5d95
	ld a,(hl)			;5d96
EL_VOLUMEN_DEL_EFECTO:
	and 0f0h		;5d97
EFECTO_EVENTO:		; Nibble alto el volumen, nibble bajo y el byte siguiente el periodo
	ld b,a			;5d99   ; El nibble alto del byte es el volumen del efecto
	xor (hl)			;5d9a
	ld d,a			;5d9b
	inc hl			;5d9c   ; Y el byte siguiente completa el periodo por abajo
	ld e,(hl)			;5d9d
	inc hl			;5d9e
	ld (ix+003h),l		;5d9f   ; La pista se deja apuntando a lo que venga detras
	ld (ix+004h),h		;5da2
	ex de,hl			;5da5
	call PSG_PERIODO		;5da6   ; El periodo entero a los dos registros del canal
	ld a,b			;5da9
	rrca			;5daa
	rrca			;5dab
	rrca			;5dac
	rrca			;5dad
NOTA_ARRANCA:		; Deja la nota sonando con su duracion y su envolvente
	ld h,a			;5dae
	ld a,(ix+001h)		;5daf   ; +1 es la duracion fijada, +0 la cuenta atras
	ld (ix+000h),a		;5db2
	add a,003h		;5db5   ; +8 arranca tres por encima: la envolvente los gasta al principio
	ld (ix+008h),a		;5db7
	jr PSG_VOLUMEN		;5dba
CANAL_APAGA:		; Cierra el canal en el PSG y lo deja libre
	ld d,001h		;5dbc   ; Se cierra el canal en la mezcla del PSG
	call PSG_MEZCLA		;5dbe
	xor a			;5dc1
	ld (ix+002h),a		;5dc2   ; Y el numero de sonido a cero: el canal queda libre
	ld h,a			;5dc5
	jr PSG_VOLUMEN		;5dc6
SUENA_MUSICA:		; Como SUENA_CANAL, pero para las pistas de musica
	dec (ix+000h)		;5dc8
	jp z,SIGUIENTE_EVENTO		;5dcb
MUSICA_PASO:		; Descuenta la nota y baja el volumen segun la envolvente
	dec (ix+008h)		;5dce   ; +8 es la envolvente: mientras no coincida con lo que queda de nota, se baja
	ld a,(ix+008h)		;5dd1
	cp (ix+000h)		;5dd4
	jr nz,BAJA_DOS_VECES		;5dd7
	cp 003h		;5dd9   ; Los tres ultimos fotogramas de la nota tambien bajan
	jr c,BAJA_EL_VOLUMEN		;5ddb
	ret			;5ddd
BAJA_DOS_VECES:
	dec (ix+008h)		;5dde
BAJA_EL_VOLUMEN:
	ld a,(ix+007h)		;5de1   ; +7 es el volumen de ahora; a cero, se deja de bajar
	dec a			;5de4
	ret m			;5de5
	ld (ix+007h),a		;5de6
	ld h,a			;5de9
PSG_VOLUMEN:		; Manda el volumen H al registro 8, 9 o 10 del PSG
	ld a,c			;5dea
	rrca			;5deb   ; C vale 1, 3 o 5: un `rrca` y mas 0x88 da 8, 9 o 10
	add a,088h		;5dec
	out (0a0h),a		;5dee
	ld a,h			;5df0
	out (0a1h),a		;5df1
	ret			;5df3
MUSICA_EVENTO:		; Los eventos de una pista de musica
	cp 0fdh		;5df4   ; 0xFD: cambia la octava y el volumen de arranque
	jr nz,MUSICA_NOTA		;5df6
	inc hl			;5df8
	ld a,(hl)			;5df9
	and 007h		;5dfa   ; Los tres bits bajos, la octava, a +5
	ld (ix+005h),a		;5dfc
	xor (hl)			;5dff   ; El resto, bajado tres bits, es el volumen de arranque, a +6
	rrca			;5e00
	rrca			;5e01
	rrca			;5e02
	ld (ix+006h),a		;5e03
	inc hl			;5e06
	ld a,(hl)			;5e07
MUSICA_NOTA:		; Nibble bajo la nota, nibble alto el indice de duracion
	and 00fh		;5e08   ; Los cuatro bits bajos son la nota
	ld b,a			;5e0a
	xor (hl)			;5e0b
	inc hl			;5e0c
	ld (ix+003h),l		;5e0d   ; La pista queda apuntando al evento siguiente
	ld (ix+004h),h		;5e10
	rrca			;5e13
	rrca			;5e14
	rrca			;5e15
	rrca			;5e16
	ld hl,05e85h		;5e17   ; El nibble alto indexa la tabla de duraciones de 0x5E85
	call HL_MAS_A		;5e1a
	ld a,(hl)			;5e1d
	ld (ix+001h),a		;5e1e
	ld a,b			;5e21
	sub 00ch		;5e22   ; La nota 12 es silencio: se deja el volumen a cero y no se repone
	ld (ix+007h),a		;5e24
	jr z,MUSICA_PERIODO		;5e27
	ld a,(ix+006h)		;5e29   ; Y con nota de verdad, el volumen vuelve al de arranque
	ld (ix+007h),a		;5e2c
MUSICA_PERIODO:		; Busca el periodo de la nota y lo baja las octavas que haga falta
	call NOTA_ARRANCA		;5e2f
	ld a,b			;5e32
	ld hl,05e55h		;5e33   ; Los doce periodos de la octava mas alta, un byte cada uno
	call HL_MAS_A		;5e36
	ld l,(hl)			;5e39
	ld h,000h		;5e3a
	ld a,(ix+005h)		;5e3c   ; Sin octavas que bajar, el periodo va tal cual
	or a			;5e3f
	jr z,PSG_PERIODO		;5e40
	ld b,a			;5e42
BAJA_UNA_OCTAVA:
	add hl,hl			;5e43   ; Doblar el periodo es bajar una octava
	djnz BAJA_UNA_OCTAVA		;5e44
PSG_PERIODO:		; El periodo HL a los dos registros del canal C
	ld a,c			;5e46   ; El registro impar lleva el byte alto...
	out (0a0h),a		;5e47
	ld a,h			;5e49
	out (0a1h),a		;5e4a
	dec c			;5e4c   ; ...y el par de debajo, el bajo
	ld a,c			;5e4d
	out (0a0h),a		;5e4e
	ld a,l			;5e50
	out (0a1h),a		;5e51
	inc c			;5e53
	ret			;5e54

; ----------------------------------------------------------------------
; DATOS periodos_de_notas: Los doce periodos de la octava mas alta, un BYTE
;   cada uno (0x5E33 los lee con `ld l,(hl)`), y las octavas de abajo salen
;   doblando.
;   0x5e55..0x5e61  (12 bytes)
DATA_periodos_de_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 5e55  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS punteros_de_pista: Las palabras que dicen donde empieza cada pista.
;   OJO: la base que usa 0x5CD8 es 0x5E5F, dos bytes ANTES, asi que la entrada
;   0 cae sobre los dos ultimos periodos y el sonido numero 0 no se puede
;   pedir. La primera de verdad es la 1, en 0x5E61.
;   0x5e61..0x5e85  (36 bytes)
DATA_punteros_de_pista:
	defb 08ch,05fh	; 5e61
	defb 0a0h,05fh	; 5e63
	defb 01bh,05fh	; 5e65
	defb 04fh,05fh	; 5e67
	defb 095h,05fh	; 5e69
	defb 029h,05fh	; 5e6b
	defb 075h,05fh	; 5e6d
	defb 013h,05fh	; 5e6f
	defb 0cbh,05eh	; 5e71
	defb 0f0h,05eh	; 5e73
	defb 089h,05eh	; 5e75
	defb 0a9h,05eh	; 5e77
	defb 0a0h,05fh	; 5e79
	defb 0a8h,05eh	; 5e7b
	defb 0bfh,05fh	; 5e7d
	defb 0a8h,05eh	; 5e7f
	defb 0a8h,05eh	; 5e81
	defb 0a8h,05eh	; 5e83

; ----------------------------------------------------------------------
; DATOS duraciones_y_pistas: La tabla de duraciones que 0x5E17 indexa con el
;   nibble alto de la nota, y detras las pistas del PSG. Los punteros de
;   0x5E61 apuntan a pistas que empiezan DENTRO de ese primer tramo -0x5E89 y
;   0x5EA9-, asi que o las duraciones que se usan de verdad son pocas o esos
;   bytes sirven para las dos cosas: no esta cerrado. La ultima pista acaba en
;   0x5FF3 y los doce bytes que quedan hasta 0x5FFF son el unico relleno de
;   0xFF del cartucho; los otros dos huecos son de ceros, doce en la cabecera
;   (0x4004) y diez en 0x506D.
;   0x5e85..0x6000  (379 bytes)
DATA_duraciones_y_pistas:
	defb 008h,010h,018h,04fh,0fdh,062h,01ah,0fdh,061h,012h,025h,005h,007h,009h,00ah,0fdh	; 5e85  ...O.b..a.%.....
	defb 060h,000h,012h,0fdh,061h,01ah,0fdh,060h,023h,003h,012h,005h,003h,012h,010h,0fdh	; 5e95  `...a..`#.......
	defb 061h,01ah,03ch,0ffh,0fdh,063h,01ah,0fdh,062h,012h,025h,005h,007h,009h,00ah,0fdh	; 5ea5  a.<..c..b.%.....
	defb 061h,000h,012h,0fdh,062h,01ah,023h,003h,0fdh,063h,00ah,0fdh,062h,000h,002h,003h	; 5eb5  a...b.#..c..b...
	defb 015h,0fdh,063h,015h,01ah,0ffh,0fdh,062h,002h,003h,002h,005h,002h,003h,002h,005h	; 5ec5  ..c....b........
	defb 002h,003h,002h,005h,002h,003h,002h,005h,0fdh,061h,002h,003h,002h,005h,002h,003h	; 5ed5  .........a......
	defb 002h,005h,002h,003h,002h,005h,002h,003h,002h,005h,0ffh,0fdh,063h,002h,003h,002h	; 5ee5  ............c...
	defb 005h,002h,003h,002h,005h,002h,003h,002h,005h,002h,003h,002h,005h,002h,003h,002h	; 5ef5  ................
	defb 005h,002h,003h,002h,005h,002h,003h,002h,005h,002h,003h,002h,005h,0ffh,021h,011h	; 5f05  ..............!.
	defb 0b0h,06ch,061h,060h,0feh,0ffh,021h,0d1h,067h,0d0h,0beh,0d2h,03bh,0d0h,078h,022h	; 5f15  .la`..!.g...;.x"
	defb 000h,000h,0feh,004h,024h,0d1h,040h,0c1h,049h,0b1h,068h,0a1h,094h,091h,099h,081h	; 5f25  ....$.@.I.h.....
	defb 0ach,071h,0c5h,061h,0e0h,023h,000h,000h,0c1h,068h,0c1h,094h,0b1h,099h,0a1h,0ach	; 5f35  .q.a.#...h......
	defb 091h,0c5h,081h,0e0h,071h,0fdh,061h,01bh,0feh,0ffh,021h,0c0h,0b3h,0c0h,0a9h,0c0h	; 5f45  ....q.a...!.....
	defb 0a0h,0c0h,097h,0c0h,086h,0c0h,07fh,0c0h,078h,0c0h,071h,0c0h,06ah,0c0h,064h,0a0h	; 5f55  ........x.q.j.d.
	defb 05fh,090h,059h,080h,054h,070h,050h,060h,04bh,050h,047h,040h,043h,030h,03fh,0ffh	; 5f65  _.Y.TpP`KPG@C0?.
	defb 025h,0b3h,057h,0b3h,027h,0b2h,0fah,0b2h,0cfh,0b2h,0a7h,0b2h,080h,0b2h,05dh,0b2h	; 5f75  %.W.'.........].
	defb 03bh,0b1h,0fdh,0b1h,0e0h,0feh,0ffh,021h,011h,0e0h,040h,023h,090h,040h,0feh,002h	; 5f85  ;......!..@#.@..
	defb 024h,0d1h,01dh,0d0h,0d5h,0d0h,0a9h,0d0h,08eh,0feh,002h,022h,01bh,0e0h,034h,0e0h	; 5f95  $.........."..4.
	defb 074h,0d0h,0b4h,0d3h,0c0h,0c3h,0a0h,0c3h,0d0h,0b3h,0c0h,0a3h,0e0h,093h,0b0h,083h	; 5fa5  t...............
	defb 0d0h,073h,0a0h,063h,0b0h,063h,0d0h,063h,0f0h,0ffh,022h,01fh,0f3h,0a0h,0f3h,0c0h	; 5fb5  .s.c.c.c..".....
	defb 0f3h,0f0h,0e3h,0d0h,0e3h,0f0h,0e3h,0b0h,0e3h,0d0h,0d3h,0a0h,0d3h,0c0h,0d3h,0a0h	; 5fc5  ................
	defb 0c3h,0b0h,0c3h,0e0h,0b3h,0a0h,0b3h,0c0h,0a3h,0a0h,0a3h,0d0h,093h,0a0h,02ah,093h	; 5fd5  ..............*.
	defb 0c0h,063h,090h,083h,0a0h,053h,0b0h,073h,0c0h,043h,0d0h,063h,0e0h,053h,0f0h,0ffh	; 5fe5  .c...S.s.C.c.S..
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5ff5  ...........
