(* Specializations for convenience *)
let spawn_player (em : Entity_manager.t) ~pos ~direction ~actor_id =
  {
    pos;
    direction;
    id = 0;
    glyph = "@";
    name = "Player";
    kind = Player;
    description = Some "This is you!";
    data = PlayerData { stats = Types.Stats.default; actor_id };
  }
  |> Entity_manager.add em

let spawn_creature (em : Entity_manager.t) ~pos ~direction ~species ~health
    ~glyph ~name ~actor_id ~description =
  {
    pos;
    direction;
    glyph;
    name;
    description = Some description;
    kind = Creature;
    data =
      CreatureData
        {
          species;
          actor_id;
          stats =
            Types.Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5
              ~speed:100;
        };
  }
  |> Entity_manager.add_entity em

let spawn_item (em : Entity_manager.t) ~pos ~direction ~item_type ~quantity
    ~name ~glyph ?(description = None) () =
  {
    pos;
    glyph;
    name;
    direction;
    description;
    kind = Item;
    data =
      ItemData
        {
          item =
            Types.Item.create ~item_type ~quantity ~name ~description:None ();
        };
  }
  |> Entity_manager.add_entity em
