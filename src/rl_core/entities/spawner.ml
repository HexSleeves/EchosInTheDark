open Components
open Chunk

type t = Entity_manager.t

let create_base ~name ~glyph ~pos ~description ?(blocking = true) (em : t) =
  let id, em = Entity_manager.spawn em in
  let position = Position.make pos in

  (* Here we set all the components *)
  Position.set id position;
  Name.set id { name };
  Renderable.set id { glyph };
  Blocking.set id blocking;

  (match description with Some desc -> Description.set id desc | None -> ());

  (id, em)

let spawn_player ~pos (em : t) =
  Logs.info (fun m -> m "Spawning player");
  let id, em =
    create_base ~name:"Player" ~glyph:'@' ~pos
      ~description:(Some "This is you!") em
  in

  Stats.set id (Stats.create_default ());
  Inventory.set id { items = []; max_slots = 20 };
  Equipment.set id Equipment.empty;
  Kind.set id Kind.Player;

  em

let spawn_creature ~pos ~species ~health ~glyph ~name ~description ~faction
    (em : t) =
  let id, em = create_base ~name ~glyph ~pos ~description em in

  Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5 ~speed:100 ()
  |> Stats.set id |> ignore;

  (* Set species, faction, etc. as components if you have them *)
  Kind.set id Kind.Creature;
  Species.set id species;
  Faction.set id faction;
  em

let spawn_item ~pos ~item_type ~quantity ~name ~glyph ?(description = None)
    (em : t) =
  let id, em = create_base ~name ~glyph ~pos ~description ~blocking:false em in
  let item = Item.Item_data.create ~item_type ~quantity ~name ~description () in
  Item.set id item;
  Kind.set id Kind.Item;
  em

let spawn_corpse ~pos (em : t) =
  let id, em =
    create_base ~name:"Corpse" ~glyph:'%' ~pos
      ~description:(Some "A dead creature") ~blocking:false em
  in
  Kind.set id Kind.Corpse;
  em
