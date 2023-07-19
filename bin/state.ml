open Base
open Common

module CtrlM = struct
  type openatlasprop = region_loc
  type t = Normal | OpenAtlas of openatlasprop * t | Died of float
end

type t = { debug : bool; random_seed : string; cm : CtrlM.t }

(* ~ game modes *)
type game_mode = MainMenu | Play of t | Exit

let make w h used_seed debug =
  let _ = (w, h, debug) in
  { debug = true; random_seed = used_seed; cm = CtrlM.Normal }

let init seed b_debug =
  let max_seed = 1000000000 in
  let hash_string s =
    Utils.fold_lim
      (fun a i -> ((a * 256) + Char.to_int s.[i]) % (max_seed / 512))
      0 0
      (String.length s - 1)
  in

  Random.init (hash_string seed);
  make 25 16 seed b_debug

let init_full opt_string b_debug =
  let seed =
    match opt_string with
    | Some s -> s
    | None ->
        let rnd_seed_string () =
          let len = 1 + Random.int 6 in
          let s =
            String.init len ~f:(fun _ ->
                Char.of_int_exn (Char.to_int 'a' + Random.int 26))
          in

          Stdlib.Printf.printf "Random seed: %s\n%!" s;

          s
        in

        rnd_seed_string ()
  in

  init seed b_debug
