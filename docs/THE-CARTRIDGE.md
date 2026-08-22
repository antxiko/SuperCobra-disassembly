# The cartridge

## The header and the machine

An 8 KB cartridge in **page 1**, from 0x4000 to 0x5FFF.

    4000  41 42 7d 40 00 00 00 00 ...      "AB", and behind it INIT = 0x407D

Only INIT is declared; the other three vectors are zero. INIT wipes 0xE000 to
0xF7FF in one go —all the RAM the game uses—, leaves the stack at 0xF800,
writes `jp 0x402B` into the H.KEYI hook (0xFD9A) and settles into a `jr $`
(0x40AD). From then on **the main thread never does anything again**: the whole
game runs inside the interrupt.

## Video memory

SCREEN 2, with the eight registers coming from 0x4830 and uploaded one by one by
0x4813:

| | |
|---|---|
| name table | 0x3800 |
| pattern table | 0x2000 |
| colour table | 0x0000 |
| sprite attributes | 0x3B00 |
| sprite patterns | 0x1800, 16×16 |

The addresses the code handles have 0x4000 added: that is the write bit `VPOKE`
sets on D before sending them to the VDP. That is why the listing reads
`ld de,06300h` where the real video memory is 0x2300.

SCREEN 2 splits patterns and colours into three 2 KB thirds, and this game wants
them identical: it builds the first and then copies **inside video memory
itself**, without reading the ROM again (`REPITE_TERCIOS`, 0x4A95).

## The letters are not in the cartridge

`SUBE_FUENTE` (0x4AA0) reads `CGTBL` —the pointer at address 0x0004 of the BASIC
ROM— and uploads **0x180 bytes of the machine's font**: 48 characters, from `0`
to `_`. The score digits and the menu words are the MSX's own letters, not
Konami artwork.

And it uploads them twice, with two different offsets and two different colours,
because in SCREEN 2 colour goes per pattern line and the same character cannot
have two colours.

![The tiles of the top third](imagenes/tiles.png)

*The 256 tiles of the top third after the title screen is built. The grey ones
are the ones the cartridge does not carry: that is where the letters copied from
the BIOS land.*

## The two drawing interpreters

The cartridge does not store graphics raw. It has two formats and two routines:

**`PINTA_DIBUJO` (0x4068)** — a video memory address, and behind it the bytes as
they are. `0xFE` closes the run and asks for another address; `0xFF` closes the
drawing. Its twin `BORRA_DIBUJO` (0x4064) is **the same routine**: it enters two
bytes earlier with C = 0x00 instead of 0xFF, and the `and c` at 0x4076 turns
every byte into a zero. One loop draws and erases.

**`PINTA_ROTULO` (0x4AC6)** — the compressed one. A command byte: with bit 7 set,
C distinct bytes follow; without it, one byte is repeated C times. `0x80` opens
another run at another address and `0x00` closes.

## The sprites

Sprite patterns have a single supplier: the stream at 0x443A, the only thing in
the whole cartridge that writes to video memory 0x1800. That is 144 bytes at
0x1800 and 328 at 0x18A8.

![The sprite drawings](imagenes/sprites.png)

*The 16×16 sprite drawings, taken from video memory 0x1800. They come out white
because the colour is not in the drawing: it is in the attribute, four bytes per
sprite —row, column, drawing and colour—.*

The four attributes the ship starts with are at 0x41E4: two halves of the
helicopter in white, and two more below, one white and one red.

## The sound

Three channels of ten bytes each from 0xE010:

| | |
|---|---|
| +0 | what is left of the note |
| +1 | the duration |
| +2 | the sound number, which is what priority looks at |
| +3/+4 | the track pointer |
| +5 | the octave |
| +6 | the volume |
| +8 | the envelope |
| +9 | the chained sound |

A sound can take one, two or three channels, and its number decides: below 0x89
one, from 0x89 to 0x8C two, from 0x8D up three (0x5CAC).

The twelve periods in the table at 0x5E55 are **one byte each**: they are the
top octave, and the lower ones come out by doubling the period (0x5E43).

These 269 bytes are close relatives of Athletic Land's: see
[Findings](FINDINGS.html).

## What it is made of

| | bytes | |
|---|---|---|
| traced code | 5,783 | 70.59 % |
| identified data | 2,409 | 29.41 % |
| **unexplained** | **0** | **0.00 %** |

The cartridge has only three gaps: twelve zeros in the header (0x4004), ten at
0x506D and **twelve 0xFF bytes from 0x5FF4 to 0x5FFF**, behind the end of the
last sound track.
