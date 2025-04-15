open Types
open Entity

(* Specializations for convenience *)
let spawn_player (em : EntityManager.t) ~pos ~direction =
  {
    pos;
    direction;
    id = 0;
    glyph = "@";
    name = "Player";
    kind = Player;
    description = Some "This is you!";
    data = PlayerData { faction = 0; health = 30 };
  }
  |> EntityManager.add em

let spawn_creature (em : EntityManager.t) ~pos ~direction ~species ~faction
    ~health ~glyph ~name ?(description = None) () =
  {
    pos;
    direction;
    glyph;
    name;
    description;
    kind = Creature;
    data = CreatureData { species; faction; health };
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
