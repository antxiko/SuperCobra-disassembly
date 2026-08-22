# Findings

Everything on this page is measured against the binary, and says with which
tool.

## Konami copied itself, and it can be counted

`tools/comun_konami.py` indexes every twelve-byte chunk of one cartridge, walks
the other and stretches each match as far as it goes. What comes out are
**identical**, non-overlapping runs. It throws away any run with fewer than four
distinct values, so that a stretch of zero padding does not count as a shared
routine.

With the tool's own threshold —24 bytes in a row, which is where a match stops
being able to be coincidence— Super Cobra against the other Konami cartridges in
this series:

| against | runs | bytes |
|---|---|---|
| Athletic Land | 8 | **400** |
| Monkey Academy | 4 | 287 |
| Antarctic Adventure | 7 | 239 |
| Time Pilot | 1 | 28 |
| Frogger | 0 | **0** |

The 28 bytes shared with Time Pilot **are not a routine**: they are the small
KONAMI logo at 0x43BE, a drawing. And against Frogger there is not a single byte
in a row: two cartridges from the same year, the same house and the same size,
sharing no code at all.

What Super Cobra really shares is with Athletic Land, Monkey Academy and
Antarctic Adventure: the three video routines (0x4013), the input reader
(0x484B), the big KONAMI logo —147 **identical** bytes— and the sound player.

## The sound player is not copied, it is revised

It is the largest thing shared with Athletic Land, and it does not line up in
one piece: **there is no single offset that aligns the two**. Dropping the
threshold to eight bytes, of the 320 bytes in 0x5D30–0x5E70 there are **177 —55.3
%— inside an identical run**, spread over six runs whose offsets range from
0x1B0B to 0x1B28. The two largest are 74 bytes at 0x5DCE and 41 at 0x5E38.

An offset that drifts 29 bytes along the same block is the signature of code
with pieces added and removed in the middle, not of a copy and paste.

## This cartridge does not carry Konami's hidden mark

Manuel Pazos ([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found that
Konami cartridges hide their RC-7xx catalogue number and the game title in
katakana at the end of the ROM.

**It is not here.** The last byte with content is 0x5FF3 —the end of the last
sound track— and from 0x5FF4 to 0x5FFF there are twelve 0xFF bytes and nothing
else. The "RC-705" on this site comes from the catalogue, not from the binary.

## The game's letters are the machine's

`SUBE_FUENTE` (0x4AA0) does `ld hl,(00004h)`. That address is **CGTBL**, the
pointer to the font the BASIC ROM keeps there, and 0x180 bytes are uploaded from
it: 48 characters, from `0` to `_`.

Neither the score digits nor the menu words are inside the cartridge. In the tile
image on [The cartridge](THE-CARTRIDGE.html) the hole is visible: everything grey
is what arrives from outside.

## A routine that draws or erases depending on where you enter

`PINTA_DIBUJO` is at 0x4068 and `BORRA_DIBUJO` two bytes earlier, at 0x4064. The
only difference is the value they load into C: 0xFF one, 0x00 the other. Down in
the loop there is an `and c` (0x4076) which with 0xFF leaves the byte alone and
with 0x00 turns it into zero.

It is the same loop drawing and erasing, and the game really uses it that way:
the INVASION SUCCEEDED banner is drawn by entering at 0x4068 and taken away by
entering at 0x4064 (0x5C63 and 0x5C7D).

The same happens with the submodes: 2 enters at 0x5275 and 4 at 0x5278, three
instructions further in. Same routine, two different jobs.

## Four tables that start inside an instruction

It is not a misreading, and it is not one: there are four.

| table | starts on top of |
|---|---|
| 0x566B, the explosion offsets | the operand of the `jp 0x5B85` at 0x566A |
| 0x58D6, how many come out per zone | the operand of the `jp 0x5C96` at 0x58D5 |
| 0x55D3, the bomb margins | the `call 0x4C93` and the `scf`/`ret` at 0x55D2 |
| 0x5E5F, the base of the track pointers | the last two note periods |

In the first three, the entries that land on top of code **cannot be used**: at
0x566B the index arrives halved and never equals 0 or 1; at 0x58D6 zones 0 and 1
never get to read it; at 0x55D3 family 0 does not either.

The fourth is different and uglier: `SONIDO_PISTAS` (0x5CD8) uses 0x5E5F as its
base, **two bytes before** the first real word. Entry 0 sits on top of the last
two note periods and points at 0x383C, which is outside the cartridge. Sound
number 0 cannot be requested, and nobody requests it.

## A byte that is two things at once

The menu's label stream starts at 0x443A and its closing `0x00` lands on
**0x4560**. And 0x4560 is also the address `MONTA_EL_MAPA` hands to `DESPLIEGA`
as the first ground drawing (0x4135), because `DESPLIEGA` does an `inc de` before
reading and therefore starts right there.

The same byte is the end of one drawing and the start of the next.

## The refresh register as a dice

`PUNTOS_DE_PREMIO` (0x501E) needs a random number and has no generator. It uses
**the Z80's R register**, the dynamic memory refresh counter, which climbs by
itself with every instruction executed. Its low two bits give 0, 1, 2 or 3, and
that goes into the high byte of the prize: 0, 100, 200 or 300 points.

## An instruction the Z80 does not have

The seven bytes at 0x41DD are copied to 0xE5F8 and run from RAM because they
**write their own displacement over themselves**: they are a `ld (IX+A),B`, which
does not exist. It is explained in [The code](THE-CODE.html).
