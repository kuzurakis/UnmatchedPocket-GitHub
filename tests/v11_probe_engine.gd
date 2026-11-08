extends "res://scripts/game_engine.gd"
## Only replaces the boundary after the tested timing. All effect execution,
## decisions and movement use the production engine. Full combats have a
## separate integration suite; this fixture exposes timing results to oracles.
func _finish_combat_values(): phase = "action"
func _complete_flow(): phase = "action"
