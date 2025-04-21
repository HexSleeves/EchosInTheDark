open Entity

(* Specializations for convenience *)
let spawn_player (em : EntityManager.t) ~pos ~direction ~actor_id =
  {
    pos;
    direction;
    id = 0;
    glyph = "@";
    name = "Player";
    kind = Player;
    description = Some "This is you!";
    data = PlayerData { health = 30; actor_id };
  }
  |> EntityManager.add em

let spawn_creature (em : EntityManager.t) ~pos ~direction ~species ~health
    ~glyph ~name ~actor_id ?(description = None) () =
  {
    pos;
    direction;
    glyph;
    name;
    description;
    kind = Creature;
    data = CreatureData { species; health; actor_id };
  }
  |> EntityManager.add_entity em

let spawn_item (em : EntityManager.t) ~pos ~direction ~item_type ~quantity ~name
    ~glyph ?(description = None) () =
  {
    pos;
    glyph;
    name;
    direction;
    description;
    kind = Item;
    data = ItemData { item_type; quantity };
  }
  |> EntityManager.add_entity em
