# Domain Docs

How the engineering skills should consume this repo's domain documentation.

## Before exploring, read these

- **`README.md`**: controls and code layout.
- **`docs/design.md`**: the game's decisions and the reasons behind them. This is the repo's decision record:
  there is no `docs/adr/`. A new decision goes into `design.md` (its Decisions table or the section it belongs
  to), with the reason.
- **`GLOSSARY.md`** at the repo root, if it exists. It's created lazily by `/domain-modeling` when a term gets
  pinned down; don't flag its absence.
- **`docs/ideas.md`**: raw ideas not yet decided or filed.

## Use the game's vocabulary

Name concepts the way `design.md` and the code do (`Branch`, `Bestiary`, `Squad`, `Knob`, vault, floor, band...).
If a concept you need has no name yet, that's a gap to settle with the maintainer, not a name to invent.

## Flag conflicts with design.md

If your output contradicts a decision in `design.md`, say so explicitly rather than silently overriding it:

> _Contradicts design.md (Rooms: doors lock until cleared), but worth reopening because…_
