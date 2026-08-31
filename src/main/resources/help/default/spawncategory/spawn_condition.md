The default predicate checked after the placement location and heightmap select a candidate position.

- **ALWAYS_ALLOW** adds no additional predicate restriction.
- **MONSTER** requires non-Peaceful difficulty, darkness, and normal mob checks.
- **CREATURE** requires animal-spawnable ground and brightness above 8.
- **AMBIENT** uses normal mob spawn checks.
- **WATER_CREATURE** requires water at the position and directly above it.

A custom spawning-condition procedure on the Living Entity overrides this selection.
