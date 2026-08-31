<#assign categories = w.getGElementsOfType("spawncategory")>
<#assign reservedCategoryNames = ["monster", "creature", "ambient", "axolotls", "underground_water_creature", "water_creature", "water_ambient", "misc"]>
<#assign seenCategoryNames = []>
<#list categories as category>
    <#assign categoryName = category.getCategoryName()?lower_case>
    <#if reservedCategoryNames?seq_contains(categoryName)>
        <#stop "Spawn Category '" + category.getModElement().getName() + "' uses reserved vanilla MobCategory identifier '" + categoryName + "'. Please choose a different Category identifier.">
    </#if>
    <#if seenCategoryNames?seq_contains(categoryName)>
        <#stop "Duplicate Spawn Category identifier '" + categoryName + "'. Every Spawn Category must have a unique Category identifier before code can be generated.">
    </#if>
    <#assign seenCategoryNames += [categoryName]>
</#list>
/*
 * This file is generated from all Spawn Category mod elements.
 * It will be regenerated whenever the workspace is built.
 */
package ${package}.init;

import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.level.LevelAccessor;

import java.util.IdentityHashMap;
import java.util.Map;
import java.util.WeakHashMap;

public final class ${JavaModName}MobCategories {
    private static final Map<ServerLevel, CategoryCountCache> CATEGORY_COUNT_CACHE = new WeakHashMap<>();

<#list categories as category>
    public static final MobCategory ${category.getCategoryName()?upper_case} =
        MobCategory.valueOf("${modid?upper_case}_${category.getCategoryName()?upper_case}");

</#list>
    /**
     * Resolves a category through the immutable MCreator mod-element name.
     * This indirection keeps Living Entity code valid when registry names or
     * user-facing category identifiers are edited later.
     */
    public static MobCategory resolve(String modElementName) {
        return switch (modElementName) {
<#list categories as category>
            case "${category.getModElement().getName()}" -> ${category.getCategoryName()?upper_case};
</#list>
            default -> throw new IllegalArgumentException("Unknown custom spawn category: " + modElementName);
        };
    }

    public static boolean entityBelongsToCategory(Entity entity, MobCategory category) {
        return entity != null && category != null && entity.getType().getCategory() == category;
    }

    /**
     * Returns the number of currently loaded, non-removed entities whose
     * EntityType belongs to the requested MobCategory. Counts are cached for
     * one server tick so repeated spawn-condition checks do not scan every
     * loaded entity on every individual spawn attempt.
     */
    public static int countLoadedEntitiesInCategory(LevelAccessor world, MobCategory category) {
        if (!(world instanceof ServerLevel serverLevel) || category == null) {
            return 0;
        }

        synchronized (CATEGORY_COUNT_CACHE) {
            CategoryCountCache cache = CATEGORY_COUNT_CACHE.computeIfAbsent(serverLevel,
                    ignored -> new CategoryCountCache());
            long gameTime = serverLevel.getGameTime();
            if (cache.gameTime != gameTime) {
                cache.gameTime = gameTime;
                cache.counts.clear();
                for (Entity entity : serverLevel.getAllEntities()) {
                    if (entity != null && !entity.isRemoved()) {
                        MobCategory entityCategory = entity.getType().getCategory();
                        cache.counts.merge(entityCategory, 1, Integer::sum);
                    }
                }
            }
            return cache.counts.getOrDefault(category, 0);
        }
    }

    private static final class CategoryCountCache {
        private long gameTime = Long.MIN_VALUE;
        private final IdentityHashMap<MobCategory, Integer> counts = new IdentityHashMap<>();
    }

    private ${JavaModName}MobCategories() {
    }
}
