# Compatibility matrix and support policy

Only environments explicitly tested should be described as supported. A clean Java compile or a clean automated checker report alone is not enough.

## Supported/tested baseline

| Plugin | MCreator | Generator ID | NeoForge build | Status | Notes |
|---|---|---|---|---|---|
| 0.3.0-beta1 | 2026.2 build 33518 | `neoforge-26.1.2` | 26.1.2.95 | Tested beta baseline | Runtime implementation promoted from Alpha 21; destructive regeneration, enum extension, natural spawning, placement, vanilla/custom procedure selectors, identifier protection, and persistence/cap behavior were tested during alpha development. |
| 0.3.0-alpha21 | 2026.2 build 33518 | `neoforge-26.1.2` | 26.1.2.95 | Historical known-good | Final alpha runtime baseline from which Beta 1 was promoted. |
| 0.3.0-alpha18 baseline | 2026.2 build 33518 | `neoforge-26.1.2` | 26.1.2.95 | Regression reference | Its `global_templates` helper-generation path was re-tested after later Alpha 19 generation experiments failed. |

## Deliberately unsupported checker control

| Plugin | MCreator | Generator ID | Build | Result | Purpose |
|---|---|---|---|---|---|
| Beta 1/Alpha 21 architecture, unported | 2026.1 build 14619 | `neoforge-1.21.8` | 21.8.31 | NOT READY: 60 PASS / 14 WARN / 3 FAIL | Negative control proving the checker detects a real older data-model/template incompatibility. |

The negative-control row is **not** a support claim.

## Three layers of compatibility

### 1. MCreator API compatibility

Can the Java plugin compile, and do required reflection/API contracts still exist?

### 2. Generator compatibility

Do the relevant generator files/data models/templates still exist, and have whole-file overrides been correctly rebased?

### 3. Minecraft/NeoForge runtime compatibility

Do enum extension, `MobCategory`, spawn placement, natural spawning, caps, and entity APIs still behave correctly at runtime?

The checker partially automates layers 1 and 2. Layer 3 remains a fixed runtime test suite.

## Major maintenance risk: whole Living Entity template override

Beta 1 ships a complete `livingentity.java.ftl` override. New upstream fixes do not automatically enter the plugin.

Every generator port must start from the **new upstream template** and reapply the plugin's custom-category changes. Old plugin overrides are not portable by default.

## Baseline hashes

`compatibility-spec.json` contains exact hashes for selected MCreator classes and upstream generator files from the tested 2026.2/26.1.2 baseline.

Hash mismatch means:

```text
review this upstream change
```

not:

```text
plugin is definitely incompatible
```

## Checker validation history

Positive control:

```text
MCreator 2026.2 build 33518
NeoForge generator 26.1.2.95
81 PASS / 0 WARN / 0 FAIL / 0 SKIP
```

Negative control:

```text
MCreator 2026.1 build 14619
NeoForge generator 1.21.8 / 21.8.31
60 PASS / 14 WARN / 3 FAIL / 0 SKIP
```

The negative control caught:

- missing `MobSpawnType.class` in the older MCreator;
- the older `LivingEntity.mobSpawningType` representation;
- the matching generator template's lack of `data.mobSpawningType.getUnmappedValue()`.

## Adding a supported row

Add a new supported row only after:

1. target compatibility report reviewed;
2. all hard failures ported;
3. plugin source builds;
4. destructive generated-file regeneration passes;
5. runtime suite in `TESTING.md` passes;
6. exported JAR launches;
7. baseline/spec records updated deliberately.
