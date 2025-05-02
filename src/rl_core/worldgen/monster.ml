(* monster_placement.ml
   Logic for placing monsters (single and bands) in the dungeon after map generation.
   Integrates with the worldgen pipeline and uses species-to-faction mapping.
*)

open Base
open Entities
open Config

(* Place a band (group) of monsters in a list of locations *)
let place_monster_band ~entity_manager ~positions (specs : monster_spec list) :
    Entity_manager.t =
  List.zip_exn positions specs
  |> List.fold_left ~init:entity_manager ~f:(fun mgr (pos, spec) ->
         let faction = Core_utils.Util.faction_of_species spec.species in
         Spawner.spawn_creature ~pos ~species:spec.species ~health:spec.health
           ~glyph:spec.glyph ~name:spec.name
           ~description:(Some spec.description) ~faction mgr)

let get_template species =
  List.Assoc.find ~equal:String.equal Config.monster_templates species
  |> Option.value_exn ~message:("No template for species: " ^ species)

(* Select a random band composition for a room, based on depth *)
let random_band_for_room ~depth ~rng =
  let bands = Config.bands_by_depth depth in
  Utils.Rng.random_choice bands ~rng

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
      place_monster_band ~entity_manager ~positions band
  | None ->
      Core_log.err (fun m ->
          m "No band spec could be selected for depth %d" depth);
      entity_manager

(* Place a single monster at a given location *)
let place_monster ~entity_manager ~pos (spec : monster_spec) : Entity_manager.t
    =
  let faction = Core_utils.Util.faction_of_species spec.species in
  Spawner.spawn_creature ~pos ~species:spec.species ~health:spec.health
    ~glyph:spec.glyph ~name:spec.name ~description:(Some spec.description)
    ~faction entity_manager

(* Utility: Generate a list of monster specs for a band *)
let make_band ~species ~count ~health ~glyph ~name ~description =
  List.init count ~f:(fun _ -> { species; health; glyph; name; description })

(* Example: Place a band of rats in a room *)
let place_rat_band_in_room ~entity_manager ~room_positions =
  let band =
    make_band ~species:`Rat
      ~count:(List.length room_positions)
      ~health:10 ~glyph:'r' ~name:"Rat" ~description:"A small, brown rodent."
  in
  place_monster_band ~entity_manager ~positions:room_positions band

(* TODO: Add logic for depth-based species selection, mixed bands, and faction-aware placement. *)
