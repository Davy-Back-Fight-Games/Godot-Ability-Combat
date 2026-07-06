# Godot Ability Combat

Standalone Godot addon containing the reusable ability/combat runtime extracted from the demo project.

## Contents

- `addons/ability_combat/runtime/stats`: stat identifiers, values, stat blocks, and a stats component.
- `addons/ability_combat/runtime/resources`: resource type definitions used by skill costs and combat systems.
- `addons/ability_combat/runtime/damage`: damage types, mitigation, formulas, scaling terms, and breakdown data.
- `addons/ability_combat/runtime/status`: status definitions, active instances, cleanse rules, receiver/controller nodes, and status effect modules.
- `addons/ability_combat/runtime/movement`: forced movement component for ability-driven movement effects.
- `addons/ability_combat/runtime/skills`: skill definitions, casting context, targeting, requirements, effects, events, aiming, and slots.

## Dependencies

This repository vendors dependency addons for validation and examples:

- `addons/modular_data`: copied from Godot Modular Data.
- `addons/godot_events`: copied from Godot Events.

They are dependencies, not part of the `ability_combat` runtime. Runtime code should continue to reference dependency APIs by their addon paths when explicit paths are needed: `res://addons/modular_data/runtime` and `res://addons/godot_events/runtime`.

## Installation

Copy `addons/ability_combat` into your Godot project. Also install compatible versions of Godot Modular Data and Godot Events.

For local validation in this repository, open the included `project.godot`; all three addons are enabled.

## Preloads

The `ability_combat` runtime currently uses `class_name` references and contains no intentional `preload()` calls.
