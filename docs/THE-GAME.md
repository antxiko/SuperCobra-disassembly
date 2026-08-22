# The game

![The title screen](imagenes/titulo.png)

You fly a helicopter left to right over scrolling terrain, shoot forwards and
drop bombs downwards, and have to reach the end of each zone without crashing
and without running out of fuel.

## The menu

Four lines and four keys. `LEE_TECLAS_DE_MENU` (0x488B) reads row 0 of the
keyboard, keeps bits 1 to 4 —keys 1, 2, 3 and 4— and translates them through the
table at 0x48AC:

| key | |
|---|---|
| 1 | one player, joystick |
| 2 | two players, joystick |
| 3 | one player, keyboard |
| 4 | two players, keyboard |

What the key picks is bit 4 of 0xE002 (keyboard or joystick) and bit 5 (one or
two players). With the keyboard, `LEE_TECLADO` (0x4863) assembles **the very same
byte** the joystick would give, out of rows 7 and 8: the four arrows, the space
bar and SELECT. From there down, the game does not care where it came from.

## Lives and the two players

Each player has a **32-byte** block: 0xE050 for whoever is playing and 0xE080
for the one waiting. The first byte is the lives, and it starts at 3 (0x490D).

Changing turns (0x4778) swaps the two blocks whole with `INTERCAMBIA` and flips
bit 7 of 0xE002 on the way, which is what decides at 0x4838 **which joystick is
read**. One game, two scores, and whoever is up is always at 0xE050.

## Fuel

It is a single byte, 0xE51C, and submode 3 (0x5291) burns it. That submode gets
one frame in eight and also demands that bits 2 to 5 of the frame counter be
zero: **one tick every 64 frames**, a little over a second.

Running out of fuel **does not kill you**. When the `dec` goes past zero the
byte is put back to zero and 0xE560 is set; and 0xE560 set is, in
`MUEVE_LA_NAVE` (0x5185), what makes the ship sink on its own without touching
the controls. What kills you is whatever is underneath.

The gauge is drawn by dividing by four: the quotient is the full cells (tile
0xC4) and **the remainder, 1 to 3, picks the half-full cell**, which is one of
the three drawings right after 0xC4 (0x4F7C).

## Shooting

`DISPARA_O_BOMBEA` (0x51B1) looks at the **edge** of the button, not at whether
it is held: `cpl` on the previous frame (0xE008) and `and` with the current one
(0xE009) lets through only the frame where it goes from released to pressed.
Without that, holding the button down would fire sixty times a second.

Where the shot goes is decided by **the low three bits of the ship's row**
(0x51C7), and the drawing is 0xF0 plus that. Before the shot is registered the
tile where it would land is checked: below tile 6 it is sky and the shot fits;
otherwise the slot is released and nothing comes out.

The bomb (0x51FD) drops twelve pixels ahead of the ship's rear half, and only
one can be in the air at a time (0xE51F).

## The zones

There are two zone numbers and they are not the same one:

- **0xE051** is the one that gets drawn, and it is BCD.
- **0xE053** is the real one, and it serves as an index.

Each zone is **0xB6 columns** long (0x53C5), and 0xE50B counts down what is left
to reach the end. With 0x12 columns to go, the arrival warning sounds.

The **low two bits** of 0xE053 say what class the zone is, so the cycle repeats
every four. The class decides four things: which sprite attributes are built
(0x504A, four per class), what size they are for collisions (0x5607, four bytes
per class), which of the three routines moves the flying things (0x52F5), and
which one finishes off the zone-cleared banner (0x522C).

Clearing a zone pays **1500 points**, and every three zones the tank is
refilled.

![A zone in progress](imagenes/partida.png)

## What comes after you

Submode 7 (0x52CD) raises the difficulty, and it does so with the stage:
**before stage 3 the count is zero**, from 3 up it climbs, and **it stops at 15**
(0x0C is the cap). That count, doubled, is compared against two bits of the
frame counter: the further along the stage, the more often something appears.

How many can be in the air at once comes from the table at 0x58D6, indexed by
the zone with a cap of 12. And in zone 0 nobody shoots: it is the learning one.

## The score

All BCD, with a `daa` after every addition, and three bytes per score: 0xE040
the high score, 0xE043 player 1, 0xE046 player 2.

The extra life is tracked in 0xE052, and what is compared is **the high byte**,
so the step is in tens of thousands: `add a,002h` in BCD on that byte puts the
extra life **every 20,000 points**. Once past, the byte goes to 0xFF and there
are no more extra lives that game.

If the score passes 999999, what gets pinned at the maximum **is the high
score** (0xE040-0xE042); the player's own points wrap around and carry on.

## The dice

`PUNTOS_DE_PREMIO` (0x501E) gives either fifty fixed points or a random amount,
and it rolls that with **the Z80's R register** —the memory refresh counter—:
its low two bits give 0, 1, 2 or 3, and that is added to the high byte. The
prize is 0, 100, 200 or 300 points.

## Arriving

At the end of the zone there is a fuel dump. `MIRA_SI_ATERRIZA` (0x50A1)
compares it against the ship using the four margins at 0x5648; on contact,
0xE54B goes to 1 —which is landing— and the attribute is left on drawing 4.

And when you get all the way there, `LLEGA_A_LA_BASE` (0x5C41) erases whatever
shots were in the air, switches off the two dump attributes, draws the
**INVASION SUCCEEDED** banner and pays another 1500 points. The same banner is
erased afterwards by entering at 0x4064 instead of 0x4068: the same routine,
with C at zero.
