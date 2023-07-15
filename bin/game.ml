open Base
open Rl2023
open Rl2023.Engine
open Components
open Utils

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
  |> ignore

module Game = Engine.MakeGame (MyGame)
