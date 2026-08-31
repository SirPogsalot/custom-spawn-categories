The base global mob cap for this category. Allowed range: **0–1024**.

Minecraft scales this value according to the number of spawnable chunks around players. When the scaled cap is reached, natural spawning attempts for this category stop until the counted population drops.

**Important:** entities marked as persistence-required are not counted toward Minecraft's natural-spawn mob cap. In MCreator, a Living Entity with **Despawn when idle** disabled is marked persistence-required. Naturally spawning entities configured this way can therefore accumulate well beyond this category's mob cap even though the category itself is working correctly. Keep **Despawn when idle** enabled for normal naturally spawning mobs that are expected to obey the cap.

Every custom category has its own independent cap. High values, many separate categories, or persistent naturally spawning entities can create extreme entity counts and severe performance problems.
