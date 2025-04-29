open Types
open Entity_manager

type t = Entity_manager.t

let create_base ~name ~glyph ~description ~direction ~pos ?(blocking = true)
    (em : t) =
  let id = next_id em in
  Components.Position.set id pos;

  ( id,
    Entity.make_base_entity ~id ~name ~glyph ~description ~direction ~blocking
      () )

let spawn_player ~pos ~direction (em : t) =
  let id, base =
    create_base ~name:"Player" ~glyph:"@" ~description:(Some "This is you!")
      ~direction ~pos em
  in
  let pdata : Types.player_data =
    {
      equipment = Types.Equipment.empty;
      inventory = { Types.Inventory.items = []; max_slots = 20 };
    }
  in
  Components.Stats.set id Stats.default;
  add_entity (Entity.Player (base, pdata)) em

let spawn_creature ~pos ~direction ~species ~health ~glyph ~name ~description
    ~faction (em : t) =
  let id, base =
    create_base ~name ~glyph ~description ~direction ~pos ~blocking:true em
  in

  let creature_data : Entity.creature_data =
    {
      species;
      stats =
        Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5 ~speed:100;
      faction;
    }
  in

  Components.Stats.set id creature_data.stats;
  add_entity (Entity.Creature (base, creature_data)) em

let spawn_item ~pos ~direction ~item_type ~quantity ~name ~glyph
    ?(description = None) (em : t) =
  let _id, base =
    create_base ~name ~glyph ~description ~direction ~pos ~blocking:false em
  in
  let item = Item.create ~item_type ~quantity ~name ~description:None () in
  add_entity (Entity.Item (base, { item })) em

let spawn_corpse ~pos (em : t) =
  let id, base =
    create_base ~name:"Corpse" ~glyph:"%" ~description:(Some "A dead creature")
      ~direction:Direction.North ~pos ~blocking:false em
  in

  Components.Position.set id pos;
  add (Entity.Corpse base) em
