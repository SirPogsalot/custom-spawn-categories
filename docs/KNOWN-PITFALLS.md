# Known pitfalls and already-solved mysteries

Read this before debugging a future port. These issues consumed real development time and are easy to misdiagnose.

## 1. Missing `<JavaModName>MobCategories.java`

### Symptom

Generated Living Entity Java references:

```text
<JavaModName>MobCategories.resolve(...)
```

but the helper class does not exist.

### Proven fix/baseline

The Alpha 18/21 `spawncategory.definition.yaml` uses `global_templates` to generate the shared helper. That path was verified by deleting the helper and fully regenerating it from nothing.

### Do not assume

The presence of old `*Definition.java` files does **not** prove the current generation mechanism works. They may be stale from an earlier plugin revision.

## 2. Alpha 19 generation experiments

Several attempts to move shared generation to other template scheduling mechanisms appeared plausible but failed to reliably generate the helper in MCreator 2026.2. The project deliberately returned to the Alpha 18-style `global_templates` path.

Future maintainers may revisit this only if MCreator itself removes/changes `global_templates`, and any replacement must pass the destructive regeneration test in `TESTING.md`.

## 3. Apparent infinite natural spawning / mob cap ignored

### Symptom

A custom category appears to spawn indefinitely past its configured cap, especially with permissive custom placement.

### First check

Verify the Living Entity has:

```text
Despawn when idle = enabled
```

When disabled, MCreator calls `setPersistenceRequired()`. Persistence-required entities are not a reliable population for the native natural-spawn cap to constrain as a hard loaded-entity ceiling.

This once looked like a custom-category cap bug. Re-enabling idle despawn restored expected behavior.

## 4. “Persistent” naming confusion

The tested `MobCategory` constructor's fourth boolean is exposed as:

```text
Use periodic 400-tick spawn checks
```

It is **not** the same thing as an individual entity being persistence-required.

Do not relabel this as “persistent mobs.”

## 5. Heightmap does not mean “spawn only on this surface”

The registered heightmap used by spawn placement is not a universal vertical filter for every natural-spawn candidate. If a modder needs a strict vertical restriction, a spawn-condition procedure is the reliable mechanism.

## 6. Category procedure has no entity dependency

A spawn-placement predicate runs before the entity exists. Category-level spawn-condition procedures therefore use only:

```text
x, y, z, world
```

Do not add an `entity` dependency unless the underlying spawn lifecycle changes and is revalidated.

## 7. Logic procedure “crash” caused by recursive test action

The membership block was once suspected of crashing the game. The actual stack overflow was:

```text
entity hurt
 -> procedure creates explosion
 -> explosion hurts same entity
 -> entity hurt trigger fires again
 -> repeat until StackOverflowError
```

The membership block was working correctly. For first-pass procedure tests, use logging/printing rather than actions that can recursively retrigger the event.

## 8. Loaded count is not native cap census

`Number of loaded entities in spawn category` counts loaded, non-removed entities by `EntityType#getCategory()` and caches the result once per server-level game tick.

Minecraft's native spawn-cap accounting has additional rules, including persistence-related exclusions. Different numbers are therefore not automatically a bug.

## 9. `mobSpawningType` changed between MCreator 2026.1 and 2026.2

The checker negative-control test demonstrated a real upstream migration:

```text
MCreator 2026.1:
LivingEntity.mobSpawningType -> String

MCreator 2026.2:
LivingEntity.mobSpawningType -> MobSpawnType
```

The matching generator template changed from direct string comparisons to `getUnmappedValue()` access.

Important lesson: **Java compilation can still pass while the serialized data-model/template contract is incompatible.** Always read the full compatibility report.

## 10. Whole-file Living Entity override can hide upstream fixes

A new generator may modify unrelated sections of `livingentity.java.ftl`. If the plugin simply copies its old whole-file override into the new generator folder, those upstream fixes disappear.

Always rebase the plugin changes onto the new upstream file.

## 11. Windows path-length failures

The source tree contains deep generator/template paths. Windows Explorer may throw:

```text
0x80010135: Path too long
```

Use a short extraction path such as:

```text
C:\CSC\
```

Maintenance archives intentionally use a short top-level folder name.

## 12. Category identifier and element name are different identities

Living Entity references use:

```text
CUSTOM:<MCreatorModElementName>
```

The editable Category identifier controls the actual custom enum/category identifier and display label. Do not change Living Entity references to use the editable identifier; doing so would make identifier edits break existing entities.
