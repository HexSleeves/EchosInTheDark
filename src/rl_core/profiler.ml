open Base

(* Simple profiler based on Unix.gettimeofday *)
module SimpleProfiler = struct
  type timing = {
    name : string;
    start_time : float;
    mutable end_time : float option;
    mutable duration : float option;
  }

  type t = { mutable timings : timing list }

  let create () = { timings = [] }

  let start profiler name =
    let timing =
      {
        name;
        start_time = Unix.gettimeofday ();
        end_time = None;
        duration = None;
      }
    in
    profiler.timings <- timing :: profiler.timings;
    timing

  let stop timing =
    let end_time = Unix.gettimeofday () in
    timing.end_time <- Some end_time;
    timing.duration <- Some (end_time -. timing.start_time);
    Option.value_exn timing.duration

  let measure_fn profiler name f =
    let timing = start profiler name in
    let result = f () in
    let _ = stop timing in
    result

  let print_results profiler =
    let sorted_timings =
      List.sort profiler.timings ~compare:(fun a b ->
          match (a.duration, b.duration) with
          | Some a_dur, Some b_dur -> Float.compare b_dur a_dur (* descending *)
          | Some _, None -> -1
          | None, Some _ -> 1
          | None, None -> String.compare a.name b.name)
    in
    Logs.info (fun m -> m "\n===== Profiling Results =====\n");
    List.iter sorted_timings ~f:(fun t ->
        match t.duration with
        | Some duration ->
            Logs.info (fun m -> m "%s: %.6f ms\n" t.name (duration *. 1000.0))
        | None -> Logs.info (fun m -> m "%s: incomplete\n" t.name));
    Logs.info (fun m -> m "============================\n\n")
end

(* Global profiler instance *)
let profiler = SimpleProfiler.create ()

(* Component access profiling *)
let measure_component_access name f = SimpleProfiler.measure_fn profiler name f

(* Profile component access patterns *)
let profile_component_access () =
  (* Clear previous timings *)
  profiler.timings <- [];

  (* Profile hashtable-based component access *)
  let _ =
    SimpleProfiler.measure_fn profiler "Position.get (1000 times)" (fun () ->
        for i = 0 to 1000 do
          let _ = Components.Position.get i in
          ()
        done)
  in

  let _ =
    SimpleProfiler.measure_fn profiler "Stats.get (1000 times)" (fun () ->
        for i = 0 to 1000 do
          let _ = Components.Stats.get i in
          ()
        done)
  in

  (* Profile packed-array component access *)
  let _ =
    SimpleProfiler.measure_fn profiler
      "PackedComponents.get_position (1000 times)" (fun () ->
        for i = 0 to 1000 do
          let _ =
            Packed_components.get_position
              !Systems.Packed_system.packed_components
              i
          in
          ()
        done)
  in

  let _ =
    SimpleProfiler.measure_fn profiler "PackedComponents.get_stats (1000 times)"
      (fun () ->
        for i = 0 to 1000 do
          let _ =
            Packed_components.get_stats
              !Systems.Packed_system.packed_components
              i
          in
          ()
        done)
  in

  (* Print results *)
  SimpleProfiler.print_results profiler

(* Profile batch operations *)
let profile_batch_operations () =
  (* Clear previous timings *)
  profiler.timings <- [];

  (* Profile individual operations vs batch operations *)
  let entity_count = 1000 in
  let entity_ids = List.init entity_count ~f:Fn.id in

  (* Individual access *)
  let _ =
    SimpleProfiler.measure_fn profiler "Individual entity position access"
      (fun () ->
        List.iter entity_ids ~f:(fun id ->
            let _ = Components.Position.get id in
            ()))
  in

  (* Batch access *)
  let _ =
    SimpleProfiler.measure_fn profiler "Batch entity position access" (fun () ->
        let _ =
          Packed_components.Position.get_batch
            !Systems.Packed_system.packed_components.positions
            (Array.of_list entity_ids)
        in
        ())
  in

  (* Print results *)
  SimpleProfiler.print_results profiler

(* Utility function to run a basic profiling session *)
let run_profiling () =
  Stdio.printf "Running component access profiling...\n";
  profile_component_access ();

  Stdio.printf "Running batch operation profiling...\n";
  profile_batch_operations ()
