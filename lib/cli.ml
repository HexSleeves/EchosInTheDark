type t = { fps : int; width : int; height : int }

let parse: t =
  (* You can write a small introduction for the --help. *)
  Clap.description "Rougelike Tutorial 2023";

  let width =
    Clap.default_int
      ~short: 'w'
      ~long: "width"
      ~description: "FPS for the game"
      800
  in

  let height =
    Clap.default_int
      ~short: 'h'
      ~long: "height"
      ~description: "FPS for the game"
      640
  in

  let fps =
    Clap.default_int
      ~long: "fps"
      ~description: "FPS for the game"
      30
  in

  Clap.close ();

  { width; height; fps}