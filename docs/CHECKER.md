# Compatibility checker

`tools\check-compatibility.bat` is the normal entry point. It wraps the PowerShell checker and accepts up to two inputs:

- one `generator-*.zip` package;
- optionally, one MCreator installation folder or `mcreator.exe`.

Arguments are order-independent.

## Fastest workflow

When the target generator ZIP is still inside the matching MCreator installation's `plugins` folder, drag the ZIP onto:

```text
tools\check-compatibility.bat
```

Example layout:

```text
C:\Program Files\Pylo\MCreator 2026.1\MCreator\
    mcreator.exe
    jdk\
    plugins\
        generator-1.21.8.zip
```

The checker detects that the ZIP is under `plugins`, finds the sibling MCreator executable, and records:

```text
MCreator selection: auto-detected from generator ZIP location
```

This avoids accidentally testing an old generator against the current installed MCreator.

## Explicit paths

If the generator is stored elsewhere:

```bat
tools\check-compatibility.bat "D:\Generators\generator-1.21.8.zip" "C:\Program Files\Pylo\MCreator 2026.1\MCreator"
```

The MCreator argument may point directly to `mcreator.exe`:

```bat
tools\check-compatibility.bat "D:\Generators\generator-1.21.8.zip" "C:\Program Files\Pylo\MCreator 2026.1\MCreator\mcreator.exe"
```

Argument order does not matter.

## No arguments

The checker uses `MCREATOR_HOME` when set; otherwise it defaults to:

```text
C:\Program Files\Pylo\MCreator
```

If that installation's `plugins` folder has exactly one `generator-*.zip`, the checker can select it automatically. When multiple generator ZIPs are present, supply the intended one explicitly.

## Output

Reports are written to:

```text
reports\compatibility-YYYY-MM-DD_HH-mm-ss.txt
reports\compatibility-YYYY-MM-DD_HH-mm-ss.json
```

Use the TXT report for normal review. The JSON report is useful for automation or a future developer/AI handoff.

## Result meanings

### BASELINE MATCH

Every automated contract matches the recorded known-good baseline.

This still does **not** prove runtime compatibility with a new Minecraft/NeoForge release. Run `TESTING.md`.

### REVIEW REQUIRED

No hard failure was found, but upstream differences exist. Review every WARN before claiming compatibility.

### NOT READY

At least one required contract failed. Porting work is required.

### INCOMPLETE

A required input/check was unavailable.

## What the checker verifies

The checker currently covers:

```text
Plugin source anchors
MCreator version/build
required MCreator classes/resources
selected MCreator class hashes
reflection/API signatures
plugin Java compilation against MCreator classes
generator plugin/generator IDs
generator buildfileversion
required upstream generator files
selected upstream file hashes
critical generator/template anchors
```

It intentionally does not claim to prove Minecraft runtime behavior.

## Why hashes are WARN signals instead of automatic failures

An upstream class/template can change harmlessly. Exact hash mismatches therefore tell the maintainer **where to inspect**, while explicit missing APIs/anchors determine hard failures.

Do not overwrite baseline hashes to make a report green. First determine whether the upstream change matters and complete runtime tests.

## Checker validation controls

The checker has been tested against:

```text
Positive control:
MCreator 2026.2 build 33518 + neoforge-26.1.2 / 26.1.2.95
81 PASS, 0 WARN, 0 FAIL, 0 SKIP

Negative control:
MCreator 2026.1 build 14619 + neoforge-1.21.8 / 21.8.31
60 PASS, 14 WARN, 3 FAIL, 0 SKIP
```

The negative control correctly detected a real `LivingEntity.mobSpawningType` data-model/template migration while the plugin Java itself still compiled. This is why the checker is more than a compile test.

## Runtime checks that remain manual

At minimum verify:

- NeoForge still extends `MobCategory` with the expected constructor descriptor;
- `EntityType#getCategory()` returns vanilla and extended categories correctly;
- `NaturalSpawner` includes extended categories without a plugin-owned loop;
- spawn-placement replacement registration still works;
- the persistence-required/native-cap caveat still behaves as documented.
