<#assign raiders = w.getGElementsOfType("livingentity")?filter(e -> e.mobBehaviourType == "Raider")>
<#assign categories = w.getGElementsOfType("spawncategory")>
{
  "entries": [
<#list raiders as raider>
    {
      "enum": "net/minecraft/world/entity/raid/Raid$RaiderType",
      "name": "${modid?upper_case}_${raider.getModElement().getRegistryNameUpper()}",
      "constructor": "(Ljava/util/function/Supplier;[I)V",
      "parameters": {
        "class": "${package?replace(".", "/")}/entity/${raider.getModElement().getName()}Entity",
        "field": "RAIDER_TYPE"
      }
    }<#if raider_has_next || categories?has_content>,</#if>
</#list>
<#list categories as category>
    {
      "enum": "net/minecraft/world/entity/MobCategory",
      "name": "${modid?upper_case}_${category.getCategoryName()?upper_case}",
      "constructor": "(Ljava/lang/String;IZZI)V",
      "parameters": [
        "${modid}:${category.getCategoryName()}",
        ${category.mobCap},
        ${category.friendly?c},
        ${category.persistent?c},
        ${category.despawnDistance}
      ]
    }<#sep>,</#list>
  ]
}
