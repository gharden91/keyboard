# ADR-0001: Key hit targets fill the column pitch; no 42 pt width floor on iPhone portrait or in Compact

- **Status:** Accepted
- **Date:** 2026-11-06
- **Scope:** Layout (`SPEC.md` §5)
- **Shipped in:** spec change only, from [#3](https://github.com/gharden91/keyboard/issues/3)

## The question

`SPEC.md` §5 set a minimum hit target of 42 × 54 pt on every device class. A
QWERTY top row has 10 keys, and the extension is always the full screen width
(§3). So on an iPhone in portrait the widest a key can be is
`screen width / 10`: 37.5 pt at 375 pt, 39.3 pt at 393 pt. M1's geometry tests
couldn't pass as specified.

## What we chose

- **Full and Split mode:** hit targets fill the whole column pitch. They're
  ≥ 42 pt wherever the geometry allows (iPad; landscape), and exactly
  `width / 10` where it doesn't. Apple's own keyboard does the same.
- **Compact mode:** no width floor. It's a one-handed mode and narrow by
  design (about 28–31 pt keys on a 393 pt phone), but keys still fill their
  pitch.
- Height stays at ≥ 54 pt everywhere.

## What we turned down

| Option | Why not |
|---|---|
| Keep 42 pt everywhere | Impossible: there's no room for it in a 10-key row on an iPhone in portrait. |
| Lower the floor to ~37 pt on phones | It's an arbitrary number that just tracks today's smallest screen, and it still fails Compact. Filling the pitch already gives the largest target the screen allows. |
| Drop the row to fewer keys on small phones | Breaks QWERTY muscle memory, and swipe decoding depends on standard key positions. |

## What would change our mind

Hardware testing that shows real miss rates on the 375 pt class, or an
alternate layout (such as the §16 hexagon) that fits fewer keys per row. Then
the floor question comes back per layout.
