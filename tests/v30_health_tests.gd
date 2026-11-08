extends "res://tests/v26_svyatogor_tests.gd"
func run():
 var g=game(["svyatogor","mikula"],true)
 check(g.fighters[0].hp==28 and g.fighters[0].max_hp==28,"new game starts at 28/28")
 g._damage(0,8);g._heal(0,99)
 check(g.fighters[0].hp==28,"healing capped at new maximum")
 g=clone(g)
 check(g.fighters[0].hp==28 and g.fighters[0].max_hp==28,"save roundtrip preserves 28/28")
 g.begin_maneuver()
 check(g.fighters[0].hp==27,"maneuver still costs one health")
 check(g._v19.large(0),"large fighter remains large")
 check(g.heroes.mikula.health==16,"Mikula unchanged")
 print("V30_HEALTH checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
