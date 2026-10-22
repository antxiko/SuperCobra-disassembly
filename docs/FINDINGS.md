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

## The terrain is ONE, and it does not change from stage to stage

You would expect a game about flying through caves to have a map per stage. It
does not: **it has one**, it is built once, and it is the same to the end.

The code says so in three places, and none of them is an interpretation:

1. **`MONTA_EL_MAPA` (0x4106) does not read a single state variable.** In its
   whole body, from 0x4106 up to where `MONTA_EL_TERRENO` starts (0x4190), there
   is not one read of the game's RAM: it only writes. What it unfolds comes entirely from the ROM —the four
   drawings at 0x4560 and the twenty-nine-byte recipe at 0x45E5— and from
   nothing else.
2. **It is called from a single place**, 0x48F5, right after copying the three
   lives into the scoreboard. That is at the start of the game, not the start of
   each stage.
3. **The stage does exist and does matter**, but for something else. It lives at
   `0xE053` and is read in eight places (0x5115, 0x522C, 0x527D, 0x5291, 0x52DC,
   0x52F5, 0x536F and 0x53FD) to split the work: which enemies appear, how the
   sound is spread across frames, which drawing routine runs. **None of the
   eight is in the terrain build.**

So what changes from one zone to the next is what attacks you and what you hear,
not where you fly. The twenty-nine-byte recipe is walked **twice**, the second
time with the carry set (the `scf` at 0x41C5), and that is the whole difference
between floor and ceiling: **the ceiling is not a mirror of the floor, it has
its own relief** and comes out of the same recipe read differently.

## The terrain's shot ignores the row

In class 0 zones the terrain fires (`SUELTA_EN_ZONA_0`, `supercobra:570A`). The
code compares the row with 0x58 ("below it one thing is looked at, above it
another", `5710`) and keeps the result in the carry. But before using it, it
does `and 0x38` and `add 0x30`, which always leave it at 0: the `jr nc` at
`5715` always jumps and every shot aims at the ship. The second batch is not
used from there. *A logical proof inside the block; the effect in a game has
not been measured.*
