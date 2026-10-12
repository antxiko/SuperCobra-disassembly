# The music

Everything you hear here comes from running the cartridge's own sound engine (`SUENA`, 0x5D31, and `SUENA_ESTO`, 0x5C96, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the demo fanfare (0x89), whole, 258 frames;
- the long track 0x8C, whole, 1,307 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`SUENA_ESTO` takes the number in A. From 0x89 to 0x8C it uses two channels and from 0x8D up all three; below that, an effect on a single channel. The listing shows only two music requests, 0x89 and 0x8B; the rest of what the game asks for during play are effects (the engine hum, the shot, the bomb). Tracks 0x8A and 0x8C are in the track table but no routine asks for them with an `ld a`. The engine never writes the PSG mixer: `ARRANCA_EL_SONIDO` (0x47FC) sets it to 0xB8, and here it starts from that same value.

## The tunes

**The demo fanfare** (0x89)

Asked for by `ESTADO_08_DEMO` (0x47C1), antes de arrancar la demostración; lasts 4.3 s.

<audio controls preload="none" src="audio/musica_89.mp3?v=80faec8a"></audio>

**A short track in the table** (0x8A)

Asked for by ninguna llamada directa: está en la tabla de pistas (0x5E5F); lasts 5.3 s.

<audio controls preload="none" src="audio/musica_8A.mp3?v=1700eef7"></audio>

**The warning as the ship stops** (0x8B)

Asked for by `LA_NAVE_SE_PARA` (0x509C) y `MARCA_EL_TRAMO_FINAL` (0x537D); lasts 5.3 s.

<audio controls preload="none" src="audio/musica_8B.mp3?v=3b1c6f48"></audio>

**A long track in the table** (0x8C)

Asked for by ninguna llamada directa: está en la tabla de pistas (0x5E5F); lasts 21.8 s.

<audio controls preload="none" src="audio/musica_8C.mp3?v=73fad73d"></audio>
