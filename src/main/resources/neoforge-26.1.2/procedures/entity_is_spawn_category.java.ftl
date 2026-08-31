<#if field$category?starts_with("CUSTOM:")>
    <#assign selectedCategory = package + ".init." + JavaModName + "MobCategories.resolve(\"" + field$category?replace("CUSTOM:", "") + "\")">
<#else>
    <#assign selectedCategory = "net.minecraft.world.entity." + generator.map(field$category, "mobspawntypes")>
</#if>
(${package}.init.${JavaModName}MobCategories.entityBelongsToCategory(${input$entity}, ${selectedCategory}))
