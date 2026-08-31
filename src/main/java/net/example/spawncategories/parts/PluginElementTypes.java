package net.example.spawncategories.parts;

import net.example.spawncategories.elements.SpawnCategory;
import net.example.spawncategories.elements.SpawnCategoryGUI;
import net.mcreator.element.ModElementType;
import net.mcreator.element.ModElementTypeLoader;

public final class PluginElementTypes {
    public static ModElementType<?> SPAWN_CATEGORY;

    private PluginElementTypes() {
    }

    public static void load() {
        SPAWN_CATEGORY = ModElementTypeLoader.register(new ModElementType<>(
                "spawncategory",
                null,
                SpawnCategoryGUI::new,
                SpawnCategory.class
        ));
    }
}
