open Base
open Rl2023
open Rl2023.Engine
open Components
open Utils
open Raylib

module MyGame = struct
  let systems : (module System) array = [||]
  let init_entities () = ()
end

let new_game () =
  Printf.sprintf "new game\n" |> Stdio.print_string;
  Entity.by_name "Player"
  |> Position.s { x = 32; y = 0 }
  |> Sprite.s (Sprite.load "assets/player.png")
  |> Health.s 100 |> Script.s can_die
  |> Input.s
       [|
         (Raylib.Key.Up, Commands.GoUp);
         (Raylib.Key.Down, Commands.GoDown);
         (Raylib.Key.Left, Commands.GoLeft);
         (Raylib.Key.Right, Commands.GoRight);
         (Raylib.Key.Space, Commands.Attack);
       |]
  |> ignore;

  new State.sharedstate "assets/font.png" 16 16 80 50

let play_game (ss : State.sharedstate) =
  let exit = ref false in

  let rec loop () =
    match !exit || Raylib.window_should_close () with
    | true -> Raylib.close_window ()
    | false ->
        (* let pressed_key = get_char_pressed () in *)
        begin_drawing ();
        clear_background Color.black;

        ss#render_layers;
        ss#draw_screen_texture;

        draw_fps 10 10;
        end_drawing ();
        loop ()
  in

  loop ()

module Game = Engine.MakeGame (MyGame)
