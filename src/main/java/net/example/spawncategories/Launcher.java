package net.example.spawncategories;

import net.example.spawncategories.parts.PluginElementTypes;
import net.mcreator.plugin.JavaPlugin;
import net.mcreator.plugin.MCREventListener;
import net.mcreator.plugin.Plugin;
import net.mcreator.plugin.events.PreGeneratorsLoadingEvent;
import net.mcreator.plugin.events.ui.ModElementGUIEvent;

public final class Launcher extends JavaPlugin {
    public Launcher(Plugin plugin) {
        super(plugin);

        addListener(PreGeneratorsLoadingEvent.class, new MCREventListener<PreGeneratorsLoadingEvent>() {
            @Override
            public void eventTriggered(PreGeneratorsLoadingEvent event) {
                PluginElementTypes.load();
            }
        });

        addListener(ModElementGUIEvent.AfterLoading.class, new MCREventListener<ModElementGUIEvent.AfterLoading>() {
            @Override
            public void eventTriggered(ModElementGUIEvent.AfterLoading event) {
                LivingEntitySpawnCategoryBridge.onAfterLoading(event);
            }
        });
    }
}
