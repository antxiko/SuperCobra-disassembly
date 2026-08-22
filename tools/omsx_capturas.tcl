# Saca las capturas de la web sin que nadie tenga que tocar el teclado.
#
# Arranca el cartucho, deja pasar el tiempo que hace falta en cada sitio y
# guarda un PNG: la pantalla del titulo, el menu de PLAY SELECT y la partida.
#
# Uso:
#   openmsx -machine Philips_VG_8020 -cart supercobra.rom \
#           -script tools/omsx_capturas.tcl
#
# LAS DOS TRAMPAS DE LAS CAPTURAS, las dos silenciosas:
#   1. lanzado con -script, el `renderer` arranca en `uninitialized` y
#      `screenshot` contesta rc=0 y escribe un PNG NEGRO. Se enciende con
#      `set renderer SDLGL-PP`.
#   2. con el acelerador quitado el renderizador se salta todos los cuadros y
#      sigue saliendo negra. Hay que esperar en tiempo REAL y con el acelerador
#      puesto.
# Un PNG negro pesa ~1 KB y uno bueno mas de 5 KB: el tamano ya avisa.

set SALIDA work/gfx
file mkdir $SALIDA
set L [open "work/omsx_capturas.log" w]
proc say {m} { global L; puts $L [format "\[%8.2f\] %s" [machine_info time] $m]; flush $L; puts $m }

set renderer SDLGL-PP
set throttle on

proc tecla {t {ms 300}} {
    type $t
    after realtime [expr {$ms / 1000.0}] {}
}

proc captura {nombre} {
    global SALIDA
    set f [file join $SALIDA $nombre]
    screenshot -raw $f
    set n [file size $f]
    say [format "%-24s %6d bytes" $nombre $n]
    if {$n < 2000} { say "  AVISO: ese PNG es sospechosamente pequeno, mira si esta negro" }
}

# La secuencia va en cadena de `after realtime`: cada paso llama al siguiente,
# asi que no hay que adivinar cuanto tarda todo junto. Los instantes salen de
# mirar el juego: el logotipo KONAMI sube fila a fila y tarda lo suyo, y la
# pantalla del titulo se queda un rato antes de pasar al menu.
proc paso_intro {} {
    captura "intro.png"
    after realtime 5 paso_titulo
}
proc paso_titulo {} {
    captura "titulo.png"
    after realtime 5 paso_menu
}
proc paso_menu {} {
    captura "menu.png"
    # La fila 0 del teclado es la de las cifras, y 0x48AC las traduce: el 1
    # arranca la partida de un jugador con joystick.
    type 1
    after realtime 12 paso_partida
}
proc paso_partida {} {
    captura "partida.png"
    after realtime 8 paso_partida2
}
proc paso_partida2 {} {
    captura "partida2.png"
    say "hecho"
    exit
}

say "arrancando; renderer=[set renderer]"
after realtime 5 paso_intro
