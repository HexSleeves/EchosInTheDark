open Base

(* Difficulty parameters for a given level *)
type difficulty_params = { monsters : int; traps : int }
type render_mode = Tiles | Ascii

(* Map generation configuration *)
type t = {
  seed : int;
  min_levels : int;
  max_levels : int;
  width : int;
  height : int;
  difficulty_curve : depth:int -> difficulty_params;
  render_mode : render_mode;
}

let default ~seed ?(render_mode = Tiles) () =
  let min_levels = 3 in
  let max_levels = 5 in
  let width = 80 in
  let height = 25 in
  let difficulty_curve ~depth = { monsters = depth * 2; traps = depth } in
  { seed; min_levels; max_levels; width; height; difficulty_curve; render_mode }

let make ~seed ~w ~h ?(render_mode = Tiles) () =
  let min_levels = 3 in
  let max_levels = 5 in
  let difficulty_curve ~depth = { monsters = depth * 2; traps = depth } in
  {
    seed;
    min_levels;
    max_levels;
    difficulty_curve;
    width = w;
    height = h;
    render_mode;
  }

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

(* Monster templates by species *)

(* Represents a monster to be placed *)
type monster_spec = {
  health : int;
  glyph : char;
  name : string;
  description : string;
  species : Components.Species.t;
}

let monster_templates =
  [
    ( "Rat",
      {
        species = `Rat;
        health = 10;
        glyph = 'r';
        name = "Rat";
        description = "A small, brown rodent.";
      } );
    ( "Kobold",
      {
        species = `Kobold;
        health = 16;
        glyph = 'k';
        name = "Kobold";
        description = "A sneaky kobold.";
      } );
    ( "Goblin",
      {
        species = `Goblin;
        health = 20;
        glyph = 'g';
        name = "Goblin";
        description = "A mean goblin.";
      } );
    ( "Goblin Shaman",
      {
        species = `Goblin_Shaman;
        health = 14;
        glyph = 'G';
        name = "Goblin Shaman";
        description = "A goblin shaman with magic.";
      } );
    ( "Ore Slime",
      {
        species = `Ore_Slime;
        health = 18;
        glyph = 's';
        name = "Ore Slime";
        description = "A metallic slime.";
      } );
    (* ( "Undead Miner",
            {
              species = `Undead_Miner;
              health = 22;
              glyph = 'u';
              name = "Undead Miner";
              description = "A miner, now undead.";
            } );
          ( "Rock Golem",
            {
              species = `Rock_Golem;
              health = 40;
              glyph = 'R';
              name = "Rock Golem";
              description = "A hulking golem of stone.";
            } ); *)
    (* ( "Giant Spider",
            {
              species = `Giant_Spider;
              health = 15;
              glyph = 'S';
              name = "Giant Spider";
              description = "A huge, venomous spider.";
            } ); *)
    (* ( "Shadow Creeper",
            {
              species = `Shadow_Creeper;
              health = 18;
              glyph = 'C';
              name = "Shadow Creeper";
              description = "A fast, shadowy creature.";
            } ); *)
  ]
