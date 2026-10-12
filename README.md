# fishev

A tiny idle fishing game that lives on your desktop as a transparent, draggable widget.
It casts, waits, reels in and fills the basket by itself while you work on something else.

> **This is a learning project** for getting to know Godot 4 (GDScript, scenes, signals,
> autoloads, translations). Expect rough edges.

## Features

- Transparent, borderless, always-on-top window you can drag anywhere
- Fully automatic fishing loop: cast, wait, bite, reel in, drop into the basket
- 19 fish across 5 rarities; rarer fish are worth more
- Random catches (junk, treasure chests, fish that get away) and random events
  (Fish Frenzy, Lucky Charm, Golden Hour, Storm)
- Basket auto-sells when full; progress is saved automatically
- Right-click menu, collection panel, English and Vietnamese

## Run

Requires Godot 4.7 (GL Compatibility renderer).

```bash
godot --path .                                     # run
godot --path . --display-driver x11                # run via XWayland (see note below)
godot --headless --path . -s tests/run_tests.gd    # run tests
```

Controls: left-drag moves the window, click the barrel for the collection, right-click for the menu.

> On Wayland the compositor controls window layering and position, so "always on top" and
> restoring the window position may not work. Use the x11 command above or a compositor window rule.

## Tune it without touching code

| File | What it controls |
|---|---|
| `config/fish.csv` | Fish: rarity, icon, `weight` (the rare ratio), `value` |
| `config/junk.csv`, `config/rarities.csv` | Junk items and rarity tiers |
| `config/game.json` | Odds, timings, basket size |
| `config/events.json` | Random events and their modifiers |
| `locales/translations.csv` | All UI text, one column per language |

Chance of a fish = its `weight` divided by the sum of all fish weights.
To add a fish, add a row to `fish.csv` and an `item.<id>` row to `translations.csv`.

## Project layout

```
config/    game data (JSON for settings, CSV for tables)
locales/   translations
src/
  autoload/  Config, PlayerState (save), Localization
  data/      typed data classes (ItemData, EventData, Catalog)
  fishing/   Fisher (the loop), LootTable, EventManager, line and rain drawing
  ui/        HUD, effects, context menu, collection panel
  main/      main scene, wires everything together
tests/     headless tests
assets/    sprites
```

Design rules used while learning: logic nodes emit signals and never touch the UI, `main.gd`
is the only place that connects the pieces, and tuning numbers live in `config/`, not in code.

## Credits

Pixel art assets in `assets/` come from third-party packs; check each pack's license
before reusing or redistributing them.
