# Spawn condition procedure

Select an optional **logic procedure** that determines whether entities assigned to this Spawn Category may naturally spawn at the tested position.

The procedure receives `x`, `y`, `z`, and `world` dependencies. When selected, it replaces this category's built-in or custom default spawn condition. A Living Entity's own natural-spawning condition procedure still has the highest priority and overrides this category procedure.
