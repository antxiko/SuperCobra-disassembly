#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

La galeria de este proyecto tiene dos clases de imagen y estan separadas a
proposito:

  * las RECONSTRUIDAS -tiles.png, sprites.png, logo_konami.png- no son
    capturas: las dibuja tools/graficos.py repitiendo instruccion a instruccion
    los dos interpretes de dibujo del cartucho (0x4068 y 0x4AC6) sobre una
    memoria de video vacia. Si un rango estuviera mal etiquetado, saldria ruido.
  * las CAPTURAS -titulo.png, logotipo.png, partida.png- son pantallas reales
    de openMSX, sacadas sin tocar el teclado con tools/omsx_capturas.tcl.

El rotulo de la cabecera, logo.png, es el del propio juego: lo recorta
tools/recorta_rotulo.py de la captura del titulo. NO es el logotipo de Konami,
que va en la galeria con su nombre.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 8192 = 5783 + 2409, que es lo que imprime
# tools/presupuesto.py (make sanity).
CODIGO = 5783
DATOS = 2409
ESTADOS = 15                        # las quince palabras de la tabla de 0x46AD
SUBMODOS = 8                        # las ocho de la tabla de 0x516F


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Super Cobra — desensamblado comentado",
        aviso="<b>Aquí hay dos clases de imagen y no se mezclan.</b> Los "
              "tiles, los dibujos de sprite y el logotipo de Konami están "
              "<b>reconstruidos</b>: los dibuja una herramienta que repite, "
              "instrucción a instrucción, los dos intérpretes de dibujo del "
              "cartucho sobre una memoria de vídeo vacía. Las pantallas son "
              "<b>capturas de openMSX</b>, y lo dicen en el pie; el rótulo de "
              "aquí arriba está recortado de una de ellas. El listado y las "
              "cifras salen del binario y se reproducen con <code>make</code>.",
        claim="Ocho kilobytes en los que el hilo principal no hace nada: "
              "arranca, engancha la interrupción y se queda en un "
              "<code>jr $</code> para siempre. El juego entero cabe dentro "
              "del gancho de vídeo, repartido en quince estados y ocho "
              "trabajos que se turnan un fotograma cada uno.",
        ficha=["Konami · <b>©KONAMI 1983</b>",
               "Cartucho <b>RC-705</b>, 8 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>062aeefd…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(ESTADOS), "estados del juego"),
                (str(SUBMODOS), "trabajos que se turnan"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada pie está la dirección de donde sale, y si "
                 "la imagen es reconstruida o capturada.",
        pie_leg="Esto es trabajo de documentación y preservación: el "
                "código y los gráficos siguen siendo de sus autores y de "
                "Konami, y la imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Super Cobra — a commented disassembly",
        aviso="<b>There are two kinds of picture here and they are not "
              "mixed.</b> The tiles, the sprite drawings and the Konami logo "
              "are <b>reconstructed</b>: they are drawn by a tool that "
              "repeats, instruction by instruction, the cartridge's two "
              "drawing interpreters over an empty video memory. The screens "
              "are <b>openMSX screenshots</b>, and their captions say so; the "
              "title above is cropped from one of them. The listing and the "
              "numbers come from the binary and are reproducible with "
              "<code>make</code>.",
        claim="Eight kilobytes in which the main thread does nothing: it "
              "starts up, hooks the interrupt and settles into a "
              "<code>jr $</code> forever. The whole game fits inside the "
              "video hook, split into fifteen states and eight jobs that take "
              "turns, one frame each.",
        ficha=["Konami · <b>©KONAMI 1983</b>",
               "An <b>RC-705</b> 8 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>062aeefd…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(ESTADOS), "game states"),
                (str(SUBMODOS), "jobs taking turns"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each caption is the address it comes from, and "
                 "whether the picture is reconstructed or captured.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Con Frogger, de 1983 y de 8 KB como este, no comparte ni un byte seguido",
         "<p><code>tools/comun_konami.py</code> indexa todos los trozos de "
         "doce bytes de un cartucho y los busca en el otro, estirando cada "
         "coincidencia hasta donde llega. Con el umbral de la herramienta "
         "—24 bytes seguidos— Super Cobra da <b>400 bytes en común con "
         "Athletic Land</b>, 287 con Monkey Academy, 239 con Antarctic "
         "Adventure… y <b>cero con Frogger</b>.</p>"
         "<p>Los 28 bytes que salen contra Time Pilot tampoco son código: son "
         "el logotipo KONAMI pequeño de 0x43BE, un dibujo. Konami tenía dos "
         "armazones distintos a la vez, y estos dos cartuchos de 1983 son uno "
         "de cada.</p>"),
        ("El reproductor de sonido no está copiado de Athletic Land: está revisado",
         "<p>Es lo más grande que comparten los dos, y <b>no hay un "
         "desplazamiento único que los alinee</b>. Bajando el umbral a ocho "
         "bytes, de los 320 de 0x5D30–0x5E70 hay <b>177 —el 55,3 %— dentro de "
         "una tira idéntica</b>, repartidos en seis tiras cuyos "
         "desplazamientos van de 0x1B0B a 0x1B28.</p>"
         "<p>Un desplazamiento que se mueve 29 bytes a lo largo del mismo "
         "bloque es la firma de un código al que le han metido y quitado "
         "trozos por el medio, no de un copia y pega.</p>"),
        ("Las letras del juego no están en el cartucho",
         "<p><code>SUBE_FUENTE</code> (0x4AA0) hace <code>ld hl,(00004h)</code>. "
         "Esa dirección es <b>CGTBL</b>, el puntero a la fuente que la ROM del "
         "BASIC guarda ahí, y de ella se suben 0x180 bytes: 48 caracteres, del "
         "<code>0</code> al <code>_</code>.</p>"
         "<p>Ni las cifras del marcador ni las palabras del menú son dibujos "
         "de Konami. Y se suben <b>dos veces</b>, con dos desplazamientos y "
         "dos colores distintos, porque en SCREEN 2 el color va por línea de "
         "patrón y el mismo carácter no puede tener dos colores.</p>"),
        ("La misma rutina pinta y borra, según por dónde entres",
         "<p><code>PINTA_DIBUJO</code> está en 0x4068 y <code>BORRA_DIBUJO</code> "
         "dos bytes antes, en 0x4064. La única diferencia es lo que cargan en "
         "C: 0xFF una y 0x00 la otra. Abajo, en el bucle, hay un "
         "<code>and c</code> (0x4076) que con 0xFF deja el byte tal cual y con "
         "0x00 lo convierte en cero.</p>"
         "<p>El juego lo usa así de verdad: el cartel INVASION SUCCEEDED se "
         "pinta entrando por 0x4068 y se quita entrando por 0x4064. Y con los "
         "submodos pasa lo mismo: el 2 entra en 0x5275 y el 4 en 0x5278, tres "
         "instrucciones más adentro, saltándose el <code>call</code> que mueve "
         "la llama del motor.</p>"),
        ("Cuatro tablas que empiezan dentro de una instrucción",
         "<p>No es un error de lectura, y no es una: son cuatro. La tabla de "
         "los desplazamientos de la explosión (0x566B) arranca sobre el "
         "operando del <code>jp</code> de 0x566A; la de cuántos salen por zona "
         "(0x58D6), sobre el del <code>jp</code> de 0x58D5; la de los márgenes "
         "de la bomba (0x55D3), sobre un <code>call</code> y un "
         "<code>scf</code>/<code>ret</code>.</p>"
         "<p>En las tres, las entradas que caen encima del código <b>no se "
         "pueden usar</b>: el índice nunca llega a valer lo que haría falta "
         "para leerlas.</p>"
         "<p>La cuarta es más fea. <code>SONIDO_PISTAS</code> (0x5CD8) usa "
         "como base 0x5E5F, <b>dos bytes antes</b> de la primera palabra de "
         "verdad: la entrada 0 se monta sobre los dos últimos periodos de nota "
         "y apunta a 0x383C, fuera del cartucho. El sonido número 0 no se "
         "puede pedir, y nadie lo pide.</p>"),
        ("Un despachador que no vuelve, y dos rutinas que nadie llama",
         "<p><code>DESPACHA</code> (0x4050) no lleva la tabla aparte: hace "
         "<code>pop hl</code> para quedarse con la dirección de retorno y "
         "usarla de base, así que la tabla va <b>pegada detrás del "
         "<code>call</code></b> y no se vuelve nunca a él. Termina en "
         "<code>jp (hl)</code>.</p>"
         "<p>Eso tiene una consecuencia: el <code>ret</code> de la rutina "
         "despachada no vuelve al despachador, vuelve a lo que hubiera dejado "
         "el llamador en la pila. 0x4691 se aprovecha haciendo un "
         "<code>push hl</code> antes de despachar, y por eso 0x488B y 0x49EA "
         "se ejecutan <b>sin que ninguna instrucción las llame</b>.</p>"),
        ("Siete bytes que se ejecutan en la RAM porque el Z80 no sabe hacerlo",
         "<p>0x412B copia siete bytes de 0x41DD a 0xE5F8 y desde entonces se "
         "los llama como rutina:</p>"
         "<p><code>ld (0E5FDh),a &nbsp;·&nbsp; ld (ix+000h),b &nbsp;·&nbsp; ret</code></p>"
         "<p>0xE5FD <b>es el tercer byte del <code>ld (ix+000h),b</code></b>, o "
         "sea su propio desplazamiento: la rutina se lo escribe encima con A y "
         "entonces guarda B. Es <code>ld (IX+A),B</code>, que no existe, porque "
         "el desplazamiento de IX es un byte fijo del opcode y no un registro. "
         "Son los <b>únicos siete bytes del cartucho que no corren desde la "
         "ROM</b>.</p>"),
        ("Este cartucho no lleva la marca oculta de Konami",
         "<p>Manuel Pazos descubrió que los cartuchos de Konami esconden al "
         "final de la ROM su número de catálogo RC-7xx y el título en "
         "katakana. <b>Aquí no está.</b></p>"
         "<p>El último byte con contenido es 0x5FF3 —el final de la última "
         "pista de sonido— y de 0x5FF4 a 0x5FFF hay doce bytes de 0xFF y nada "
         "más. El «RC-705» de esta web sale del catálogo, no del binario.</p>"),
        ("El contador de refresco de la memoria, usado de dado",
         "<p><code>PUNTOS_DE_PREMIO</code> (0x501E) necesita un número al azar "
         "y no tiene generador. Usa <b>el registro R del Z80</b>, el contador "
         "de refresco de la memoria dinámica, que sube solo con cada "
         "instrucción que se ejecuta: sus dos bits bajos dan 0, 1, 2 o 3, y "
         "eso va al byte alto del premio. Salen 0, 100, 200 o 300 puntos.</p>"),
    ],
    "en": [
        ("With Frogger, from 1983 and 8 KB like this one, it shares no run of bytes",
         "<p><code>tools/comun_konami.py</code> indexes every twelve-byte chunk "
         "of one cartridge and looks for it in the other, stretching each match "
         "as far as it goes. With the tool's threshold —24 bytes in a row— "
         "Super Cobra gives <b>400 bytes in common with Athletic Land</b>, 287 "
         "with Monkey Academy, 239 with Antarctic Adventure… and <b>zero with "
         "Frogger</b>.</p>"
         "<p>The 28 bytes that turn up against Time Pilot are not code either: "
         "they are the small KONAMI logo at 0x43BE, a drawing. Konami had two "
         "different frameworks running at once, and these two 1983 cartridges "
         "are one of each.</p>"),
        ("The sound player is not copied from Athletic Land: it is revised",
         "<p>It is the biggest thing the two share, and <b>there is no single "
         "offset that aligns them</b>. Dropping the threshold to eight bytes, "
         "of the 320 in 0x5D30–0x5E70 there are <b>177 —55.3 %— inside an "
         "identical run</b>, spread over six runs whose offsets range from "
         "0x1B0B to 0x1B28.</p>"
         "<p>An offset that drifts 29 bytes along the same block is the "
         "signature of code with pieces added and removed in the middle, not "
         "of a copy and paste.</p>"),
        ("The game's letters are not in the cartridge",
         "<p><code>SUBE_FUENTE</code> (0x4AA0) does <code>ld hl,(00004h)</code>. "
         "That address is <b>CGTBL</b>, the pointer to the font the BASIC ROM "
         "keeps there, and 0x180 bytes are uploaded from it: 48 characters, "
         "from <code>0</code> to <code>_</code>.</p>"
         "<p>Neither the score digits nor the menu words are Konami artwork. "
         "And they are uploaded <b>twice</b>, at two different offsets and in "
         "two different colours, because in SCREEN 2 colour goes per pattern "
         "line and the same character cannot have two colours.</p>"),
        ("The same routine draws or erases, depending on where you enter",
         "<p><code>PINTA_DIBUJO</code> is at 0x4068 and <code>BORRA_DIBUJO</code> "
         "two bytes earlier, at 0x4064. The only difference is what they load "
         "into C: 0xFF one, 0x00 the other. Down in the loop there is an "
         "<code>and c</code> (0x4076) which with 0xFF leaves the byte alone and "
         "with 0x00 turns it into zero.</p>"
         "<p>The game really uses it that way: the INVASION SUCCEEDED banner is "
         "drawn by entering at 0x4068 and taken away by entering at 0x4064. And "
         "the same goes for the submodes: 2 enters at 0x5275 and 4 at 0x5278, "
         "three instructions further in, skipping the <code>call</code> that "
         "moves the engine flame.</p>"),
        ("Four tables that start inside an instruction",
         "<p>It is not a misreading, and it is not one: there are four. The "
         "explosion offset table (0x566B) starts on the operand of the "
         "<code>jp</code> at 0x566A; the how-many-per-zone one (0x58D6), on "
         "that of the <code>jp</code> at 0x58D5; the bomb margins one (0x55D3), "
         "on a <code>call</code> and an <code>scf</code>/<code>ret</code>.</p>"
         "<p>In all three, the entries that land on top of code <b>cannot be "
         "used</b>: the index never reaches the value it would take to read "
         "them.</p>"
         "<p>The fourth is uglier. <code>SONIDO_PISTAS</code> (0x5CD8) uses "
         "0x5E5F as its base, <b>two bytes before</b> the first real word: "
         "entry 0 sits on the last two note periods and points at 0x383C, "
         "outside the cartridge. Sound number 0 cannot be requested, and nobody "
         "requests it.</p>"),
        ("A dispatcher that never returns, and two routines nobody calls",
         "<p><code>DESPACHA</code> (0x4050) does not keep its table apart: it "
         "does a <code>pop hl</code> to take the return address and use it as a "
         "base, so the table sits <b>right behind the <code>call</code></b> and "
         "is never returned to. It ends in <code>jp (hl)</code>.</p>"
         "<p>That has a consequence: the <code>ret</code> of the dispatched "
         "routine does not go back to the dispatcher, it goes back to whatever "
         "the caller left on the stack. 0x4691 exploits that with a "
         "<code>push hl</code> before dispatching, and that is why 0x488B and "
         "0x49EA run <b>without a single instruction calling them</b>.</p>"),
        ("Seven bytes that run in RAM because the Z80 cannot do it",
         "<p>0x412B copies seven bytes from 0x41DD to 0xE5F8 and calls them as a "
         "routine from then on:</p>"
         "<p><code>ld (0E5FDh),a &nbsp;·&nbsp; ld (ix+000h),b &nbsp;·&nbsp; ret</code></p>"
         "<p>0xE5FD <b>is the third byte of the <code>ld (ix+000h),b</code></b>, "
         "that is, its own displacement: the routine writes it over itself with "
         "A and then stores B. It is <code>ld (IX+A),B</code>, which does not "
         "exist, because IX's displacement is a fixed byte of the opcode and "
         "not a register. Those are the <b>only seven bytes of the cartridge "
         "that do not run from ROM</b>.</p>"),
        ("This cartridge does not carry Konami's hidden mark",
         "<p>Manuel Pazos found that Konami cartridges hide their RC-7xx "
         "catalogue number and the katakana title at the end of the ROM. "
         "<b>It is not here.</b></p>"
         "<p>The last byte with content is 0x5FF3 —the end of the last sound "
         "track— and from 0x5FF4 to 0x5FFF there are twelve 0xFF bytes and "
         "nothing else. The \"RC-705\" on this site comes from the catalogue, "
         "not from the binary.</p>"),
        ("The memory refresh counter, used as a dice",
         "<p><code>PUNTOS_DE_PREMIO</code> (0x501E) needs a random number and "
         "has no generator. It uses <b>the Z80's R register</b>, the dynamic "
         "memory refresh counter, which climbs by itself with every instruction "
         "executed: its low two bits give 0, 1, 2 or 3, and that goes into the "
         "high byte of the prize. Out come 0, 100, 200 or 300 points.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "CAPTURA de openMSX — la pantalla del título y el menú, montada por el "
     "estado 04 y el 06. Las teclas 1 y 2 juegan con joystick, la 3 y la 4 con "
     "el teclado; lo que eligen son dos bits de 0xE002",
     "openMSX SCREENSHOT — the title screen and menu, built by states 04 and "
     "06. Keys 1 and 2 play with a joystick, 3 and 4 with the keyboard; what "
     "they pick is two bits of 0xE002"),
    ("partida.png",
     "CAPTURA de openMSX — una zona en marcha: el decorado que corre a doble "
     "búfer desde 0xE800, el marcador de arriba y la barra de combustible de "
     "0x4F7C",
     "openMSX SCREENSHOT — a zone in progress: the terrain scrolling "
     "double-buffered from 0xE800, the scoreboard on top and the fuel gauge "
     "from 0x4F7C"),
    ("logotipo.png",
     "CAPTURA de openMSX — el estado 01, cazado a medias: SUBE_LOGOTIPO "
     "(0x4CBF) sube el KONAMI de abajo arriba, una fila de 32 bytes cada dos "
     "fotogramas",
     "openMSX SCREENSHOT — state 01, caught halfway: SUBE_LOGOTIPO (0x4CBF) "
     "raises the KONAMI from the bottom up, one 32-byte row every two frames"),
    ("tiles.png",
     "RECONSTRUIDA de 0x4248 — los 256 tiles del tercio de arriba con su "
     "color, tal como los deja MONTA_EL_TITULO. Los grises son los que el "
     "cartucho no trae: ahí caen las letras que se copian de la BIOS",
     "RECONSTRUCTED from 0x4248 — the 256 tiles of the top third with their "
     "colour, as MONTA_EL_TITULO leaves them. The grey ones are what the "
     "cartridge does not carry: that is where the BIOS letters land"),
    ("sprites.png",
     "RECONSTRUIDA de 0x443A — los dibujos de sprite de 16×16. Ese flujo es lo "
     "único de todo el cartucho que escribe en la VRAM 0x1800, que es donde el "
     "registro 6 del VDP pone la tabla de patrones de sprite",
     "RECONSTRUCTED from 0x443A — the 16×16 sprite drawings. That stream is "
     "the only thing in the whole cartridge writing to VRAM 0x1800, which is "
     "where VDP register 6 puts the sprite pattern table"),
    ("logo_konami.png",
     "RECONSTRUIDA de 0x4CFA — los 26 tiles del KONAMI grande, 147 bytes "
     "idénticos a los de Athletic Land, montados como los monta el cartucho: "
     "tres tiles arriba, once en medio y doce abajo",
     "RECONSTRUCTED from 0x4CFA — the 26 tiles of the big KONAMI, 147 bytes "
     "identical to Athletic Land's, laid out the way the cartridge lays them: "
     "three tiles on top, eleven in the middle and twelve below"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El rotulo del JUEGO, no el de Konami: logo.png lo recorta
    # tools/recorta_rotulo.py de la captura del titulo.
    ruta_logo = os.path.join(imgdir, "logo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Super Cobra">'
                if os.path.exists(ruta_logo) else "<h1>Super Cobra</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
