(* monster_placement.ml
   Logic for placing monsters (single and bands) in the dungeon after map generation.
   Integrates with the mapgen pipeline and uses species-to-faction mapping.
*)

open Base
open Types
open Util
open Entities

(* Represents a monster to be placed *)
type monster_spec = {
  species : string;
  health : int;
  glyph : string;
  name : string;
  description : string;
}

(* Place a band (group) of monsters in a list of locations *)
let place_monster_band ~entity_manager ~positions ~direction
    (specs : monster_spec list) : Entity_manager.t =
  List.zip_exn positions specs
  |> List.fold_left ~init:entity_manager ~f:(fun mgr (pos, spec) ->
         let faction = faction_of_species spec.species in
         Spawner.spawn_creature ~pos ~direction ~species:spec.species
           ~health:spec.health ~glyph:spec.glyph ~name:spec.name
           ~description:(Some spec.description) ~faction mgr)

(* Monster templates by species *)
let monster_templates =
  [
    ( "Rat",
      {
        species = "Rat";
        health = 10;
        glyph = "r";
        name = "Rat";
        description = "A small, brown rodent.";
      } );
    ( "Kobold",
      {
        species = "Kobold";
        health = 16;
        glyph = "k";
        name = "Kobold";
        description = "A sneaky kobold.";
      } );
    ( "Goblin",
      {
        species = "Goblin";
        health = 20;
        glyph = "g";
        name = "Goblin";
        description = "A mean goblin.";
      } );
    ( "Goblin Shaman",
      {
        species = "Goblin Shaman";
        health = 14;
        glyph = "G";
        name = "Goblin Shaman";
        description = "A goblin shaman with magic.";
      } );
    ( "Ore Slime",
      {
        species = "Ore Slime";
        health = 18;
        glyph = "s";
        name = "Ore Slime";
        description = "A metallic slime.";
      } );
    ( "Undead Miner",
      {
        species = "Undead Miner";
        health = 22;
        glyph = "u";
        name = "Undead Miner";
        description = "A miner, now undead.";
      } );
    ( "Rock Golem",
      {
        species = "Rock Golem";
        health = 40;
        glyph = "R";
        name = "Rock Golem";
        description = "A hulking golem of stone.";
      } );
    ( "Giant Spider",
      {
        species = "Giant Spider";
        health = 15;
        glyph = "S";
        name = "Giant Spider";
        description = "A huge, venomous spider.";
      } );
    ( "Shadow Creeper",
      {
        species = "Shadow Creeper";
        health = 18;
        glyph = "C";
        name = "Shadow Creeper";
        description = "A fast, shadowy creature.";
      } );
  ]

let get_template species =
  List.Assoc.find ~equal:String.equal monster_templates species
  |> Option.value_exn ~message:("No template for species: " ^ species)

(* Monster bands by depth: returns a list of (species * count) *)
let bands_by_depth depth =
  match depth with
  | 1 -> [ [ ("Rat", 2) ]; [ ("Kobold", 1) ]; [ ("Rat", 1); ("Kobold", 1) ] ]
  | 2 ->
      [
        [ ("Kobold", 2) ];
        [ ("Goblin", 1); ("Goblin Shaman", 1) ];
        [ ("Ore Slime", 2) ];
      ]
  | 3 ->
      [
        [ ("Goblin", 2); ("Goblin Shaman", 1) ];
        [ ("Undead Miner", 2) ];
        [ ("Ore Slime", 1); ("Giant Spider", 1) ];
      ]
  | 4 ->
      [
        [ ("Rock Golem", 1); ("Goblin", 1) ];
        [ ("Shadow Creeper", 2) ];
        [ ("Undead Miner", 1); ("Giant Spider", 1) ];
      ]
  | _ ->
      [ [ ("Rock Golem", 2) ]; [ ("Shadow Creeper", 2); ("Goblin Shaman", 1) ] ]

(* Select a random band composition for a room, based on depth *)
let random_band_for_room ~depth ~rng =
  let bands = bands_by_depth depth in
  random_choice bands ~rng

(* Expand a band spec [(species, count); ...] to a list of monster_specs *)
let expand_band band =
  List.concat_map band ~f:(fun (species, count) ->
      let template = get_template species in
      List.init count ~f:(fun _ -> template))

(* Place a band of monsters in a room, with mixed species support *)
let place_band_in_room ~entity_manager ~room_positions ~depth ~rng =
  match random_band_for_room ~depth ~rng with
  | Some band_spec ->
      let band = expand_band band_spec in
      let positions = List.take room_positions (List.length band) in
      place_monster_band ~entity_manager ~positions ~direction:Direction.North
        band
  | None ->
      Core_log.err (fun m ->
          m "No band spec could be selected for depth %d" depth);
      entity_manager

(* Place a single monster at a given location *)
let place_monster ~entity_manager ~pos ~direction (spec : monster_spec) :
    Entity_manager.t =
  let faction = faction_of_species spec.species in
  Spawner.spawn_creature ~pos ~direction ~species:spec.species
    ~health:spec.health ~glyph:spec.glyph ~name:spec.name
    ~description:(Some spec.description) ~faction entity_manager

(* Utility: Generate a list of monster specs for a band *)
let make_band ~species ~count ~health ~glyph ~name ~description =
  List.init count ~f:(fun _ -> { species; health; glyph; name; description })

(* Example: Place a band of rats in a room *)
let place_rat_band_in_room ~entity_manager ~room_positions =
  let band =
    make_band ~species:"Rat"
      ~count:(List.length room_positions)
      ~health:10 ~glyph:"r" ~name:"Rat" ~description:"A small, brown rodent."
  in
  place_monster_band ~entity_manager ~positions:room_positions
    ~direction:Direction.North band

(* TODO: Add logic for depth-based species selection, mixed bands, and faction-aware placement. *)
