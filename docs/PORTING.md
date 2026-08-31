# Porting playbook — new MCreator / Minecraft / NeoForge version

This is the detailed maintenance procedure. The short version is in `START-HERE.md`.

The main rule is: **measure the upstream changes first, then make the smallest necessary port.**

## Phase 0 — freeze the known-good baseline

Before touching source:

- archive/tag the last working plugin source;
- keep the last working plugin ZIP;
- keep its compatibility report if available;
- work in a copy/branch;
- do not update baseline hashes yet.

The Beta 1 reference baseline is recorded in `compatibility-spec.json` and `COMPATIBILITY.md`.

## Phase 1 — collect the target environment

Obtain:

```text
1. target MCreator installation
2. target generator-*.zip containing the NeoForge generator to support
```

Keep the generator ZIP intact.

If the generator ZIP is stored under the target installation's `plugins` folder, the checker can infer the matching MCreator automatically.

## Phase 2 — run the compatibility checker before editing code

Preferred:

```text
drag generator-*.zip -> tools\check-compatibility.bat
```

Explicit:

```bat
tools\check-compatibility.bat "C:\path\to\generator-XX.X.x.zip" "C:\path\to\MCreator"
```

Read the generated text report under `reports\`.

### Result meanings

- **BASELINE MATCH** — automated contracts match the recorded baseline; runtime tests still required.
- **REVIEW REQUIRED** — no hard contract failed, but differences need manual review.
- **NOT READY** — at least one hard contract failed; porting required.
- **INCOMPLETE** — the checker could not evaluate everything.

### Never do this

Do not change `compatibility-spec.json` hashes merely to turn WARN into PASS. Hashes are change detectors, not obstacles.

## Phase 3 — classify every WARN and FAIL

Put each result into one of these buckets.

### A. MCreator Java/API/reflection change

Likely affected source:

```text
src/main/java/**/Launcher.java
src/main/java/**/SpawnCategoryGUI.java
src/main/java/**/LivingEntitySpawnCategoryBridge.java
```

Inspect the target classes/methods/fields and adapt the plugin Java. The checker should compile the Java against the target application classes after the change.

Remember the 2026.1 -> 2026.2 `LivingEntity.mobSpawningType` migration: a serialized data-model/reflection change may matter even when the Java plugin still compiles.

### B. Generator format/data-model/template change

Likely affected source:

```text
src/main/resources/<generator-id>/generator.yaml
src/main/resources/<generator-id>/spawncategory.definition.yaml
src/main/resources/<generator-id>/mappings/mobspawntypes.yaml
src/main/resources/<generator-id>/templates/**
```

Create/update a generator-specific resource folder for the target generator ID.

### C. Minecraft/NeoForge runtime API change

Likely affected areas:

```text
MobCategory constructor / enum-extension descriptor
RegisterSpawnPlacementsEvent
SpawnPlacements / heightmap APIs
EntityType#getCategory()
server-level entity iteration
NaturalSpawner behavior
```

These require generated-code inspection and runtime tests, not just MCreator API checks.

## Phase 4 — rebase generator overrides correctly

### Living Entity template: mandatory rebase

The plugin ships a whole-file override:

```text
src/main/resources/<generator-id>/templates/livingentity/livingentity.java.ftl
```

For a new generator:

1. extract the **new upstream** `templates/livingentity/livingentity.java.ftl`;
2. compare old-upstream to new-upstream to understand upstream changes;
3. compare old-upstream to old-plugin-override to identify this plugin's changes;
4. start from the **new upstream** file;
5. reapply only the custom Spawn Category changes;
6. inspect the final diff;
7. generate a Living Entity and inspect its Java.

Do not copy the old plugin override unchanged into the new generator directory.

### Other overridden upstream files

Repeat the same review for:

```text
templates/modbase/neoforge.mods.toml.ftl
templates/modbase/enumextensions.json.ftl
```

Preserve new upstream behavior while reapplying the minimal plugin additions.

### Shared helper generation

Preserve the known-good `global_templates` path unless the target MCreator explicitly makes it incompatible:

```yaml
global_templates:
  - template: spawncategory/custom_mob_categories.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/init/@JavaModNameMobCategories.java"
```

Any replacement must pass a delete/regenerate-from-nothing test.

## Phase 5 — verify `MobCategory` enum extension

Confirm the target Minecraft/NeoForge still permits extending:

```text
net.minecraft.world.entity.MobCategory
```

Beta 1 baseline descriptor:

```text
(Ljava/lang/String;IZZI)V
```

If the constructor changes:

- update enum-extension JSON template;
- update any generated helper assumptions;
- update `compatibility-spec.json` manual/runtime contract text;
- update `ARCHITECTURE.md`;
- test the runtime enum extension before proceeding.

Do not infer constructor semantics only from parameter names in old mappings; verify the target version.

## Phase 6 — build the plugin

Run:

```text
build-plugin.bat
```

The checker also performs a Java compile, but the normal build script is the release build path.

Fix plugin-side compilation before testing generated workspaces.

## Phase 7 — destructive regeneration test

Use a disposable workspace copy.

Delete at minimum:

```text
src/main/java/<basepackage>/init/<JavaModName>MobCategories.java
src/main/java/<basepackage>/init/*Definition.java
src/main/resources/META-INF/enumextensions.json
```

Then fully regenerate.

Required result:

- shared helper reappears;
- required definition files reappear if the current design uses them;
- enumextensions JSON reappears;
- Living Entity generated code compiles against the helper.

Do not treat surviving files as proof of generation. Delete first.

## Phase 8 — runtime regression suite

Follow `TESTING.md` completely. Release-blocking essentials are:

- client/world starts with enum extension loaded;
- custom category entity naturally spawns;
- low custom cap stabilizes with **Despawn when idle enabled**;
- placement preset/custom rules work;
- category-level and Living Entity spawn procedures obey precedence;
- membership block works for vanilla + custom categories;
- loaded-count block works for vanilla + custom categories;
- identifier rename/duplicate/delete behavior is safe;
- exported mod JAR launches outside the dev workspace.

## Phase 9 — decide support scope

If the new release uses a different generator ID, decide whether the plugin will:

```text
A. support both old and new generator IDs
or
B. drop the old generator and require the new version
```

Do not silently delete an old generator-specific resource folder without documenting the support decision.

## Phase 10 — update maintenance records

Only after automated + runtime tests pass:

- update supported version metadata in plugin resources as required;
- update `compatibility-spec.json` target baseline and reviewed hashes;
- add a row to `COMPATIBILITY.md`;
- update `SOURCE-PACKAGE.md`;
- record port-specific notes/pitfalls;
- archive/tag the new known-good source and plugin ZIP.

## What to send when asking someone else to perform the port

Minimum useful bundle:

```text
1. complete current maintenance source ZIP/repository
2. target generator-*.zip
3. target compatibility TXT or JSON report
4. target mcreator.exe if MCreator API/reflection checks changed or failed
5. Gradle/crash logs from any failed fixed regression test
```

That is intentionally enough for a future developer or AI conversation to resume without the original chat.
