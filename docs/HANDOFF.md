# Handoff guide — future developer or AI conversation

This file exists so the project can be resumed even if nobody remembers the original development history.

## Files to provide for a version update

Always provide:

```text
- the complete latest maintenance source ZIP/repository
- the target generator-*.zip
- the compatibility checker report for the target (TXT preferred; JSON also useful)
```

Also provide the target `mcreator.exe` when:

```text
- the report shows MCreator API/reflection WARN/FAIL results;
- Java compilation fails;
- a GUI/editor behavior changed despite a clean generator report;
- deeper inspection of MCreator internals is needed.
```

Provide Gradle/crash logs whenever a fixed test workspace fails.

## Copy-paste prompt for a future AI chat

```text
I am maintaining the MCreator plugin “Custom Spawn Categories”. The current release/source baseline is 0.3.0-beta1 unless the attached package documents a newer release.

Please treat the attached source archive as the source of truth and read these files before proposing changes:
- docs/START-HERE.md
- docs/ARCHITECTURE.md
- docs/PORTING.md
- docs/KNOWN-PITFALLS.md
- docs/TESTING.md
- compatibility-spec.json

Target environment:
- MCreator: <version/build>
- generator: <generator id>
- NeoForge/Minecraft build: <version>

Attached:
- current maintenance source ZIP
- target generator ZIP
- compatibility report
- target mcreator.exe (if supplied)
- any relevant Gradle/crash logs

Goal: port the plugin to the target version while preserving the known-good architecture and behavior. Do not redesign the plugin unless an actual upstream incompatibility requires it.

Important invariants:
1. Do not implement a separate natural-spawn loop; extended MobCategory values are intended to use Minecraft NaturalSpawner.
2. Preserve Living Entity references as CUSTOM:<MCreatorModElementName>; the editable Category identifier is separate.
3. Preserve/revalidate the proven global_templates generation of <JavaModName>MobCategories.java. Delete generated files and prove regeneration from nothing.
4. Rebase the whole-file livingentity.java.ftl override onto the NEW upstream template; do not carry the old override forward blindly.
5. Verify the target MobCategory enum-extension constructor/descriptor rather than assuming the old one.
6. Remember that Despawn when idle=false makes entities persistence-required and can make native mob caps appear ineffective.
7. Loaded category count is not specified as Minecraft's exact natural-spawn census.
8. Do not update compatibility hashes just to silence warnings; review upstream changes first.

Please first summarize the compatibility report into:
- unchanged contracts
- warnings requiring review
- hard failures
- files likely requiring edits
- runtime contracts that still need manual testing

Then make the smallest port necessary, build/validate the source where possible, and provide an updated source/plugin package plus a concise test plan.
```

## What a maintainer should expect from the first analysis

Before editing code, the maintainer should be able to answer:

```text
- Did MCreator Java/reflection APIs change?
- Did LivingEntity.mobSpawningType representation change?
- Did the generator ID/resource layout change?
- Did upstream livingentity.java.ftl change?
- Did mobspawntypes mapping format change?
- Did enum-extension/TOML format change?
- Did MobCategory constructor/descriptor change?
- Did spawn-placement registration APIs change?
```

If those questions have not been answered, the port is still in discovery, not implementation.

## What “done” means

A future port is not complete until:

```text
checker reviewed
+ plugin source builds
+ generated helper/JSON regenerate from deletion
+ workspace builds
+ runtime enum extension loads
+ custom natural spawning works
+ non-persistent low-cap test works
+ placement/procedure tests pass
+ rename/duplicate/delete safety passes
+ exported JAR launches
+ compatibility records updated
```

## Historical baseline for comparison

Known-good positive control:

```text
MCreator 2026.2 build 33518
neoforge-26.1.2
NeoForge buildfileversion 26.1.2.95
checker: 81 PASS / 0 WARN / 0 FAIL / 0 SKIP
```

Known negative control used to validate the checker:

```text
MCreator 2026.1 build 14619
neoforge-1.21.8
buildfileversion 21.8.31
checker: 60 PASS / 14 WARN / 3 FAIL / 0 SKIP
```

The negative control demonstrated the old `LivingEntity.mobSpawningType` String representation and the corresponding absence of the newer `data.mobSpawningType.getUnmappedValue()` template access.
