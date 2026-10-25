#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado.

Ninguna de estas necesita el cartucho: se hacen sobre src/supercobra.asm y
src/supercobra.notes. Lo que vigilan es que el listado
no se degrade sin que nadie se entere: que no desaparezcan comentarios, que no
vuelvan a aparecer bloques de datos sin identificar, y que las cifras que se
publican sean las del arbol.
"""
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "supercobra.asm")
NOTES = os.path.join(RAIZ, "src", "supercobra.notes")
DOCS = os.path.join(RAIZ, "docs")
OTROS_JUEGOS = ("Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
                "Middle Earth", "F-1 Spirit", "Antarctic", "Pippols",
                "Frogger", "Time Pilot")

# Athletic Land, Monkey Academy y Konami's Billiards son la excepcion, y a
# proposito: este cartucho es el ARMAZON B de Konami, el mismo de aquellos, y
# media docena de piezas se han identificado comparando binarios en vez de
# leyendolas. Se pueden nombrar, pero SOLO en las lineas ancladas a esas
# piezas; en cualquier otro sitio seria un comentario prestado que se ha
# colado. Cada rango de aqui es una comparacion binaria concreta.
PERMITIDOS = ("Athletic", "Monkey", "Billiards")
HERENCIA = (
    (0x4010, 0x402B),   # las tres rutinas de VDP, identicas a Athletic 0x401C
    (0x41DD, 0x4626),   # la fuente, con el KONAMI pequeno de 0x43BE
    (0x4830, 0x488B),   # PUERTO_DEL_JOYSTICK y LEE_MANDOS
    (0x4AE8, 0x4C8D),   # los rotulos y el menu, palabra por palabra los de Athletic
    (0x4CFA, 0x4D8D),   # el logotipo KONAMI grande comprimido, identico
    (0x5D30, 0x5E70),   # el reproductor de sonido, 177 de 320 bytes en tiras
)

ORG, FIN = 0x4000, 0x6000        # 8 KB: este cartucho acaba en 0x5FFF

# Lo que imprime `make sanity`. Van tambien en make_web.py y en los dos README,
# y el test de abajo vigila que no se separen.
CODIGO, DATOS = 5783, 2409

# Direcciones que se citan en la web y que NO son inicio de instruccion, con su
# razon. Sin esta lista el test de direcciones inventadas las daria por falsas.
BYTES_CITADOS = {
    # El principio de una TIRA de bytes comun con otro cartucho no tiene por
    # que caer en el principio de una instruccion: lo marca la comparacion
    # binaria, no el desensamblado. 0x4013 es donde arrancan los 24 bytes
    # identicos a Athletic Land, tres bytes dentro de VPEEK (0x4010).
    "4013",
}

# La seccion del codigo compartido con los otros Konami de la serie los
# nombra a proposito: la escribe pon_en_webs.py, de MSX-disassembly-database.
_COMPARTIDO = re.compile(
    r"(?:^## |<h2[^>]*>)(?:Code shared with other Konami cartridges|"
    r"C\u00f3digo compartido con otros cartuchos de Konami)"
    r".*?(?=^## |<h2|</main>|<footer|\Z)", re.S | re.M)


def sin_compartido(texto):
    """El texto sin la seccion del codigo compartido."""
    return _COMPARTIDO.sub("", texto)


def asm():
    with open(ASM, encoding="utf-8") as f:
        return f.read()


def notas():
    with open(NOTES, encoding="utf-8") as f:
        return f.read().splitlines()


def directivas(clave):
    return [l for l in notas() if l.startswith(clave + " ")]


def direcciones_vivas():
    """Las direcciones del cartucho que existen de verdad en el listado.

    Son las que mkasm.py escribe en la columna de la derecha, mas las de los
    `equ` de la cabecera: los destinos que caen dentro de otra instruccion no
    tienen linea propia y aun asi son direcciones buenas.
    """
    texto = asm()
    vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", texto, re.M))
    vivas |= set(re.findall(r"^\s*(?:defb|defw).*?;\s*([0-9a-f]{4})",
                            texto, re.M))
    vivas |= {d[-4:].lower()
              for d in re.findall(r"equ\s+0x0?([0-9A-Fa-f]{4,5})", texto)}
    # y las que nombran las propias anotaciones: las bases de tabla que caen
    # dentro de una instruccion (0x6B58, 0x7652...) son direcciones buenas y no
    # tienen linea propia en el listado
    todas_las_notas = chr(10).join(notas())
    vivas |= {d.lower()
              for d in re.findall(r"0x([0-9A-Fa-f]{4})", todas_las_notas)}
    vivas.add("7fff")                       # el ultimo byte del cartucho
    return vivas


class TestListado(unittest.TestCase):

    def test_ningun_bloque_de_datos_sin_identificar(self):
        """Cada zona de datos tiene que tener nombre y explicacion."""
        n = asm().count("DATOS sin identificar")
        self.assertEqual(n, 0, "hay %d bloques de datos sin identificar" % n)

    def test_todas_las_rutinas_con_call_tienen_nombre(self):
        """Si algo se llama con CALL es una rutina, y una rutina se bautiza."""
        sueltas = sorted(set(re.findall(
            r"\bcall (?:n?[zc],|p[oe],|[mp],)?(L_[0-9A-F]{4})", asm())))
        self.assertEqual(sueltas, [], "rutinas llamadas y sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_no_queda_ninguna_etiqueta_sin_bautizar(self):
        """Aqui se bautizaron las 676, incluidos los destinos de salto."""
        sueltas = sorted(set(re.findall(r"\bL_[0-9A-F]{4}\b", asm())))
        self.assertEqual(sueltas, [], "etiquetas sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_ninguna_etiqueta_declarada_dos_veces(self):
        """Dos etiquetas con el mismo nombre y el ensamblador se queja."""
        nombres = re.findall(r"^([A-Za-z_][\w]*):", asm(), re.M)
        repetidas = sorted({n for n in nombres if nombres.count(n) > 1})
        self.assertEqual(repetidas, [], "etiquetas repetidas: %s"
                         % " ".join(repetidas))

    def test_ningun_comentario_de_linea_repetido(self):
        """Dos C en la misma direccion: la segunda pisa a la primera."""
        dirs = [l.split()[1].upper() for l in directivas("C")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "comentarios repetidos en %s" % " ".join(repes))

    def test_ninguna_direccion_bautizada_dos_veces(self):
        """Dos L para la misma direccion: una de las dos se pierde en silencio."""
        dirs = [l.split()[1] for l in directivas("L")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "direcciones con dos nombres: %s"
                         % " ".join(repes))

    def test_todos_los_comentarios_llegan_al_listado(self):
        """Un comentario anclado a una direccion que ya no existe se pierde."""
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        perdidos = [l.split()[1] for l in directivas("C")
                    if l.split()[1][2:].lower() not in vivas]
        self.assertEqual(perdidos, [], "comentarios que no llegan: %s"
                         % " ".join(perdidos[:12]))

    def test_todas_las_cabeceras_llegan_al_listado(self):
        """Igual con las cabeceras de bloque."""
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        perdidas = sorted({l.split()[1] for l in directivas("B")
                           if l.split()[1][2:].lower() not in vivas})
        self.assertEqual(perdidas, [], "cabeceras que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_todas_las_etiquetas_llegan_al_listado(self):
        """Una L cuyo nombre no aparece definido en el .asm es una L perdida."""
        texto = asm()
        perdidas = [l.split()[2] for l in directivas("L")
                    if not re.search(r"^%s:" % re.escape(l.split()[2]), texto, re.M)
                    and not re.search(r"^%s:\s+equ" % re.escape(l.split()[2]),
                                      texto, re.M)]
        self.assertEqual(perdidas, [], "etiquetas que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_los_rangos_no_se_solapan(self):
        """Dos D que pisan los mismos bytes: uno de los dos esta mal."""
        rangos = sorted((int(l.split()[1], 16), int(l.split()[2], 16),
                         l.split()[3]) for l in directivas("D"))
        for (a1, b1, n1), (a2, b2, n2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(b1, a2, "%s (%04X-%04X) pisa a %s (%04X-%04X)"
                                 % (n1, a1, b1, n2, a2, b2))

    def test_todos_los_rangos_van_al_derecho_y_dentro(self):
        """Un rango acaba despues de empezar, y cae dentro del cartucho."""
        for l in directivas("D"):
            a, b, nombre = int(l.split()[1], 16), int(l.split()[2], 16), l.split()[3]
            self.assertLess(a, b, "%s va del reves" % nombre)
            self.assertGreaterEqual(a, ORG, "%s empieza fuera" % nombre)
            self.assertLessEqual(b, FIN, "%s acaba fuera" % nombre)

    def test_todos_los_rangos_estan_explicados(self):
        """Un nombre no basta: cada D lleva su explicacion detras."""
        pelados = [l.split()[3] for l in directivas("D") if len(l.split()) < 5]
        self.assertEqual(pelados, [], "rangos sin explicacion: %s"
                         % " ".join(pelados))

    def test_cada_anchura_cae_en_un_rango(self):
        """Una F cuya direccion no es el principio de una D no hace nada."""
        inicios = {l.split()[1].lower() for l in directivas("D")}
        sueltas = [l.split()[1] for l in directivas("F")
                   if l.split()[1].lower() not in inicios]
        self.assertEqual(sueltas, [], "anchuras sin rango: %s"
                         % " ".join(sueltas[:12]))

    def test_el_listado_lo_genera_la_herramienta(self):
        """El .asm no se edita a mano: sale de mkasm.py."""
        self.assertIn("Generado por tools/mkasm.py", asm())

    def test_no_queda_nada_por_repartir(self):
        """Mientras haya un 'formato pendiente' el trabajo no esta hecho."""
        pendientes = [l for l in notas()
                      if "formato pendiente" in l or "reparto por" in l]
        self.assertEqual(pendientes, [], "quedan %d zonas por repartir"
                         % len(pendientes))

    def test_el_listado_no_habla_de_otro_juego(self):
        """Los comentarios prestados de otro desensamblado se cuelan solos."""
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, asm(), "el listado nombra %s" % juego)

    def test_solo_se_nombra_otro_cartucho_donde_toca(self):
        """Los del armazon B solo salen donde se explica la pieza heredada."""
        fuera = []
        for ln in notas():
            if not any(j in ln for j in PERMITIDOS) or ln.lstrip().startswith("#"):
                continue          # las lineas de comentario del .notes no van ancladas
            m = re.match(r"^[LCBDF] (0x[0-9A-Fa-f]{4})", ln)
            if not m:
                fuera.append(ln[:60])
                continue
            a = int(m.group(1), 16)
            if not any(ini <= a < fin for ini, fin in HERENCIA):
                fuera.append(ln[:60])
        self.assertEqual(fuera, [], "nombra otro cartucho fuera de la herencia "
                         "medida: %s" % " | ".join(fuera))

    def test_la_raiz_no_habla_de_otro_juego(self):
        """En el aviso legal, ni un nombre; en los README, solo con cifra.

        Los dos README resumen los hallazgos, y el primero de ellos es la
        comparacion binaria contra los otros cartuchos: no se puede contar sin
        decir los nombres. Se les aplica la misma regla que a la pagina de
        hallazgos, y la unidad es la VINETA, para que un nombre no se cuele
        colgando de la cifra de la vineta de al lado.
        """
        for fichero in ("AVISO-LEGAL.md", "LEGAL-NOTICE.md", "LICENSE"):
            ruta = os.path.join(RAIZ, fichero)
            if not os.path.exists(ruta):
                continue
            with open(ruta, encoding="utf-8") as f:
                texto = f.read()
            for juego in OTROS_JUEGOS:
                self.assertNotIn(juego, texto, "%s nombra %s" % (fichero, juego))

        for fichero in ("README.md", "README.es.md"):
            ruta = os.path.join(RAIZ, fichero)
            if not os.path.exists(ruta):
                continue
            with open(ruta, encoding="utf-8") as f:
                lineas = f.read().splitlines()
            trozos, actual = [], []
            for ln in lineas:
                if ln.startswith("- ") or not ln.strip():
                    trozos.append(chr(10).join(actual))
                    actual = []
                actual.append(ln)
            trozos.append(chr(10).join(actual))
            for trozo in trozos:
                for juego in OTROS_JUEGOS:
                    if juego in trozo:
                        self.assertTrue(re.search(r"\d", trozo),
                                        "%s nombra %s sin ninguna cifra: %s"
                                        % (fichero, juego, trozo.strip()[:70]))



class TestWeb(unittest.TestCase):
    """La web es bilingue y se genera: lo que se vigila es que no se separe."""

    PAGINAS = [("GETTING-STARTED.md", "EMPEZAR.md"),
               ("THE-GAME.md", "EL-JUEGO.md"),
               ("THE-CARTRIDGE.md", "EL-CARTUCHO.md"),
               ("THE-CODE.md", "EL-CODIGO.md"),
               ("FINDINGS.md", "HALLAZGOS.md"),
               ("OPEN-QUESTIONS.md", "PREGUNTAS-ABIERTAS.md")]

    def test_cada_pagina_tiene_su_pareja_en_el_otro_idioma(self):
        for en, es in self.PAGINAS:
            self.assertTrue(os.path.exists(os.path.join(DOCS, en)),
                            "falta docs/%s" % en)
            self.assertTrue(os.path.exists(os.path.join(DOCS, "es", es)),
                            "falta docs/es/%s" % es)

    # La pagina de hallazgos SI puede nombrar a los otros cartuchos, porque su
    # primer hallazgo ES la comparacion binaria contra ellos: 400 bytes con
    # Athletic Land y cero con Frogger no se puede contar sin decir los
    # nombres. En las demas paginas siguen prohibidos, que es donde se colaria
    # un comentario prestado sin que nadie lo notara.
    COMPARAN = ("FINDINGS.md", "HALLAZGOS.md")

    def test_las_paginas_no_hablan_de_otro_juego(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md") or fn in self.COMPARAN:
                    continue
                with open(os.path.join(raiz, fn), encoding="utf-8") as f:
                    texto = sin_compartido(f.read())
                for juego in OTROS_JUEGOS:
                    self.assertNotIn(juego, texto,
                                     "%s nombra %s" % (fn, juego))

    def test_la_pagina_de_hallazgos_nombra_a_los_otros_CON_su_cifra(self):
        """Si se nombra otro cartucho, tiene que ser para dar una medida.

        La excepcion de arriba abre una puerta: que en hallazgos se cuele una
        frase suelta sobre otro juego sin nada medido detras. Esto la cierra
        exigiendo que cada nombre aparezca en una linea que ademas lleve una
        cifra.
        """
        for fn in self.COMPARAN:
            ruta = (os.path.join(DOCS, fn) if fn == "FINDINGS.md"
                    else os.path.join(DOCS, "es", fn))
            with open(ruta, encoding="utf-8") as f:
                lineas = f.read().splitlines()
            for ln in lineas:
                for juego in OTROS_JUEGOS:
                    if juego not in ln:
                        continue
                    self.assertTrue(re.search(r"\d", ln),
                                    "%s nombra %s sin ninguna cifra: %s"
                                    % (fn, juego, ln.strip()[:70]))

    def test_las_herramientas_de_la_web_no_hablan_de_otro_juego(self):
        """En md2html y graficos, ni un nombre; en make_web, solo con cifra.

        make_web.py lleva dentro el texto de la portada, y ahi vive el mismo
        hallazgo que en la pagina de hallazgos: la comparacion binaria contra
        los otros cartuchos. Se le aplica la misma regla, nombre con medida al
        lado. Las otras dos herramientas no tienen ninguna razon para nombrar
        a nadie.
        """
        for fn in ("md2html.py", "graficos.py"):
            with open(os.path.join(RAIZ, "tools", fn), encoding="utf-8") as f:
                texto = f.read()
            for juego in OTROS_JUEGOS:
                self.assertNotIn(juego, texto, "tools/%s nombra %s"
                                 % (fn, juego))
        # La unidad no es la linea -en un fichero de Python una frase viene
        # partida en cinco cadenas- sino el hallazgo entero, que es como lo
        # lee quien entra en la web.
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        import make_web
        for idioma, hallazgos in make_web.HALLAZGOS.items():
            for titulo, cuerpo in hallazgos:
                texto = titulo + " " + cuerpo
                for juego in OTROS_JUEGOS:
                    if juego in texto:
                        self.assertTrue(re.search(r"\d", texto),
                                        "make_web.py [%s] nombra %s sin "
                                        "ninguna cifra: %s"
                                        % (idioma, juego, titulo[:60]))

    def test_los_enlaces_al_repositorio_son_a_ESTE_repositorio(self):
        """La maquinaria de la web se copio de otro juego de la serie.

        Con ella vinieron los enlaces a `src/` y a `tools/`, que salen de una
        sola constante: si esa constante se queda sin cambiar, toda la web
        manda al repositorio del OTRO cartucho y no se nota mirandola.
        """
        with open(os.path.join(RAIZ, "tools", "md2html.py"),
                  encoding="utf-8") as f:
            texto = f.read()
        urls = re.findall(r"https://github\.com/antxiko/[\w.-]+", texto)
        self.assertTrue(urls, "md2html.py no enlaza al repositorio")
        for url in urls:
            self.assertIn("SuperCobra", url,
                          "tools/md2html.py enlaza a %s" % url)

    def test_la_portada_publica_las_cifras_del_arbol(self):
        """Las cifras de la web son las del presupuesto, y suman el cartucho."""
        with open(os.path.join(RAIZ, "tools", "make_web.py"),
                  encoding="utf-8") as f:
            texto = f.read()
        self.assertIn("CODIGO = %d" % CODIGO, texto)
        self.assertIn("DATOS = %d" % DATOS, texto)
        self.assertEqual(CODIGO + DATOS, FIN - ORG,
                         "las cifras publicadas no suman los 8192 bytes")

    def test_la_cabecera_lleva_el_rotulo_DEL_JUEGO(self):
        """Y no el logotipo de Konami, que es el error que ya se colo una vez.

        Las dos imagenes son PNG pequenos con nombres parecidos en la misma
        carpeta, van embebidas en base64 y en la pagina se ven las dos, asi que
        confundirlas no salta a la vista: la portada salio publicada con el
        logotipo de la CASA de cabecera en vez del rotulo del JUEGO.
        """
        import base64
        img = os.path.join(DOCS, "imagenes")
        juego = os.path.join(img, "logo.png")
        konami = os.path.join(img, "logo_konami.png")
        for f in (juego, konami):
            self.assertTrue(os.path.exists(f), "falta %s" % f)

        def b64(f):
            with open(f, "rb") as fh:
                return base64.b64encode(fh.read()).decode()

        for pagina in (os.path.join(DOCS, "index.html"),
                       os.path.join(DOCS, "es", "index.html")):
            if not os.path.exists(pagina):
                continue
            with open(pagina, encoding="utf-8") as f:
                texto = f.read()
            m = re.search(r'<header class="top">\s*<img src="data:image/png;'
                          r'base64,([^"]+)"', texto)
            self.assertIsNotNone(m, "%s no tiene imagen de cabecera"
                                 % os.path.basename(pagina))
            self.assertNotEqual(m.group(1), b64(konami),
                                "%s lleva el logotipo de KONAMI de cabecera"
                                % os.path.basename(pagina))
            self.assertEqual(m.group(1), b64(juego),
                             "%s no lleva el rotulo del juego de cabecera"
                             % os.path.basename(pagina))

    def test_el_mapa_de_la_zona_1_mide_lo_que_dice_la_web(self):
        """Las 485 columnas que se publican tienen que ser las del PNG.

        El mapa no se lee de la ROM -el terreno se monta en la RAM y solo
        aparece una columna por paso de scroll-, asi que la unica manera de
        equivocarse sin que se note es publicar una cifra que no sea la del
        dibujo. La cifra sale del ancho: 8 pixeles por columna.
        """
        import struct
        ruta = os.path.join(DOCS, "imagenes", "mapa_zona01.png")
        self.assertTrue(os.path.exists(ruta), "falta el mapa de la zona 1")
        with open(ruta, "rb") as f:
            cabecera = f.read(24)
        self.assertEqual(cabecera[:8], b"\x89PNG\r\n\x1a\n", "no es un PNG")
        ancho, alto = struct.unpack(">II", cabecera[16:24])
        self.assertEqual(ancho % 8, 0, "el ancho no es multiplo de 8")
        self.assertEqual(alto, 40, "el decorado son cinco filas de 8 pixeles")
        columnas = ancho // 8
        for pagina in (os.path.join(DOCS, "index.html"),
                       os.path.join(DOCS, "es", "index.html"),
                       os.path.join(DOCS, "OPEN-QUESTIONS.md"),
                       os.path.join(DOCS, "es", "PREGUNTAS-ABIERTAS.md")):
            if not os.path.exists(pagina):
                continue
            with open(pagina, encoding="utf-8") as f:
                texto = f.read()
            for m in re.finditer(r"(\d+) columnas|(\d+) columns", texto):
                dicha = int(m.group(1) or m.group(2))
                self.assertEqual(dicha, columnas,
                                 "%s dice %d columnas y el mapa tiene %d"
                                 % (os.path.basename(pagina), dicha, columnas))

    def test_las_paginas_no_inventan_direcciones(self):
        """Cada 0xNNNN del cartucho que se cite tiene que existir."""
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        vivas |= set(re.findall(r"^\s*(?:defb|defw).*?;\s*([0-9a-f]{4})",
                                asm(), re.M))
        todas = chr(10).join(notas())
        vivas |= {d.lower()
                  for d in re.findall(r"0x([0-9A-Fa-f]{4})", todas)}
        vivas |= set(BYTES_CITADOS)
        # El final de una directiva D es EXCLUSIVO, asi que al citar un rango
        # en la web se nombra su ultimo byte, que es uno menos. Existe y esta
        # declarado: no es una direccion inventada.
        for ln in notas():
            m = re.match(r"^D 0x([0-9A-Fa-f]{4}) 0x([0-9A-Fa-f]{4})", ln)
            if m:
                vivas.add("%04x" % (int(m.group(2), 16) - 1))
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md"):
                    continue
                with open(os.path.join(raiz, fn), encoding="utf-8") as f:
                    pagina = f.read()
                for d in set(re.findall(r"0x([0-9A-F]{4})", pagina)):
                    if 0x4000 <= int(d, 16) < 0x8000:
                        self.assertIn(d.lower(), vivas,
                                      "%s nombra 0x%s y no existe" % (fn, d))


if __name__ == "__main__":
    unittest.main()
