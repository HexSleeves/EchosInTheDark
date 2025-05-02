open Base

type chunk_gen_algo =
  | CA
  | Rooms
  | Prefab of string
  | Custom of
      (width:int -> height:int -> rng:Random.State.t -> Dungeon.Tile.t array)
