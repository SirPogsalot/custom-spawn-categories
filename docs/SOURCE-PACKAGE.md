# Source package and release provenance

Plugin version: **0.3.0-beta1**  
Source/maintenance revision: **beta1**

Beta 1 promotes the tested Alpha 21 runtime implementation. The intentional runtime-facing change for the promotion is release metadata (`plugin.json` version/description); the Java implementation and generator/procedure/help behavior are otherwise carried forward.

## Embedded source bundle

The distributable plugin ZIP contains:

```text
maintenance/csc-0.3.0-beta1-maintenance-source.zip
```

This is an opaque nested archive containing the source, documentation, compatibility checker, and build script. It is included for recoverability and handoff. MCreator discovers plugin ZIPs from plugin directories; it does not recursively treat an archive stored as a resource inside an already loaded plugin ZIP as another plugin.

`build-plugin.bat` recreates this source bundle from a clean staging list before assembling the outer plugin ZIP. Build outputs, logs, reports, and other generated directories are deliberately excluded from the nested source archive.

## Historical provenance

Known-good Alpha 21 plugin ZIP SHA-256:

```text
ab8f5186788dc2838a33096dde2a12d8da48fbb86fdc8cba75fe3de058ee4eae
```

Original Alpha 21 source ZIP SHA-256:

```text
3dc4c26f136874e8d0aff823edde231115eb2fbe7081876db4c5abd67fbcee39
```

Those hashes establish the implementation from which Beta 1 was promoted.

## Checker validation controls

Positive control:

```text
MCreator 2026.2 build 33518
neoforge-26.1.2 / buildfileversion 26.1.2.95
81 PASS, 0 WARN, 0 FAIL, 0 SKIP
```

Negative control:

```text
MCreator 2026.1 build 14619
neoforge-1.21.8 / buildfileversion 21.8.31
60 PASS, 14 WARN, 3 FAIL, 0 SKIP
```

The negative control correctly detected the older `LivingEntity.mobSpawningType` data model and matching generator-template difference while Java compilation still passed.

These controls validate checker behavior. They do **not** make MCreator 2026.1 a supported target.

## Release checksums

Do not place the current source archive's own hash inside that archive: doing so creates a self-referential checksum problem. Record final Beta 1 plugin/source SHA-256 values in the release notes or an adjacent checksum file instead.
