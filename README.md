# Super Cobra (MSX, Konami 1983) — a commented disassembly

A full, commented disassembly of **Super Cobra** for MSX: Konami's cartridge
**RC-705**, 8 KB in page 1.

**100 % of the binary is explained**, it reassembles into the original byte for
byte, and nothing here is a guess dressed up as a fact.

📖 **[Read the site](https://antxiko.github.io/SuperCobra-disassembly/)** ·
🇪🇸 **[En castellano](README.es.md)**

## What is in here

| | bytes | |
|---|---|---|
| traced code | 5,783 | 70.59 % |
| identified data | 2,409 | 29.41 % |
| **unexplained** | **0** | **0.00 %** |

**407 labels** (not one left unnamed), **771 anchored comments** — 24.2 % of the
instructions, with **no routine under 10 %** — and **36 data ranges**, each with
its name, its explanation and the width of its rows. **25 tests** watch over all
of it.

## Some of what turned up

- **Against Frogger it shares no run of bytes at all.** Same year, same house,
  same 8 KB. Measured with `tools/comun_konami.py`: 400 bytes in common with
  Athletic Land, 287 with Monkey Academy, 239 with Antarctic Adventure, and
  **zero** with Frogger.
- **The sound player is not copied from Athletic Land, it is revised**: no
  single offset aligns the two, and the six identical runs drift 29 bytes along
  the same block.
- **The game's letters are not in the cartridge**: `SUBE_FUENTE` reads CGTBL and
  uploads 48 characters from the BASIC ROM.
- **The main thread does nothing.** INIT hooks the interrupt and settles into a
  `jr $` forever; the whole game runs inside the video hook.
- **The same routine draws and erases**, depending on which of two entry points
  you use — and the same trick appears again in the submodes.
- **Four tables that start inside an instruction**, one of them pointing outside
  the cartridge.
- **Seven bytes that run from RAM** because they are a `ld (IX+A),B`, which the
  Z80 does not have.
- **This cartridge does not carry Konami's hidden mark** — the RC-7xx code and
  katakana title found by Manuel Pazos. There are twelve 0xFF bytes and nothing
  else.

The full list, with addresses and figures, is in
[docs/FINDINGS.md](docs/FINDINGS.md). What is *not* known is in
[docs/OPEN-QUESTIONS.md](docs/OPEN-QUESTIONS.md), and it says so.

## Running it

The cartridge image is **not distributed here**. Put it in the root as
`supercobra.rom` — 8192 bytes, sha256 `062aeefd…62091470` — and:

    make            # trace, listing, reassembly, checks and tests
    make verify     # reassemble and compare against the ROM, byte for byte
    make sanity     # not one byte may be left unassigned
    make web        # rebuild the site

You need Python 3, `pasmo` and `z80dasm`. Full instructions in
[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md).

## Legal notice

This is documentation and preservation work. The code and artwork still belong
to their authors and to Konami, and **the cartridge image is not distributed**.
See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
