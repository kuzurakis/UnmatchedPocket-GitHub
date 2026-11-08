extends RefCounted
## Jurassic rule primitives. Not connected to the playable roster yet.
const INSIGHT_SUPPLY := 5
static func insight_add(tokens: Array, node: int) -> bool:
 if tokens.size() >= INSIGHT_SUPPLY or node < 0: return false
 tokens.append(node)
 return true
static func insight_after_move(tokens: Array, origin: int, destination: int, was_placed: bool) -> bool:
 if was_placed or origin == destination: return false
 return insight_add(tokens, destination)
static func insight_clear(tokens: Array) -> int:
 var count := tokens.size()
 tokens.clear()
 return count
static func occupied_spaces(head: int, tail: int) -> Array[int]:
 var result: Array[int] = [head]
 if tail >= 0 and tail != head: result.append(tail)
 return result
static func large_attack_reach(nodes: Array, head: int, tail: int) -> Array[int]:
 var result: Array[int] = []
 var occupied := occupied_spaces(head, tail)
 for origin in occupied:
  if origin < 0 or origin >= nodes.size(): continue
  for neighbor in nodes[origin].neighbors:
   var n := int(neighbor)
   if not occupied.has(n) and not result.has(n): result.append(n)
   for next in nodes[n].neighbors:
    var m := int(next)
    if not occupied.has(m) and not result.has(m): result.append(m)
 return result
