# Toto: notes for Claude

Godot 4.4.1 (GDScript) top-down dungeon crawler for phones. Read `README.md` (controls, code layout) and
`docs/design.md` (decisions and the reasons behind them) before changing gameplay.

## Working style

- Readable code, separation of concerns, no hidden side effects. Rules live in small pure classes
  (`LootTable`, `EnemyTactics`, `DungeonGenerator` parts, `Exploration`...); nodes only carry them out;
  `scripts/main.gd` is the composition root.
- Tests describe behaviour, not implementation; descriptive names; no unnecessary mocks.
- Defaults live in the classes; tunable fields are exposed as `Knob`s and show up in the in-game Tune screen.
- Update `docs/design.md` and `README.md` when behaviour changes.

## Godot in a cloud session

The container has no Godot. Download it once into the scratchpad (not the repo):

```sh
cd <scratchpad>
curl -L -o godot.zip https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip
unzip godot.zip                      # -> Godot_v4.4.1-stable_linux.x86_64
# Export templates, only needed to build the web playtest:
curl -L -o templates.tpz https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_export_templates.tpz
mkdir -p ~/.local/share/godot/export_templates/4.4.1.stable
unzip -j templates.tpz 'templates/web*' -d ~/.local/share/godot/export_templates/4.4.1.stable
```

## Tests

```sh
G=<scratchpad>/Godot_v4.4.1-stable_linux.x86_64
$G --headless --import                                    # after adding new scripts (class names)
$G --headless -s addons/gut/gut_cmdln.gd -gexit           # all tests (.gutconfig.json)
$G --headless -s addons/gut/gut_cmdln.gd -gselect=test_loot -gexit   # one file
```

A "Test script has 2 unfreed children" warning in the projectile tests is pre-existing.
Screenshots of the real game: `xvfb-run -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 -s <script.gd>`
with a SceneTree script that instantiates `res://scenes/main.tscn` and saves `root.get_texture().get_image()`.

## Updating the phone playtest artifact

The playtest page is the artifact **Toto Playtest**: https://claude.ai/artifact/Xd81kxxhNv5M5PyBYeQqzL
(private, owned by the user). Republish it after every gameplay change the user should try.

1. Build the bundle (needs the export templates above):
   ```sh
   tools/web_playtest/package.sh $G <scratchpad>/web_playtest
   ```
   It exports the Web build and writes, in the output folder: `toto-playtest.html` (the loader page, a copy of
   `tools/web_playtest/toto-playtest.html`), `engine.gz.wasm`, `gamedata.pck.wasm`, `index.js` and two
   `index.audio*.worklet.js` files. The host only serves web file types, so the engine is gzipped and the game
   data renamed to `.wasm`; the loader page unpacks them in the browser.
2. In a new conversation, first read the artifact (`Artifact` action `read` with the URL above); a publish to
   an artifact the conversation hasn't read is refused.
3. Publish to the same URL, with the loader page as the page and the changed files as supporting files:
   - `url`: the artifact URL above
   - `file_path`: `<scratchpad>/web_playtest/toto-playtest.html`
   - `files`: `{"gamedata.pck.wasm": {"from": "<scratchpad>/web_playtest/gamedata.pck.wasm", "contentType": "application/wasm"}}`
     Game code and scenes live in `gamedata.pck.wasm`, so that is usually the only file that changes. Also send
     `engine.gz.wasm` (same content type) and `index.js` if the Godot version or export preset changed. Files
     left out are kept from the previous version.
   - Don't pass `capabilities`: the page's `db` capability is carried forward (it backs "Send to Claude").
   - A short `label` describing the change.
4. If the loader text in `tools/web_playtest/toto-playtest.html` changes, commit it too.

### Reading tuning the user sent

The Tune screen's **Send to Claude** button (on the playtest page only) adds a document to the artifact's
database collection `tunings` (`text` = the exported JSON, `changed` = changed keys, `savedAt`). Read it with
the `ArtifactData` tool (`list` or `query` on collection `tunings` of the artifact URL), newest `savedAt` first.
When the user settles on values, copy them into the class defaults.

## Agent skills

Matt Pocock's engineering skills are vendored in `.claude/skills/` (see its README): `/triage`, `/wayfinder`,
`/to-spec`, `/to-tickets`, `/grill-me`, `/pr` and the skills they call.

### Issue tracker

GitHub Issues on `zenb0t/toto`; cloud sessions use the GitHub MCP tools instead of `gh`. Epics are wayfinder
maps. See `docs/agents/issue-tracker.md`.

### Triage labels

The default triage vocabulary (`bug` / `enhancement` + `needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `wontfix`), plus `wayfinder:*` for epics. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context; `docs/design.md` is the decision record (no ADR folder). See `docs/agents/domain.md`.

## Git

Work happens on the session's feature branch; `main` holds the latest shipped state. Never push to `main`
directly: changes reach it through a pull request (body shaped by the `pr` skill), which the maintainer merges.
