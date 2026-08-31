package net.example.spawncategories.elements;

import net.example.spawncategories.elements.SpawnCategory;
import net.mcreator.blockly.data.Dependency;
import net.mcreator.element.GeneratableElement;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.help.HelpUtils;
import net.mcreator.ui.init.L10N;
import net.mcreator.ui.modgui.ModElementGUI;
import net.mcreator.ui.procedure.AbstractProcedureSelector;
import net.mcreator.ui.procedure.ProcedureSelector;
import net.mcreator.ui.validation.ValidationResult;
import net.mcreator.ui.validation.Validator;
import net.mcreator.ui.validation.component.VTextField;
import net.mcreator.workspace.elements.ModElement;
import net.mcreator.workspace.elements.VariableTypeLoader;

import javax.swing.*;
import java.awt.*;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.net.URI;
import java.util.Locale;

public final class SpawnCategoryGUI extends ModElementGUI<SpawnCategory> {
    private static final int MOB_CAP_MIN = 0;
    private static final int MOB_CAP_MAX = 1024;
    private static final int DESPAWN_DISTANCE_MIN = 32;
    private static final int DESPAWN_DISTANCE_MAX = 4096;

    private final VTextField categoryName = new VTextField(24);
    private final JSpinner mobCap = new JSpinner(new SpinnerNumberModel(25, MOB_CAP_MIN, MOB_CAP_MAX, 1));
    private final JCheckBox friendly = new JCheckBox();
    private final JCheckBox persistent = new JCheckBox();
    private final JSpinner despawnDistance = new JSpinner(
            new SpinnerNumberModel(128, DESPAWN_DISTANCE_MIN, DESPAWN_DISTANCE_MAX, 1));
    private final JComboBox<String> placementMode = new JComboBox<>(new String[]{"PRESET", "CUSTOM"});
    private final JComboBox<String> placementPreset = new JComboBox<>(
            new String[]{"MONSTER", "CREATURE", "AMBIENT", "WATER_CREATURE", "NO_RESTRICTIONS"});
    private final JComboBox<String> customPlacementType = new JComboBox<>(
            new String[]{"ON_GROUND", "IN_WATER", "NO_RESTRICTIONS"});
    private final JComboBox<String> customHeightmap = new JComboBox<>(
            new String[]{"MOTION_BLOCKING", "MOTION_BLOCKING_NO_LEAVES", "OCEAN_FLOOR", "WORLD_SURFACE"});
    private final JComboBox<String> customSpawnCondition = new JComboBox<>(
            new String[]{"ALWAYS_ALLOW", "MONSTER", "CREATURE", "AMBIENT", "WATER_CREATURE"});
    private final ProcedureSelector spawnConditionProcedure;

    public SpawnCategoryGUI(MCreator mcreator, ModElement modElement, boolean editingMode) {
        super(mcreator, modElement, editingMode);

        categoryName.setValidator(new Validator() {
            @Override
            public ValidationResult validate() {
                return validateCategoryName();
            }
        });
        categoryName.enableRealtimeValidation();

        spawnConditionProcedure = new ProcedureSelector(
                withEntry("spawncategory/spawn_condition_procedure"),
                mcreator,
                "Procedure",
                VariableTypeLoader.BuiltInTypes.LOGIC,
                Dependency.fromString("x:number/y:number/z:number/world:world")
        ).setDefaultName("Use configured placement condition").makeInline();

        initGUI();
        if (!editingMode && (categoryName.getText() == null || categoryName.getText().isBlank())) {
            categoryName.setText(makeUniqueCategoryName(SpawnCategory.defaultCategoryName(modElement)));
        }
        finalizeGUI();
    }

    @Override
    protected void initGUI() {
        JPanel root = new JPanel();
        root.setLayout(new BoxLayout(root, BoxLayout.Y_AXIS));
        root.setBorder(BorderFactory.createEmptyBorder(18, 24, 20, 24));
        root.setOpaque(false);

        root.add(createPerformanceWarning());
        root.add(Box.createVerticalStrut(14));

        JPanel behavior = createSection("Category behavior");
        int row = 0;
        addRow(behavior, row++, "Category identifier:", categoryName, "spawncategory/category_name");
        addRow(behavior, row++, "Mob cap:", mobCap, "spawncategory/mob_cap");
        addRow(behavior, row++, "Friendly category:", friendly, "spawncategory/friendly");
        addRow(behavior, row++, "Use periodic 400-tick spawn checks:", persistent,
                "spawncategory/periodic_spawn_checks");
        addRow(behavior, row, "Despawn distance:", despawnDistance, "spawncategory/despawn_distance");

        JPanel placement = createSection("Default entity spawn placement");
        row = 0;
        addRow(placement, row++, "Configuration mode:", placementMode, "spawncategory/placement_mode");
        addRow(placement, row++, "Placement preset:", placementPreset, "spawncategory/placement_preset");
        addRow(placement, row++, "Placement location:", customPlacementType, "spawncategory/placement_type");
        addRow(placement, row++, "Heightmap (special spawning):", customHeightmap, "spawncategory/heightmap");
        addRow(placement, row++, "Default spawn condition:", customSpawnCondition,
                "spawncategory/spawn_condition");
        addRow(placement, row, "Spawn condition procedure:", spawnConditionProcedure,
                "spawncategory/spawn_condition_procedure");

        placementMode.addActionListener(event -> updatePlacementModeState());
        updatePlacementModeState();

        JPanel sections = new JPanel(new GridLayout(1, 2, 16, 0));
        sections.setOpaque(false);
        sections.setAlignmentX(Component.LEFT_ALIGNMENT);
        sections.add(behavior);
        sections.add(placement);

        root.add(sections);
        root.add(Box.createVerticalGlue());

        addPage(root).validate(categoryName);
    }

    private JComponent createPerformanceWarning() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setOpaque(false);
        panel.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(214, 142, 0, 150)),
                BorderFactory.createEmptyBorder(5, 10, 5, 10)
        ));

        JLabel warning = new JLabel("<html><div style='width:760px'><b>Performance warning:</b> "
                + "Use custom categories and mob caps sparingly; every category has an independent cap. "
                + "Living Entities with <b>Despawn when idle</b> disabled are persistence-required and do not "
                + "count toward natural-spawn caps, so they can accumulate beyond the configured cap.</div></html>");
        Color warningColor = UIManager.getColor("Component.warning.focusedBorderColor");
        warning.setForeground(warningColor != null ? warningColor : new Color(230, 160, 40));
        panel.add(warning, BorderLayout.CENTER);

        Dimension preferred = panel.getPreferredSize();
        panel.setMaximumSize(new Dimension(Integer.MAX_VALUE, preferred.height));
        return panel;
    }

    private JPanel createSection(String title) {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBorder(BorderFactory.createTitledBorder(title));
        panel.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.setOpaque(false);
        return panel;
    }

    private void addRow(JPanel panel, int row, String label, Component component, String helpEntry) {
        GridBagConstraints labelConstraints = new GridBagConstraints();
        labelConstraints.gridx = 0;
        labelConstraints.gridy = row;
        labelConstraints.anchor = GridBagConstraints.WEST;
        labelConstraints.insets = new Insets(6, 8, 6, 12);
        panel.add(HelpUtils.wrapWithHelpButton(withEntry(helpEntry), new JLabel(label)), labelConstraints);

        configurePreferredWidth(component);
        JPanel fieldHolder;
        if (component instanceof ProcedureSelector) {
            fieldHolder = new JPanel(new BorderLayout());
            fieldHolder.setOpaque(false);
            component.setMinimumSize(new Dimension(260, component.getPreferredSize().height));
            fieldHolder.add(component, BorderLayout.CENTER);
        } else {
            fieldHolder = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
            fieldHolder.setOpaque(false);
            fieldHolder.add(component);
        }

        GridBagConstraints fieldConstraints = new GridBagConstraints();
        fieldConstraints.gridx = 1;
        fieldConstraints.gridy = row;
        fieldConstraints.weightx = 1.0;
        fieldConstraints.fill = GridBagConstraints.HORIZONTAL;
        fieldConstraints.anchor = GridBagConstraints.WEST;
        fieldConstraints.insets = new Insets(6, 6, 6, 8);
        panel.add(fieldHolder, fieldConstraints);
    }

    private void configurePreferredWidth(Component component) {
        Dimension preferred = component.getPreferredSize();
        int width;
        if (component instanceof JSpinner) {
            width = 132;
        } else if (component instanceof JCheckBox) {
            width = Math.max(28, preferred.width);
        } else if (component instanceof VTextField) {
            width = 300;
        } else if (component instanceof ProcedureSelector) {
            width = 520;
        } else if (component instanceof JComboBox<?> comboBox) {
            width = comboWidth(comboBox);
        } else {
            width = Math.min(Math.max(preferred.width, 180), 560);
        }
        component.setPreferredSize(new Dimension(width, preferred.height));
    }

    private int comboWidth(JComboBox<?> comboBox) {
        FontMetrics metrics = comboBox.getFontMetrics(comboBox.getFont());
        int max = 0;
        for (int i = 0; i < comboBox.getItemCount(); i++) {
            Object item = comboBox.getItemAt(i);
            if (item != null) {
                max = Math.max(max, metrics.stringWidth(item.toString()));
            }
        }
        return Math.min(Math.max(max + 64, 220), 430);
    }

    private void updatePlacementModeState() {
        boolean custom = "CUSTOM".equals(placementMode.getSelectedItem());
        placementPreset.setEnabled(!custom);
        customPlacementType.setEnabled(custom);
        customHeightmap.setEnabled(custom);
        customSpawnCondition.setEnabled(custom);
    }

    @Override
    public void reloadDataLists() {
        super.reloadDataLists();
        AbstractProcedureSelector.ReloadContext context =
                AbstractProcedureSelector.ReloadContext.create(mcreator.getWorkspace());
        spawnConditionProcedure.refreshListKeepSelected(context);
    }

    @Override
    protected void openInEditingMode(SpawnCategory element) {
        String storedName = element.getCategoryName();
        if (hasEarlierCategoryWithIdentifier(storedName)) {
            storedName = makeUniqueCategoryName(SpawnCategory.defaultCategoryName(modElement));
        }
        categoryName.setText(storedName);
        mobCap.setValue(clamp(element.mobCap, MOB_CAP_MIN, MOB_CAP_MAX));
        friendly.setSelected(element.friendly);
        persistent.setSelected(element.persistent);
        despawnDistance.setValue(clamp(element.despawnDistance, DESPAWN_DISTANCE_MIN, DESPAWN_DISTANCE_MAX));
        placementMode.setSelectedItem(safeChoice(element.placementMode, "PRESET"));
        placementPreset.setSelectedItem(safeChoice(element.placementPreset, "CREATURE"));
        customPlacementType.setSelectedItem(safeChoice(element.customPlacementType, "ON_GROUND"));
        customHeightmap.setSelectedItem(safeChoice(element.customHeightmap, "MOTION_BLOCKING_NO_LEAVES"));
        customSpawnCondition.setSelectedItem(safeChoice(element.customSpawnCondition, "AMBIENT"));
        spawnConditionProcedure.setSelectedProcedure(element.spawnConditionProcedure);
        updatePlacementModeState();
    }

    private ValidationResult validateCategoryName() {
        String value = categoryName.getText() == null ? "" : categoryName.getText().trim();
        if (value.isEmpty()) {
            return new ValidationResult(ValidationResult.Type.ERROR,
                    L10N.t("elementgui.spawncategory.category_name_required"));
        }
        if (!value.matches("[a-z][a-z0-9_]{0,63}")) {
            return new ValidationResult(ValidationResult.Type.ERROR,
                    L10N.t("elementgui.spawncategory.category_name_format"));
        }
        if (SpawnCategory.isReservedVanillaName(value)) {
            return new ValidationResult(ValidationResult.Type.ERROR,
                    L10N.t("elementgui.spawncategory.category_name_reserved"));
        }
        for (ModElement element : mcreator.getWorkspace().getModElements()) {
            if (element == null || element.equals(modElement) || !"spawncategory".equals(element.getTypeString())) {
                continue;
            }
            GeneratableElement definition = element.getGeneratableElement();
            String otherName;
            if (definition instanceof SpawnCategory otherCategory) {
                otherName = otherCategory.getCategoryName();
            } else {
                otherName = element.getRegistryName();
            }
            if (value.equalsIgnoreCase(otherName)) {
                return new ValidationResult(ValidationResult.Type.ERROR,
                        L10N.t("elementgui.spawncategory.category_name_duplicate"));
            }
        }
        return ValidationResult.PASSED;
    }

    private boolean hasEarlierCategoryWithIdentifier(String identifier) {
        if (identifier == null || identifier.isBlank()) {
            return false;
        }
        for (ModElement element : mcreator.getWorkspace().getModElements()) {
            if (element == null || !"spawncategory".equals(element.getTypeString())) {
                continue;
            }
            if (element.equals(modElement)) {
                return false;
            }
            String otherName = categoryIdentifierOf(element);
            if (identifier.equalsIgnoreCase(otherName)) {
                return true;
            }
        }
        return false;
    }

    private String makeUniqueCategoryName(String preferred) {
        String base = preferred == null || preferred.isBlank() ? "spawn_category" : preferred.toLowerCase(Locale.ENGLISH);
        if (SpawnCategory.isReservedVanillaName(base)) {
            base = base + "_category";
        }
        if (!isCategoryNameTaken(base)) {
            return base;
        }

        for (int index = 2; index < 10000; index++) {
            String suffix = "_" + index;
            int baseLength = Math.min(base.length(), 64 - suffix.length());
            String candidate = base.substring(0, baseLength) + suffix;
            if (!isCategoryNameTaken(candidate) && !SpawnCategory.isReservedVanillaName(candidate)) {
                return candidate;
            }
        }
        return "spawn_category_" + Math.abs(modElement.getName().hashCode());
    }

    private boolean isCategoryNameTaken(String identifier) {
        for (ModElement element : mcreator.getWorkspace().getModElements()) {
            if (element == null || element.equals(modElement) || !"spawncategory".equals(element.getTypeString())) {
                continue;
            }
            if (identifier.equalsIgnoreCase(categoryIdentifierOf(element))) {
                return true;
            }
        }
        return false;
    }

    private static String categoryIdentifierOf(ModElement element) {
        GeneratableElement definition = element.getGeneratableElement();
        if (definition instanceof SpawnCategory otherCategory) {
            return otherCategory.getCategoryName();
        }
        return SpawnCategory.defaultCategoryName(element);
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    private static String safeChoice(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    @Override
    public SpawnCategory getElementFromGUI() {
        SpawnCategory element = new SpawnCategory(modElement);
        element.categoryName = categoryName.getText().trim().toLowerCase(Locale.ENGLISH);
        element.mobCap = ((Number) mobCap.getValue()).intValue();
        element.friendly = friendly.isSelected();
        element.persistent = persistent.isSelected();
        element.despawnDistance = ((Number) despawnDistance.getValue()).intValue();
        element.placementMode = (String) placementMode.getSelectedItem();
        element.placementPreset = (String) placementPreset.getSelectedItem();
        element.customPlacementType = (String) customPlacementType.getSelectedItem();
        element.customHeightmap = (String) customHeightmap.getSelectedItem();
        element.customSpawnCondition = (String) customSpawnCondition.getSelectedItem();
        element.spawnConditionProcedure = spawnConditionProcedure.getSelectedProcedure();
        return element;
    }

    @Override
    protected void afterGeneratableElementGenerated() {
        String reference = "CUSTOM:" + modElement.getName();
        for (ModElement element : mcreator.getWorkspace().getModElements()) {
            if (!"livingentity".equals(element.getTypeString())) {
                continue;
            }
            GeneratableElement definition = element.getGeneratableElement();
            if (definition != null && usesCategory(definition, reference)) {
                mcreator.getGenerator().generateElement(definition);
            }
        }
    }

    private static boolean usesCategory(GeneratableElement element, String reference) {
        try {
            Field field = element.getClass().getField("mobSpawningType");
            Object mappedValue = field.get(element);
            if (mappedValue == null) {
                return false;
            }
            Method method = mappedValue.getClass().getMethod("getUnmappedValue");
            return reference.equals(method.invoke(mappedValue));
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            return false;
        }
    }

    @Override
    public URI contextURL() {
        return null;
    }
}
