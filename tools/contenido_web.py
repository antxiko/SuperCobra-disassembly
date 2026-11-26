#!/usr/bin/env python3
"""EL CONTENIDO de la web de este juego: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.
"""

NOMBRE = 'Super Cobra'
EDITOR = ''
ANIO = 1983
REPOSITORIO = 'https://github.com/antxiko/SuperCobra-disassembly'

CODIGO = 5783
DATOS = 2409
ESTADOS = 15
ESTILO = '\n:root{--tinta:#cfd0d4;--suave:#83868f;--fondo:#000;--panel:#0c0e13;--linea:#23262e;\n  --rojo:#ff897d;--cyan:#65dbef;--verde:#3eb849;--oro:#ded087}\n@media (prefers-color-scheme:light){:root{--tinta:#191a1e;--suave:#5a5d66;--fondo:#e9e7e1;\n  --panel:#f7f6f2;--linea:#d0cdc5;--rojo:#b23f34;--cyan:#1c6b7c;--verde:#2b7734;--oro:#8a7420}}\n:root[data-theme="dark"]{--tinta:#cfd0d4;--suave:#83868f;--fondo:#000;--panel:#0c0e13;\n  --linea:#23262e;--rojo:#ff897d;--cyan:#65dbef;--verde:#3eb849;--oro:#ded087}\n:root[data-theme="light"]{--tinta:#191a1e;--suave:#5a5d66;--fondo:#e9e7e1;--panel:#f7f6f2;\n  --linea:#d0cdc5;--rojo:#b23f34;--cyan:#1c6b7c;--verde:#2b7734;--oro:#8a7420}\n*{box-sizing:border-box}\nbody{margin:0;background:var(--fondo);color:var(--tinta);padding:0 1.25rem 6rem;\n  font:15px/1.7 ui-monospace,"SF Mono",Menlo,Consolas,monospace}\n.w{max-width:1120px;margin:0 auto}\n.n{max-width:68ch}\nh1,h2,h3,h4{font-weight:400;text-wrap:balance}\na{color:var(--cyan)}\nimg{image-rendering:pixelated;max-width:100%;height:auto;display:block}\nheader.top{display:flex;flex-direction:column;align-items:center;gap:1.5rem;\n  padding:4rem 0 2rem;text-align:center}\nheader.top img{width:min(100%,642px)}\n.claim{max-width:60ch;color:var(--suave);font-size:1.05rem}\n.claim b{color:var(--tinta);font-weight:400}\n.ficha{display:flex;flex-wrap:wrap;justify-content:center;gap:0 1.5rem;width:100%;\n  font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--suave);\n  border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);padding:.85rem 0}\n.ficha b{color:var(--rojo);font-weight:400}\nnav{display:flex;flex-wrap:wrap;gap:1.25rem;justify-content:center;padding:1.25rem 0;\n  font-size:12px;letter-spacing:.08em;text-transform:uppercase}\nnav a{color:var(--suave);text-decoration:none;border-bottom:1px solid transparent}\nnav a:hover,nav a:focus{color:var(--tinta);border-bottom-color:var(--rojo)}\nnav.docs{border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);\n  margin-bottom:1rem}\nsection{margin-top:4.5rem;scroll-margin-top:1rem}\nsection>h2{font-size:1rem;letter-spacing:.1em;text-transform:uppercase;\n  border-left:3px solid var(--rojo);padding-left:.9rem;margin:0 0 1.5rem}\n.cifras{display:grid;gap:1px;background:var(--linea);border:1px solid var(--linea);\n  grid-template-columns:repeat(auto-fit,minmax(160px,1fr))}\n.cifra{background:var(--panel);padding:1.1rem}\n.cifra b{display:block;font-size:1.7rem;color:var(--oro);font-weight:400;\n  font-variant-numeric:tabular-nums;line-height:1.2}\n.cifra span{font-size:11px;letter-spacing:.07em;text-transform:uppercase;color:var(--suave)}\n.hall{border-top:1px solid var(--linea);padding-top:1.75rem;margin-top:2.5rem}\n.hall:first-of-type{border-top:0;padding-top:0;margin-top:0}\n.hall h3{margin:0 0 .75rem;font-size:1.15rem;color:var(--rojo)}\n.hall h4{color:var(--oro);margin:1.5rem 0 .5rem;font-size:.95rem}\n.hall p{margin:0 0 1rem}\npre.asm{background:var(--panel);border-left:2px solid var(--verde);margin:1.25rem 0;\n  padding:1rem 1.1rem;overflow-x:auto;font-size:13px;line-height:1.6;color:var(--tinta)}\n.par{display:grid;gap:1.25rem;grid-template-columns:1fr}\n@media(min-width:820px){.par{grid-template-columns:1fr 1fr}}\n.par figure{margin:0}\ntable{border-collapse:collapse;width:100%;margin:1.25rem 0;font-size:13px;display:block;\n  overflow-x:auto}\nth,td{text-align:left;padding:.5rem .75rem;border-bottom:1px solid var(--linea)}\nth{color:var(--suave);font-weight:400;font-size:11px;letter-spacing:.07em;text-transform:uppercase}\ntd.num{font-variant-numeric:tabular-nums;color:var(--oro)}\n.nivel{margin-top:2rem}\n.nivel h3{margin:0 0 .9rem;font-size:.95rem;letter-spacing:.06em;text-transform:uppercase}\n.nivel em{color:var(--cyan);font-style:normal}\n.sep{color:var(--suave);margin:0 .6rem}\n.rejilla{display:grid;gap:.9rem;grid-template-columns:repeat(auto-fill,minmax(250px,1fr))}\n.rejilla figure{margin:0;background:var(--panel);box-shadow:0 0 0 1px var(--linea)}\n.rejilla figcaption{display:flex;justify-content:space-between;padding:.45rem .65rem;\n  font-size:11px;color:var(--suave);border-top:1px solid var(--linea)}\n.dir{font-variant-numeric:tabular-nums;color:var(--verde)}\nfooter{margin-top:5rem;padding-top:1.5rem;border-top:1px solid var(--linea);\n  color:var(--suave);font-size:12px}\n\n/* Aviso de trabajo en curso: tiene que verse antes que las cifras, porque un\n   100% mal leido hace mas dano que no ponerlo. */\n.aviso{background:#3a2a10;border-left:3px solid var(--oro);margin:1.5rem auto;\n  padding:1rem 1.2rem;max-width:900px;border-radius:4px}\n.aviso p{margin:0;color:var(--tinta);font-size:15px;line-height:1.65}\n.galeria{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));\n  gap:1.5rem;margin:1.5rem 0}\n.galeria figure{margin:0}\n.galeria img{width:100%;height:auto;image-rendering:pixelated;\n  border:1px solid var(--linea);border-radius:3px}\n.galeria figcaption{color:var(--suave);font-size:13px;margin-top:.5rem}\naudio{display:block;width:100%;max-width:640px;margin:.75rem 0 1.5rem}\n'
SUBMODOS = 8

PIE_LEGAL = {'es': '<em>Super Cobra</em> lo publico Konami para MSX; su numero de catalogo es RC-705 y son 8 KB. Todos los derechos sobre el juego siguen siendo de sus titulares. Este trabajo es de preservacion, estudio y documentacion.', 'en': '<em>Super Cobra</em> was published by Konami for the MSX; its catalogue number is RC-705 and it is 8 KB. All rights in the game remain with their holders. This is preservation, study and documentation work.'}

PORTADA = {
    'es': dict(
        titulo='Super Cobra — desensamblado comentado',
        claim='Ocho kilobytes en los que el hilo principal no hace nada: arranca, engancha la interrupción y se queda en un <code>jr $</code> para siempre. El juego entero cabe dentro del gancho de vídeo, repartido en quince estados y ocho trabajos que se turnan un fotograma cada uno.',
        ficha=['Konami · <b>©KONAMI 1983</b>', 'Cartucho <b>RC-705</b>, 8 KB', 'MSX1 · <b>página 1</b>', 'Volcado <b>062aeefd…</b>'],
        h_num='El cartucho en cifras',
        cifras=[("100 %", "del binario explicado"),
                ("15", "estados del juego"),
                ("8", "trabajos que se turnan"),
                ("5.783", "bytes de código"),
                ("2.409", "bytes de datos"),
                ("0", "bytes sin identificar")],
        pie_leg='Esto es trabajo de documentación y preservación: el código y los gráficos siguen siendo de sus autores y de Konami, y la imagen del cartucho no se distribuye.',
        aviso='<b>Aquí hay dos clases de imagen y no se mezclan.</b> Los tiles, los dibujos de sprite y el logotipo de Konami están <b>reconstruidos</b>: los dibuja una herramienta que repite, instrucción a instrucción, los dos intérpretes de dibujo del cartucho sobre una memoria de vídeo vacía. Las pantallas son <b>capturas de openMSX</b>, y lo dicen en el pie; el rótulo de aquí arriba está recortado de una de ellas. El listado y las cifras salen del binario y se reproducen con <code>make</code>.',
    ),
    'en': dict(
        titulo='Super Cobra — a commented disassembly',
        claim='Eight kilobytes in which the main thread does nothing: it starts up, hooks the interrupt and settles into a <code>jr $</code> forever. The whole game fits inside the video hook, split into fifteen states and eight jobs that take turns, one frame each.',
        ficha=['Konami · <b>©KONAMI 1983</b>', 'An <b>RC-705</b> 8 KB cartridge', 'MSX1 · <b>page 1</b>', 'Dump <b>062aeefd…</b>'],
        h_num='The cartridge in numbers',
        cifras=[("100%", "of the binary explained"),
                ("15", "game states"),
                ("8", "jobs taking turns"),
                ("5,783", "bytes of code"),
                ("2,409", "bytes of data"),
                ("0", "bytes unidentified")],
        pie_leg='This is documentation and preservation work: the code and artwork still belong to their authors and to Konami, and the cartridge image is not distributed.',
        aviso="<b>There are two kinds of picture here and they are not mixed.</b> The tiles, the sprite drawings and the Konami logo are <b>reconstructed</b>: they are drawn by a tool that repeats, instruction by instruction, the cartridge's two drawing interpreters over an empty video memory. The screens are <b>openMSX screenshots</b>, and their captions say so; the title above is cropped from one of them. The listing and the numbers come from the binary and are reproducible with <code>make</code>.",
    ),
}

PAGINAS = [
    [('THE-GAME.html', 'EL-JUEGO.html', 'The game', 'El juego',
      'what the game is and how it plays',
      'qu&eacute; es el juego y c&oacute;mo se juega'),
     ('THE-PICTURES.html', 'LAS-IMAGENES.html', 'What the cartridge draws', 'Lo que el cartucho dibuja',
      'every picture drawn from the ROM, with its caption',
      'todas las im&aacute;genes dibujadas desde la ROM, con su pie'),
     ('THE-MUSIC.html', 'LA-MUSICA.html', 'The music', 'La m&#250;sica',
      'the tunes, from its own sound engine',
      'las m&uacute;sicas, de su propio motor de sonido')],
    [('CURIOSITIES.html', 'CURIOSIDADES.html', 'Curiosities', 'Curiosidades',
      'what turned up when taking it apart, and what is still open',
      'lo que apareci&oacute; al desmontarlo y lo que queda abierto')],
    [('UNDER-THE-HOOD.html', 'POR-DENTRO.html', 'Under the hood', 'Por dentro',
      'getting started, the cartridge and the code',
      'empezar, el cartucho y el c&oacute;digo')],
]

VIEJAS = {
    'FINDINGS.html': 'CURIOSITIES.html',
    'HALLAZGOS.html': 'CURIOSIDADES.html',
    'GETTING-STARTED.html': 'UNDER-THE-HOOD.html',
    'EMPEZAR.html': 'POR-DENTRO.html',
    'OPEN-QUESTIONS.html': 'CURIOSITIES.html',
    'PREGUNTAS-ABIERTAS.html': 'CURIOSIDADES.html',
    'THE-CARTRIDGE.html': 'UNDER-THE-HOOD.html',
    'EL-CARTUCHO.html': 'POR-DENTRO.html',
    'THE-CODE.html': 'UNDER-THE-HOOD.html',
    'EL-CODIGO.html': 'POR-DENTRO.html',
}

LOGOTIPO = 'logo.png'

# Los pies de las imagenes de la galeria: (imagen, pie en castellano, pie en ingles)
GALERIA = [('titulo.png',
  'CAPTURA de openMSX — la pantalla del título y el menú, montada por el estado 04 y el 06. Las '
  'teclas 1 y 2 juegan con joystick, la 3 y la 4 con el teclado; lo que eligen son dos bits de '
  '0xE002',
  'openMSX SCREENSHOT — the title screen and menu, built by states 04 and 06. Keys 1 and 2 play '
  'with a joystick, 3 and 4 with the keyboard; what they pick is two bits of 0xE002'),
 ('partida.png',
  'CAPTURA de openMSX — una zona en marcha: el decorado que corre a doble búfer desde 0xE800, el '
  'marcador de arriba y la barra de combustible de 0x4F7C',
  'openMSX SCREENSHOT — a zone in progress: the terrain scrolling double-buffered from 0xE800, the '
  'scoreboard on top and the fuel gauge from 0x4F7C'),
 ('logotipo.png',
  'CAPTURA de openMSX — el estado 01, cazado a medias: SUBE_LOGOTIPO (0x4CBF) sube el KONAMI de '
  'abajo arriba, una fila de 32 bytes cada dos fotogramas',
  'openMSX SCREENSHOT — state 01, caught halfway: SUBE_LOGOTIPO (0x4CBF) raises the KONAMI from '
  'the bottom up, one 32-byte row every two frames'),
 ('tiles.png',
  'RECONSTRUIDA de 0x4248 — los 256 tiles del tercio de arriba con su color, tal como los deja '
  'MONTA_EL_TITULO. Los grises son los que el cartucho no trae: ahí caen las letras que se copian '
  'de la BIOS',
  'RECONSTRUCTED from 0x4248 — the 256 tiles of the top third with their colour, as '
  'MONTA_EL_TITULO leaves them. The grey ones are what the cartridge does not carry: that is where '
  'the BIOS letters land'),
 ('sprites.png',
  'RECONSTRUIDA de 0x443A — los dibujos de sprite de 16×16. Ese flujo es lo único de todo el '
  'cartucho que escribe en la VRAM 0x1800, que es donde el registro 6 del VDP pone la tabla de '
  'patrones de sprite',
  'RECONSTRUCTED from 0x443A — the 16×16 sprite drawings. That stream is the only thing in the '
  'whole cartridge writing to VRAM 0x1800, which is where VDP register 6 puts the sprite pattern '
  'table'),
 ('mapa_zona01.png',
  'VOLADA — la zona 1 entera, sus 485 columnas, con los cohetes y los depósitos donde el cartucho '
  'los pone. No está leída de la ROM, porque no está guardada en la ROM: '
  '<code>tools/mapa.py</code> ejecuta el cartucho en un intérprete de Z80 escrito en Python, juega '
  'la partida y va guardando la columna que entra por la derecha en cada paso de scroll',
  'FLOWN — the whole of zone 1, its 485 columns, with the rockets and the fuel tanks where the '
  'cartridge puts them. It is not read from the ROM, because it is not stored in the ROM: '
  '<code>tools/mapa.py</code> runs the cartridge on a Z80 interpreter written in Python, plays the '
  'game, and saves the column that comes in from the right on every scroll step'),
 ('logo_konami.png',
  'RECONSTRUIDA de 0x4CFA — los 26 tiles del KONAMI grande, 147 bytes idénticos a los de Athletic '
  'Land, montados como los monta el cartucho: tres tiles arriba, once en medio y doce abajo',
  'RECONSTRUCTED from 0x4CFA — the 26 tiles of the big KONAMI, 147 bytes identical to Athletic '
  "Land's, laid out the way the cartridge lays them: three tiles on top, eleven in the middle and "
  'twelve below')]
