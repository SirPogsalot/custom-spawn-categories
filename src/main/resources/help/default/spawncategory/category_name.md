The generated identifier for this spawn category.

For a newly created Spawn Category, this field is initialized from the mod element's registry name, but it is saved independently afterward. Duplicating a Spawn Category will choose a new identifier when the duplicated element is opened if its copied identifier conflicts with an earlier category.

Use 1–64 lowercase letters, numbers, and underscores only, beginning with a letter. The identifier must be unique within the workspace and may not reuse a vanilla `MobCategory` identifier (`monster`, `creature`, `ambient`, `axolotls`, `underground_water_creature`, `water_creature`, `water_ambient`, or `misc`).

This identifier controls the enum-extension name, serialized category name, generated Java constant, and the label shown in Living Entity spawn-category lists.
