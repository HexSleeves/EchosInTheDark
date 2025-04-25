open Rl_loader

let () =
  let map_data = Loader.load_tile_mapping "resources/mapping.csv" in
  Logs.info (fun m -> m "Loaded map data");

  let () =
    Base.Hashtbl.iteri map_data ~f:(fun ~key ~data ->
        let x, y = key in
        Stdio.printf "Tile at %d, %d: %s\n" x y data)
  in
  ()
