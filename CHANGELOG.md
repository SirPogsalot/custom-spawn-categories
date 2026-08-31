# Changelog

## 0.3.0-beta1

First beta release. Runtime functionality is promoted from the tested 0.3.0-alpha21 implementation; no new spawn-category or procedure behavior is intentionally introduced in this promotion.

- Keeps Alpha 21 identifier validation, duplicate protection, custom placement, category-level spawn conditions, and persistence-aware mob-cap guidance.
- Keeps the vanilla/custom spawn-category procedure selectors and the membership / loaded-count blocks.
- Includes the validated compatibility checker and future-port documentation.
- Bundles the maintenance source archive inside the distributable plugin ZIP under `maintenance/` for easier recovery and handoff.
- Build script now reproduces both the plugin ZIP and its embedded maintenance source bundle.

### Tested baseline

- MCreator 2026.2 build 33518
- Generator `neoforge-26.1.2`
- NeoForge buildfileversion 26.1.2.95

## 0.3.0-alpha21

Final alpha feature baseline before beta promotion. Added identifier and duplication polishing, persistence/mob-cap documentation, and retained the tested Alpha 18-style helper-generation architecture plus Alpha 20 procedure blocks.
