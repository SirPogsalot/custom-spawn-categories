# Start here — future maintainer guide

This is the shortest path to understanding and updating Custom Spawn Categories without relying on the original development conversation.

## What this plugin does

Custom Spawn Categories adds an MCreator **Spawn Category** mod element backed by NeoForge's extensible Minecraft `MobCategory` enum. Living Entities can use these custom categories for natural spawning, independent base mob caps, category-level placement rules, and category-level spawn-condition procedures.

The plugin intentionally **does not implement its own natural-spawn loop**. Minecraft's `NaturalSpawner` handles the extended `MobCategory` values.

## Current known-good baseline

```text
Plugin:             0.3.0-beta1
MCreator:           2026.2 build 33518
Generator:          neoforge-26.1.2
NeoForge build:     26.1.2.95
```

Treat this as the reference implementation. Beta 1 is a release promotion of the tested Alpha 21 runtime implementation; the compatibility baseline remains MCreator 2026.2 build 33518 / NeoForge 26.1.2.95. Do not call another MCreator/generator combination supported until the checker and runtime tests have been completed.

## The six facts most likely to save you hours

1. **The shared `<JavaModName>MobCategories.java` file must regenerate from `global_templates`.** This path was re-proven after Alpha 19 experiments broke generation. Do not replace it with a different template mechanism without a clean delete/regenerate test.
2. **The Living Entity generator override is a whole-file upstream template override.** On every generator update, start from the *new upstream* `livingentity.java.ftl` and reapply this plugin's changes. Never carry the old override forward blindly.
3. **Living Entities reference custom categories by MCreator mod-element name, not by editable category identifier.** Stored form: `CUSTOM:<ModElementName>`. This is what makes identifier edits safe.
4. **`Despawn when idle = false` makes a Living Entity persistence-required.** Persistence-required mobs are not a reliable population for Minecraft's natural spawn cap to constrain as a hard loaded-entity ceiling. This once looked like an infinite-spawn plugin bug.
5. **The Spawn Category flag “Use periodic 400-tick spawn checks” is not entity persistence.** It is the fourth `MobCategory` constructor boolean in the tested mappings.
6. **Generated workspace files are evidence, not source of truth.** Old `*Definition.java` files can survive regeneration and look current when they are stale. Delete generated files before using their presence as proof of generation behavior.

## Updating to a new MCreator / Minecraft / NeoForge version

Use this order. Do not begin by editing code.

### 1. Preserve the last working source

Archive/tag the known-good source and plugin ZIP. Work in a copy or branch.

### 2. Obtain the target environment

Collect:

```text
- target MCreator installation
- target generator-*.zip containing the NeoForge generator
```

Keep the generator ZIP intact.

### 3. Run the compatibility checker

Best case: drag the generator ZIP from that MCreator installation's `plugins` folder onto:

```text
tools\check-compatibility.bat
```

Then read `reports\compatibility-....txt`.

Interpretation:

```text
BASELINE MATCH   -> automated contracts match; runtime testing still required
REVIEW REQUIRED  -> no hard break proven, but upstream changes need inspection
NOT READY        -> one or more required contracts failed; porting work required
INCOMPLETE       -> checker lacked an input or could not run a required check
```

### 4. Port only the pieces that changed

The most common work is one or more of:

```text
MCreator Java API/reflection change
    -> update Java bridge/GUI code

Generator data-model/template change
    -> create/update generator-specific resource folder
    -> rebase whole-file overrides onto new upstream templates

Minecraft/NeoForge API change
    -> update MobCategory enum-extension descriptor/helper code/placement registration
```

See `PORTING.md` for the detailed procedure.

### 5. Build the plugin

Run:

```text
build-plugin.bat
```

Fix compilation errors against the target MCreator before testing a workspace.

### 6. Run the fixed disposable-workspace regression tests

Follow `TESTING.md`, especially:

```text
- delete generated MobCategories/Definition/enumextensions files
- full regeneration from nothing
- build + launch
- custom natural spawning
- low mob-cap test with Despawn when idle enabled
- vanilla/custom procedure-block tests
- identifier rename/duplicate/delete tests
- exported JAR test
```

### 7. Record support only after tests pass

Update:

```text
compatibility-spec.json
docs/COMPATIBILITY.md
docs/SOURCE-PACKAGE.md
release notes / changelog
```

Only then publish or claim compatibility.

## Which files matter most during a port

### MCreator-side Java

```text
src/main/java/.../Launcher.java
src/main/java/.../PluginElementTypes.java
src/main/java/.../SpawnCategory.java
src/main/java/.../SpawnCategoryGUI.java
src/main/java/.../LivingEntitySpawnCategoryBridge.java
```

### Generator-side resources

```text
src/main/resources/<generator-id>/spawncategory.definition.yaml
src/main/resources/<generator-id>/generator.yaml
src/main/resources/<generator-id>/mappings/mobspawntypes.yaml
src/main/resources/<generator-id>/templates/spawncategory/custom_mob_categories.java.ftl
src/main/resources/<generator-id>/templates/livingentity/livingentity.java.ftl
src/main/resources/<generator-id>/templates/modbase/enumextensions.json.ftl
src/main/resources/<generator-id>/templates/modbase/neoforge.mods.toml.ftl
```

### Procedure blocks

```text
src/main/resources/procedures/entity_is_spawn_category.json
src/main/resources/procedures/spawn_category_loaded_count.json
src/main/resources/<generator-id>/procedures/...
```

## What *not* to do

- Do not “fix” compatibility by editing only the hashes in `compatibility-spec.json`.
- Do not assume Java compilation proves generator or runtime compatibility.
- Do not edit generated workspace Java/JSON as the permanent fix.
- Do not assume old `*Definition.java` files were freshly regenerated.
- Do not replace the proven `global_templates` helper generation path without a destructive regeneration test.
- Do not treat loaded entity count as Minecraft's exact internal spawn-cap census.
- Do not test a hurt-trigger procedure with an explosion or another action that recursively hurts the same entity and then blame the category logic when it stack-overflows.

## If you are a future AI assistant

Before proposing code changes, read:

```text
docs/START-HERE.md
docs/ARCHITECTURE.md
docs/PORTING.md
docs/KNOWN-PITFALLS.md
docs/TESTING.md
```

Then inspect the supplied compatibility report and target generator. If the report flags an MCreator API/reflection change, inspect the supplied target `mcreator.exe` too. Preserve the known-good Beta 1 architecture unless an upstream change actually requires a redesign.

A ready-to-copy handoff prompt is in `HANDOFF.md`.
