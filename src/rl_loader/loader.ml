open Base
open Stdio

(* Find the project root by locating a dune-project file in the directory or its ancestors *)
let rec find_project_root (dir : string) : string =
  let candidate = Stdlib.Filename.concat dir "dune-project" in
  if Stdlib.Sys.file_exists candidate then dir
  else
    let parent = Stdlib.Filename.dirname dir in
    if String.equal parent dir then dir else find_project_root parent

(* Determine project root: use PROJECT_ROOT env or autodetect *)
let project_root () : string =
  match Stdlib.Sys.getenv_opt "PROJECT_ROOT" with
  | Some p -> p
  | None -> find_project_root (Stdlib.Sys.getcwd ())

(* Mapping table: (x, y) in tileset -> type string *)
type tile_mapping = (int * int, string) Hashtbl.Poly.t

(* Load mapping CSV: each non-empty line 'x,y,type' *)
let load_tile_mapping (filename : string) : tile_mapping =
  let root = project_root () in
  let full_path = Stdlib.Filename.concat root filename in
  let mapping = Hashtbl.Poly.create () in
  In_channel.with_file full_path ~f:(fun ic ->
      In_channel.iter_lines ic ~f:(fun line ->
          let line = String.strip line in
          if not (String.is_empty line) then
            match String.split line ~on:',' with
            | [ x_str; y_str; typ ] -> (
                match (Int.of_string x_str, Int.of_string y_str) with
                | x, y ->
                    Hashtbl.set mapping ~key:(x, y) ~data:(String.strip typ)
                | exception _ ->
                    eprintf "[loader] Invalid coords in %s: %s\n" full_path line
                )
            | _ ->
                eprintf "[loader] Skipping malformed line in %s: %s\n" full_path
                  line));
  mapping

(* Convert a gid to (x, y) in the tileset, given its width *)
let gid_to_xy ~(tileset_width : int) (gid : int) : int * int =
  let x = Int.rem gid tileset_width in
  let y = gid / tileset_width in
  (x, y)

(* Lookup the type string for a gid using the mapping table *)
let type_of_gid ~(mapping : tile_mapping) ~(tileset_width : int) (gid : int) :
    string option =
  let xy = gid_to_xy ~tileset_width gid in
  Hashtbl.find mapping xy

(* Example usage: *)
(*
let () =
  let mapping = load_tile_mapping "resources/mapping.csv" in
  let tileset_width = 8 in
  let gid = 3 in
  match type_of_gid ~mapping ~tileset_width gid with
  | Some typ -> printf "gid %d is type: %s\n" gid typ
  | None -> printf "gid %d is unknown\n" gid
*)
