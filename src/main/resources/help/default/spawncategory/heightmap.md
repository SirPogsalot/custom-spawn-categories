Controls the heightmap stored in the entity's spawn-placement registration.

In Minecraft 26.1.2, this heightmap is **not used to choose the Y coordinate for ordinary natural spawning**. The normal natural spawner first chooses a random Y between the world minimum and the column's world surface, then checks the placement location and spawn condition at that position. This is why selecting **WORLD_SURFACE** does not prevent underground spawning.

The registered heightmap is mainly consulted by systems that deliberately request a top position, such as chunk-generation or other special spawners.

- **MOTION_BLOCKING** includes blocks and fluids that block motion.
- **MOTION_BLOCKING_NO_LEAVES** is similar but ignores leaves.
- **OCEAN_FLOOR** selects the highest motion-blocking position below fluids.
- **WORLD_SURFACE** selects the highest non-air position.

To require surface-only or underground-only ordinary spawning, use the category's **Spawn condition procedure** to compare the candidate Y position with the world heightmap or sky visibility.

This field is used only in **CUSTOM** mode.
