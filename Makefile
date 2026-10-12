# Super Cobra (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como supercobra.rom, y
# `make comprueba` verifica el sha256.

ROM      = supercobra.rom
SHA      = 062aeefd04e6ac28f565c15bd1010fc2a007bfbe8d3898ff8586778462091470
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = SUPER COBRA - Konami - MSX1 - cartucho RC-705 de 8 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Super Cobra (Konami, RC-705) para MSX, 8192 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/supercobra.trace.json: $(ROM) $(SRC)/supercobra.entries $(SRC)/supercobra.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/supercobra.entries \
	        $(WORK)/supercobra $(SRC)/supercobra.nocode

trace: $(WORK)/supercobra.trace.json

listado: $(WORK)/supercobra.trace.json $(SRC)/supercobra.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/supercobra.trace.json \
	        $(SRC)/supercobra.notes work/msx.sym $(SRC)/supercobra.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/supercobra.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/supercobra.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/supercobra.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/supercobra.trace.json $(SRC)/supercobra.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/supercobra.entries $(SRC)/supercobra.notes \
	        $(SRC)/supercobra.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

densidad:
	@python3 tools/densidad.py $(SRC)/supercobra.asm

clean:
	rm -rf $(WORK)/supercobra.trace.json $(WORK)/supercobra.map $(WORK)/png


PYMUS ?= python3     # el que tenga numpy y lameenc
# La musica: el motor del cartucho ejecutado (tools/musica.py) a MP3
musica: $(ROM)
	$(PYMUS) tools/musica.py todas docs/audio
	$(PYMUS) tools/pagina_musica.py

.PHONY: musica all comprueba trace listado verify sanity test densidad clean imagenes web

# ---------------------------------------------------------------------------
# Las imagenes y la web
# ---------------------------------------------------------------------------
# Las tres imagenes RECONSTRUIDAS salen de la ROM y se rehacen aqui. Las tres
# CAPTURAS (titulo, logotipo, partida) son pantallas de openMSX y van
# versionadas en docs/imagenes: se rehacen a mano con
#     openmsx -machine Philips_VG_8020 -cart supercobra.rom #             -script tools/omsx_capturas.tcl
# y hace falta el emulador, asi que no cuelgan de `make`.
imagenes: $(ROM)
	@mkdir -p docs/imagenes
	python3 tools/graficos.py $(ROM) docs/imagenes
	python3 tools/recorta_rotulo.py docs/imagenes/titulo.png docs/imagenes/logo.png

web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	@touch docs/.nojekyll
	@python3 tools/check_enlaces.py docs
