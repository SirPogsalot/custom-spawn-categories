package net.example.spawncategories;

import net.example.spawncategories.elements.SpawnCategory;
import net.mcreator.element.GeneratableElement;
import net.mcreator.plugin.events.ui.ModElementGUIEvent;
import net.mcreator.ui.modgui.ModElementGUI;
import net.mcreator.workspace.Workspace;
import net.mcreator.workspace.elements.ModElement;

import javax.swing.*;
import java.awt.*;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public final class LivingEntitySpawnCategoryBridge {
    private static final String LIVING_ENTITY_GUI = "net.mcreator.ui.modgui.LivingEntityGUI";
    private static final String CUSTOM_PREFIX = "CUSTOM:";
    private static final String RENDERER_MARKER = "custom_spawn_categories.renderer_installed";
    private static final String DISPLAY_NAMES = "custom_spawn_categories.display_names";

    private LivingEntitySpawnCategoryBridge() {
    }

    public static void onAfterLoading(ModElementGUIEvent.AfterLoading event) {
        ModElementGUI<?> gui = event.getModElementGUI();
        if (gui == null || !LIVING_ENTITY_GUI.equals(gui.getClass().getName())) {
            return;
        }
        SwingUtilities.invokeLater(() -> enhanceLivingEntityGUI(event, gui));
    }

    private static void enhanceLivingEntityGUI(ModElementGUIEvent.AfterLoading event, ModElementGUI<?> gui) {
        try {
            Field field = gui.getClass().getDeclaredField("mobSpawningType");
            field.setAccessible(true);
            @SuppressWarnings("unchecked")
            JComboBox<String> comboBox = (JComboBox<String>) field.get(gui);
            if (comboBox == null) {
                return;
            }

            Workspace workspace = event.getMCreator().getWorkspace();
            List<ModElement> categories = new ArrayList<>();
            if (workspace != null && workspace.getModElements() != null) {
                for (ModElement element : workspace.getModElements()) {
                    if (element != null && "spawncategory".equals(element.getTypeString())) {
                        categories.add(element);
                    }
                }
            }
            categories.sort(Comparator.comparing(
                    LivingEntitySpawnCategoryBridge::categoryDisplayName,
                    String.CASE_INSENSITIVE_ORDER));

            Map<String, String> displayNames = new HashMap<>();
            for (ModElement category : categories) {
                String reference = CUSTOM_PREFIX + category.getName();
                addIfMissing(comboBox, reference);
                displayNames.put(reference, "Custom: " + humanize(categoryDisplayName(category)));
            }
            comboBox.putClientProperty(DISPLAY_NAMES, displayNames);
            installRenderer(comboBox);

            String savedReference = gui.isEditingMode() ? readSavedReference(gui.getModElement()) : null;
            if (savedReference != null && savedReference.startsWith(CUSTOM_PREFIX)) {
                addIfMissing(comboBox, savedReference);
                restoreSelection(comboBox, savedReference);
                SwingUtilities.invokeLater(() -> restoreSelection(comboBox, savedReference));
                Timer timer = new Timer(120, event1 -> restoreSelection(comboBox, savedReference));
                timer.setRepeats(false);
                timer.start();
            }
        } catch (ReflectiveOperationException | RuntimeException exception) {
            System.err.println("[Custom Spawn Categories] Could not enhance Living Entity spawn type selector: " + exception);
            exception.printStackTrace(System.err);
        }
    }

    private static String categoryDisplayName(ModElement element) {
        if (element != null) {
            GeneratableElement definition = element.getGeneratableElement();
            if (definition instanceof SpawnCategory category) {
                return category.getCategoryName();
            }
            if (element.getRegistryName() != null && !element.getRegistryName().isBlank()) {
                return element.getRegistryName();
            }
            return element.getName();
        }
        return "spawn_category";
    }

    private static void restoreSelection(JComboBox<String> comboBox, String reference) {
        addIfMissing(comboBox, reference);
        if (!reference.equals(comboBox.getSelectedItem())) {
            comboBox.setSelectedItem(reference);
        }
    }

    private static void addIfMissing(JComboBox<String> comboBox, String value) {
        for (int i = 0; i < comboBox.getItemCount(); i++) {
            if (value.equals(comboBox.getItemAt(i))) {
                return;
            }
        }
        comboBox.addItem(value);
    }

    private static String readSavedReference(ModElement modElement) throws ReflectiveOperationException {
        if (modElement == null) {
            return null;
        }
        GeneratableElement element = modElement.getGeneratableElement();
        if (element == null) {
            return null;
        }
        Field field = element.getClass().getField("mobSpawningType");
        Object mappedValue = field.get(element);
        if (mappedValue == null) {
            return null;
        }
        Method method = mappedValue.getClass().getMethod("getUnmappedValue");
        Object value = method.invoke(mappedValue);
        return value instanceof String string ? string : null;
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static void installRenderer(JComboBox<String> comboBox) {
        if (Boolean.TRUE.equals(comboBox.getClientProperty(RENDERER_MARKER))) {
            return;
        }
        comboBox.putClientProperty(RENDERER_MARKER, Boolean.TRUE);
        ListCellRenderer original = comboBox.getRenderer();
        comboBox.setRenderer((list, value, index, selected, focus) -> {
            Component component = original.getListCellRendererComponent(list, value, index, selected, focus);
            if (component instanceof JLabel label && value instanceof String string && string.startsWith(CUSTOM_PREFIX)) {
                Object property = comboBox.getClientProperty(DISPLAY_NAMES);
                String display = null;
                if (property instanceof Map<?, ?> map) {
                    Object mapped = map.get(string);
                    if (mapped instanceof String mappedString) {
                        display = mappedString;
                    }
                }
                if (display == null) {
                    display = "Custom: " + humanize(string.substring(CUSTOM_PREFIX.length()));
                }
                label.setText(display);
            }
            return component;
        });
    }

    private static String humanize(String value) {
        String spaced = value.replace('_', ' ')
                .replace('-', ' ')
                .replaceAll("([a-z0-9])([A-Z])", "$1 $2")
                .replaceAll("\\s+", " ")
                .trim();
        if (spaced.isEmpty()) {
            return value;
        }
        return spaced.substring(0, 1).toUpperCase(Locale.ENGLISH) + spaced.substring(1);
    }
}
