# Open questions

What is not known. None of this is dressed up as a finding anywhere else on this
site.

## Two bytes with no owner

0x5632–0x5633: `0C 00`. They sit between the ground tile shapes —three tiles of
three bytes, 0x5629–0x5631— and the big tile ones —five of four bytes,
0x5634–0x5647—.

They fit neither the rows of three above nor the rows of four below, and in the
8192 bytes there is no `ld hl,05632h` nor anything landing there. They are
declared as data because reassembly demands it, but who reads them is not known.

## Where the sound durations really end

0x5E85 is the table `MUSICA_NOTA` (0x5E17) indexes with the high nibble of the
note, and behind it come the PSG tracks. The trouble is that the pointers at
0x5E61 point at tracks starting **inside that first stretch**: 0x5E89 and 0x5EA9.

Either the durations actually used are very few, or those bytes serve both
purposes at once. It is not settled, and that is why the block is declared whole
as `duraciones_y_pistas` instead of split in two.

## Which label the one at 0x506D is

`PINTA_EL_ROTULO_DE_FASE` (0x5012) lays the drawing at 0x506D into the terrain
buffer, at 0xEB31. And that drawing is **ten 0x00 bytes and one 0xFF** closing
it.

Run through `DESPLIEGA`, ten zeros are not ten columns: with no 0x50 in between
the column never changes, so all ten passes write to the same one. What is
supposed to appear there, and why ten identical passes are needed, has not been
checked.

## Nothing measured in the emulator

The three screenshots on this site are real openMSX screens, but there is **not a
single figure** here that came out of the emulator: not the cost of the
interrupt, not how many VDP writes a frame makes, not how long a zone takes to
pass. Everything else comes from reading the binary.

The zone 1 map is the one thing that comes from running the cartridge, and it
was **not** run in openMSX either: it comes out of `tools/z80run.py`, an
interpreter written here. Which is why it has not been checked against openMSX's
VRAM, and that check is still owed.

## Only zone 1 is mapped

`tools/mapa.py` flies the cartridge and captures zone 1 whole: 485 columns, and
it comes out the same byte for byte every run.

Zones 2 onwards are **not** here, and the reason is the pilot, not the tool. The
automatic pilot only holds its height and keeps firing, and in zone 2 it dies at
the very same place every single time —416 frames after the zone starts, ten
times out of ten—, so the zone restarts for ever and the capture never gets past
it.

Getting the rest needs one of two things: a pilot that dodges what it has in
front, or a way of making the cartridge build a given zone's terrain without
having to fly all the way there. Neither has been tried.
