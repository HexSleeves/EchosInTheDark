open Components

let create_base ~name ~glyph ~pos ~description ?(blocking = true) em =
  let position = Position.make pos in
  let id, em = Entity_manager.spawn_entity em in

  (* Here we set all the components *)
  Position.set id position;
  Name.set id { name };
  Renderable.set id { glyph };
  Blocking.set id blocking;

  (match description with Some desc -> Description.set id desc | None -> ());

  (id, em)

let spawn_player ~pos em =
  Logs.info (fun m -> m "Spawning player");
  let id, em =
    create_base ~name:"Player" ~glyph:'@' ~pos
      ~description:(Some "This is you!") em
  in

  Stats.set id (Stats.create_default ());
  Inventory.set id { items = []; max_slots = 20 };
  Equipment.set id Equipment.empty;
  Kind.set id Kind.Player;
  Field_of_view.set id (Field_of_view.make ~radius:8);

  Entity_manager.register_player id em

let spawn_creature ~pos ~species ~health ~glyph ~name ~description ~faction em =
  let id, em = create_base ~name ~glyph ~pos ~description em in

  Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5 ~speed:100 ()
  |> Stats.set id |> ignore;

  (* Set species, faction, etc. as components if you have them *)
  Kind.set id Kind.Creature;
  Species.set id species;
  Faction.set id faction;

  (id, em)

let spawn_item ~pos ~item_type ~quantity ~name ~glyph ?(description = None) em =
  let id, em = create_base ~name ~glyph ~pos ~description em in
  let item = Item.Item_data.create ~item_type ~quantity ~name ~description () in
  Item.set id item;
  Kind.set id Kind.Item;

  (id, em)

let spawn_corpse ~pos em =
  let id, em =
    create_base ~name:"Corpse" ~glyph:'%' ~pos
      ~description:(Some "A dead creature") ~blocking:false em
  in
  Kind.set id Kind.Corpse;

  (id, em)
