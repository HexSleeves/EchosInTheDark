open Types
open Entity_manager

type t = Entity_manager.t

let create_base ~name ~glyph ~pos ~description ?(blocking = true) (em : t) =
  let id, em = Entity_manager.spawn em in

  (* Here we set all the components *)
  Components.Position.set id pos;
  Components.Name.set id { name };
  Components.Renderable.set id { glyph };
  Components.Blocking.set id blocking;

  (match description with
  | Some desc -> Components.Description.set id desc
  | None -> ());

  (id, em)

let spawn_player ~pos (em : t) =
  let id, em =
    create_base ~name:"Player" ~glyph:'@' ~pos
      ~description:(Some "This is you!") em
  in

  Components.Stats.default id;
  Components.Inventory.set id { items = []; max_slots = 20 };
  Components.Equipment.default id;
  Components.Kind.set id Components.Kind.Player;
  (em, id)

let spawn_creature ~pos ~species ~health ~glyph ~name ~description ~faction
    (em : t) =
  let id, em = create_base ~name ~glyph ~pos ~description em in

  Components.Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5
    ~speed:100
  |> Components.Stats.set id;

  (* Set species, faction, etc. as components if you have them *)
  Components.Kind.set id Components.Kind.Creature;
  (em, id)

let spawn_item ~pos ~item_type ~quantity ~name ~glyph ?(description = None)
    (em : t) =
  let id, em = create_base ~name ~glyph ~pos ~description ~blocking:false em in
  let item = Item.create ~item_type ~quantity ~name ~description () in
  Components.Item_data.set id item;
  Components.Kind.set id Components.Kind.Item;
  (em, id)

let spawn_corpse ~pos (em : t) =
  let id, em =
    create_base ~name:"Corpse" ~glyph:'%' ~pos
      ~description:(Some "A dead creature") ~blocking:false em
  in
  Components.Kind.set id Components.Kind.Corpse;
  (em, id)
