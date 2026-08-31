# Fixed regression and release testing checklist

Use a **disposable workspace copy** for destructive generation tests. Do not use an irreplaceable project as the first target of a new port.

## Recommended compatibility workspace

Keep at least:

```text
Spawn Categories
  TestSpawnCategory
  CaveCategory

Living Entities
  TestVanillaMonster -> vanilla Monster
  TestCustomMob      -> TestSpawnCategory

Procedures
  entity/category membership test
  loaded category count test
  category-level spawn-condition test
```

Use deliberately low caps during testing.

---

## A. Automated compatibility report

- [ ] Run `tools\check-compatibility.bat` against the exact target MCreator + generator.
- [ ] Review every WARN.
- [ ] Resolve every FAIL.
- [ ] Do not change baseline hashes merely to hide differences.

## B. Clean regeneration from nothing

Close MCreator and install only the plugin build being tested.

Delete plugin-generated support files in the disposable workspace:

```text
src/main/java/<basepackage>/init/<JavaModName>MobCategories.java
src/main/java/<basepackage>/init/*Definition.java
src/main/resources/META-INF/enumextensions.json
```

Then:

- [ ] full regenerate workspace code;
- [ ] `<JavaModName>MobCategories.java` reappears;
- [ ] expected `*Definition.java` files reappear if used by this version;
- [ ] `META-INF/enumextensions.json` reappears;
- [ ] workspace builds;
- [ ] delete `<JavaModName>MobCategories.java` a second time and prove it regenerates again.

**Release blocker:** generated Living Entity code references `<JavaModName>MobCategories` while the helper is missing.

## C. Spawn Category editor / serialization

- [ ] new Category identifier initializes from the mod element name/registry name;
- [ ] identifier format enforcement works;
- [ ] vanilla category identifiers are rejected;
- [ ] duplicates are rejected;
- [ ] duplicating a Spawn Category receives a unique identifier when opened;
- [ ] mob cap persists;
- [ ] despawn distance persists;
- [ ] friendly flag persists;
- [ ] periodic 400-tick spawn-check flag persists;
- [ ] preset/custom placement fields persist;
- [ ] category spawn-condition procedure persists;
- [ ] procedure selector survives procedure rename/delete/refresh.

## D. Living Entity integration

- [ ] vanilla spawn categories still appear;
- [ ] every custom Spawn Category appears;
- [ ] custom selection survives close/reopen;
- [ ] changing editable Category identifier does not break the Living Entity reference;
- [ ] changing category placement/procedure regenerates dependent Living Entities;
- [ ] deleting a referenced category does not leave silently valid-but-wrong generated code.

## E. Spawn placement and procedure precedence

Test at minimum:

- [ ] preset Monster;
- [ ] preset Creature;
- [ ] preset Ambient / no restrictions;
- [ ] preset Water Creature;
- [ ] custom ON_GROUND;
- [ ] custom IN_WATER;
- [ ] custom NO_RESTRICTIONS;
- [ ] at least two heightmaps;
- [ ] ALWAYS_ALLOW;
- [ ] at least one restrictive configured condition;
- [ ] category-level spawn-condition procedure;
- [ ] Living Entity spawn-condition procedure overriding the category procedure.

Expected precedence:

```text
Living Entity procedure
> Spawn Category procedure
> configured category placement condition
```

Heightmap selection alone is not a guarantee of a strict global vertical restriction; use a procedure when strict vertical logic is required.

## F. Mob cap / persistence regression

1. Set a custom category cap low, e.g. `10`.
2. Use a naturally spawning Living Entity with **Despawn when idle enabled**.
3. Observe with the loaded-category-count block.

- [ ] population settles instead of growing indefinitely;
- [ ] no unexpected category crossover;
- [ ] no server-tick degradation.

Then repeat with **Despawn when idle disabled** only to confirm the documentation still accurately explains the persistence-required caveat.

Do **not** use persistence-required mobs as the sole evidence that a native category cap is broken.

## G. Procedure blocks

### Membership logic

Use harmless logging/printing for first-pass testing.

Expected:

```text
custom-category mob vs its category -> true
custom-category mob vs Monster      -> false
vanilla zombie vs Monster           -> true
vanilla zombie vs custom category   -> false
```

- [ ] vanilla category choices work;
- [ ] custom category choices work;
- [ ] no crash/exception.

Avoid recursive tests such as:

```text
entity hurt -> explosion -> entity hurt -> ...
```

### Loaded count

- [ ] vanilla category count changes as entities load/unload;
- [ ] custom category count changes as entities load/unload;
- [ ] counts do not cause obvious tick stalls during normal use.

Remember: this is loaded-entity count, not Minecraft's exact internal natural-spawn census.

## H. Rename / duplicate / delete safety

- [ ] edit Category identifier and regenerate;
- [ ] rename MCreator mod element if supported by the tested workflow;
- [ ] duplicate a category;
- [ ] delete a category used by a Living Entity;
- [ ] regenerate after each operation;
- [ ] no duplicate enum-extension names;
- [ ] no stale generated Java/JSON silently survives and masks a failure.

## I. Runtime soak

When practical, run a world for ~30 minutes.

Watch for:

- [ ] runaway counts with non-persistence-required mobs;
- [ ] repeated exceptions;
- [ ] server tick stalls;
- [ ] category crossover;
- [ ] procedure counter performance problems;
- [ ] unusual behavior after save/reload or dimension change.

## J. Build/export release gate

- [ ] full workspace build succeeds;
- [ ] development client launches;
- [ ] test world loads;
- [ ] exported mod JAR launches outside the workspace;
- [ ] stated NeoForge/generator version matches the tested environment;
- [ ] known companion plugins used during testing are rechecked when relevant.

## Release decision

A new environment should not be added to `COMPATIBILITY.md` as supported until **all applicable release-blocking checks above pass**.
