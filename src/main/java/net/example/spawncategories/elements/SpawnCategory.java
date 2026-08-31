package net.example.spawncategories.elements;

import net.mcreator.element.GeneratableElement;
import net.mcreator.element.parts.procedure.Procedure;
import net.mcreator.workspace.elements.ModElement;

import java.util.Locale;
import java.util.Set;

public final class SpawnCategory extends GeneratableElement {
    public static final Set<String> RESERVED_VANILLA_NAMES = Set.of(
            "monster",
            "creature",
            "ambient",
            "axolotls",
            "underground_water_creature",
            "water_creature",
            "water_ambient",
            "misc"
    );

    public String categoryName;
    public int mobCap = 25;
    public boolean friendly = true;
    public boolean persistent = false;
    public int despawnDistance = 128;
    public String placementPreset = "CREATURE";
    public String placementMode = "PRESET";
    public String customPlacementType = "ON_GROUND";
    public String customHeightmap = "MOTION_BLOCKING_NO_LEAVES";
    public String customSpawnCondition = "AMBIENT";
    public Procedure spawnConditionProcedure;

    public SpawnCategory(ModElement element) {
        super(element);
        this.categoryName = defaultCategoryName(element);
    }

    public String getCategoryName() {
        if (categoryName == null || categoryName.isBlank()) {
            return defaultCategoryName(getModElement());
        }
        return categoryName.toLowerCase(Locale.ENGLISH);
    }

    public static String defaultCategoryName(ModElement element) {
        String value = element == null ? "spawn_category" : element.getRegistryName();
        if (value == null || value.isBlank()) {
            value = element == null ? "spawn_category" : element.getName();
        }
        value = value.toLowerCase(Locale.ENGLISH)
                .replaceAll("[^a-z0-9_]", "_")
                .replaceAll("_+", "_")
                .replaceAll("^_+|_+$", "");
        if (value.isBlank() || !Character.isLetter(value.charAt(0))) {
            value = "category_" + value;
        }
        if (RESERVED_VANILLA_NAMES.contains(value)) {
            value = value + "_category";
        }
        return value;
    }

    public static boolean isReservedVanillaName(String value) {
        return value != null && RESERVED_VANILLA_NAMES.contains(value.toLowerCase(Locale.ENGLISH));
    }

    public String getDescription() {
        String mode = placementMode == null || placementMode.isBlank() ? "PRESET" : placementMode;
        String placement = "CUSTOM".equals(mode) ? customPlacementType : placementPreset;
        return getCategoryName() + " • cap " + mobCap + " • " + placement;
    }
}
