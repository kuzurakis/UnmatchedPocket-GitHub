extends "res://tests/v19_rules_tests.gd"
func run():
 all_catalog_cards_v8()
 print("V21_CARDS checks=%d failures=%d cards=%d"%[checks,failures,card_runs]);quit(1 if failures else 0)
