# Dependency Notes

This addon expects compatible copies of these addons in consuming projects:

- Godot Modular Data at `res://addons/modular_data`.
- Godot Events at `res://addons/godot_events`.

The vendored dependency folders in this repository are included to make the validation project load cleanly. Do not treat them as Ability Combat runtime source.

Runtime scripts should use the standalone addon layout and avoid references back to the original demo project tree.
