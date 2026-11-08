extends "res://scripts/game_engine.gd"
func _init():
 super()
 _v29=preload("res://tests/balance_pouch_policy_v29.gd").new(self)
func _position_score(fid: int,destination: int,away=false) -> float:
 var score=super._position_score(fid,destination,away)
 var owner=int(fighters[fid].owner)
 if _is_hero(owner,"mikula"):
  var bag=_v29.pouch(owner)
  if bag>=0 and (bag==destination or nodes[bag].neighbors.has(destination)):score+=4.0
 return score
