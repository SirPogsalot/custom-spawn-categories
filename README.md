# Custom Spawn Categories — 0.3.0-beta1 source + maintenance kit

This archive is the **source of truth for 0.3.0-beta1**. Beta 1 promotes the tested Alpha 21 runtime implementation without adding new gameplay features, and carries forward the maintenance/compatibility toolkit validated against both a known-good and a deliberately incompatible MCreator environment.

The distributable plugin ZIP also contains a copy of this maintenance source archive under `maintenance/`. That nested ZIP is documentation/source material only; MCreator loads the outer plugin archive and does not treat a ZIP stored inside it as a separate plugin.

## Start here

For normal development or a future version update, read these in order:

1. [`docs/START-HERE.md`](docs/START-HERE.md) — five-minute project orientation and exact update workflow.
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how the plugin works and which files are authoritative.
3. [`docs/PORTING.md`](docs/PORTING.md) — detailed version-port procedure.
4. [`docs/KNOWN-PITFALLS.md`](docs/KNOWN-PITFALLS.md) — failures and misleading behaviors already discovered.
5. [`docs/TESTING.md`](docs/TESTING.md) — fixed regression/release checklist.
6. [`docs/HANDOFF.md`](docs/HANDOFF.md) — what to give a future developer or AI conversation, including a copy-paste prompt.

The compatibility checker is documented separately in [`docs/CHECKER.md`](docs/CHECKER.md).

## Current tested baseline

| Component | Tested baseline |
|---|---|
| Plugin | 0.3.0-beta1 |
| Runtime code provenance | Promoted from 0.3.0-alpha21 |
| MCreator | 2026.2 build 33518 |
| Generator ID | `neoforge-26.1.2` |
| NeoForge buildfileversion | 26.1.2.95 |

Only versions explicitly recorded in [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md) should be described as supported.

## Rebuilding the plugin

Keep `build-plugin.bat` beside `src/` and run it from Windows. The rebuilt plugin ZIP is written to:

```text
build\custom-spawn-categories-0.3.0-beta1.zip
```

The build also creates a maintenance source bundle and embeds a copy at:

```text
maintenance/csc-0.3.0-beta1-maintenance-source.zip
```

inside the plugin ZIP. Timestamped build logs are written to `logs/`.

## Quick compatibility check

When the target generator ZIP is inside its matching MCreator installation's `plugins` folder, drag it onto:

```text
tools\check-compatibility.bat
```

For explicit paths:

```bat
tools\check-compatibility.bat "C:\path\to\generator-XX.X.x.zip" "C:\path\to\MCreator"
```

The checker writes text and JSON reports to `reports/`. A clean checker result is **not** a substitute for the runtime tests in `docs/TESTING.md`.

## Beta 1 feature baseline

- Custom **Spawn Category** MCreator mod element backed by NeoForge/Minecraft `MobCategory` enum extensions.
- Independent mob cap, friendliness, periodic 400-tick spawn-check flag, and despawn distance.
- Editable category identifier with vanilla-name reservation and duplicate protection.
- Preset/custom spawn placement and optional category-level spawn-condition procedure.
- Living Entity selector supports vanilla and custom categories.
- Procedure blocks:
  - `Entity [entity] belongs to spawn category [category]`
  - `Number of loaded entities in spawn category [category]`
- Mob-cap help documents the persistence-required / **Despawn when idle** caveat.

See [`CHANGELOG.md`](CHANGELOG.md) for release notes.

`compatibility-spec.json` records the machine-readable baseline contracts and hashes. **Do not update hashes merely to silence warnings.** Review and test upstream changes first.
