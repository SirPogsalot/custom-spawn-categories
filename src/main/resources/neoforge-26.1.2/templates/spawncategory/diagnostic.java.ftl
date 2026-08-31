package ${package}.init;

/** Diagnostic snapshot of the values stored by this Spawn Category element. */
public final class ${name}Definition {
    public static final String CATEGORY_NAME = "${data.getCategoryName()}";
    public static final int MOB_CAP = ${data.mobCap};
    public static final boolean FRIENDLY = ${data.friendly?c};
    public static final boolean PERIODIC_SPAWN_CHECKS = ${data.persistent?c};
    public static final int DESPAWN_DISTANCE = ${data.despawnDistance};
    public static final String PLACEMENT_MODE = "${(data.placementMode)!"PRESET"}";
    public static final String PLACEMENT_PRESET = "${(data.placementPreset)!"CREATURE"}";
    public static final String CUSTOM_PLACEMENT_TYPE = "${(data.customPlacementType)!"ON_GROUND"}";
    public static final String CUSTOM_HEIGHTMAP = "${(data.customHeightmap)!"MOTION_BLOCKING_NO_LEAVES"}";
    public static final String CUSTOM_SPAWN_CONDITION = "${(data.customSpawnCondition)!"AMBIENT"}";

    private ${name}Definition() {
    }
}
