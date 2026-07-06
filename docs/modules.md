# Ability Combat Modules

## Stats And Resources

Stats define reusable stat identifiers, current/base values, grouped stat blocks, and a node component for actors. Resources define cost/resource categories consumed by skills.

## Damage

Damage resources describe damage types, mitigation types, formulas, scaling terms, and calculation breakdowns. Effects can use these resources to apply structured damage without hard-coding formulas into skill logic.

## Status

Status definitions model buffs, debuffs, tags, categories, duration behavior, cleanse rules, and effect modules. Status controllers and receivers coordinate applying, refreshing, ticking, and removing active status instances.

## Movement

Movement contains ability-driven forced movement support. It is separated from player input so skills and statuses can request movement effects without owning character control code.

## Skills And Abilities

Skills contain definitions, costs, requirements, cast context, targeting strategies, aim controllers, slot/layout data, lifecycle events, and reusable effects. Skill effects compose combat actions such as damage, status application, stat changes, caster movement, and projectile spawning.

## Dependencies

Ability Combat depends on:

- Godot Modular Data for resource variables, references, runtime sets, and scriptable enums.
- Godot Events for typed event channels and event payload/listener patterns.

Vendored copies are included in this repository only for validation and examples.
