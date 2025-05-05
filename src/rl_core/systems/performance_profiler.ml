open Base

module ComponentCounter = struct
  type t = {
    mutable position_lookups : int;
    mutable stats_lookups : int;
    mutable blocking_lookups : int;
    mutable renderable_lookups : int;
    mutable lookup_time_ms : float;
    mutable last_report_time : float;
  }

  let counter =
    {
      position_lookups = 0;
      stats_lookups = 0;
      blocking_lookups = 0;
      renderable_lookups = 0;
      lookup_time_ms = 0.0;
      last_report_time = Unix.gettimeofday ();
    }

  let record_position_lookup time_ms =
    counter.position_lookups <- counter.position_lookups + 1;
    counter.lookup_time_ms <- counter.lookup_time_ms +. time_ms

  let record_stats_lookup time_ms =
    counter.stats_lookups <- counter.stats_lookups + 1;
    counter.lookup_time_ms <- counter.lookup_time_ms +. time_ms

  let record_blocking_lookup time_ms =
    counter.blocking_lookups <- counter.blocking_lookups + 1;
    counter.lookup_time_ms <- counter.lookup_time_ms +. time_ms

  let record_renderable_lookup time_ms =
    counter.renderable_lookups <- counter.renderable_lookups + 1;
    counter.lookup_time_ms <- counter.lookup_time_ms +. time_ms

  let report_and_reset () =
    let now = Unix.gettimeofday () in
    let elapsed = now -. counter.last_report_time in

    if Float.compare elapsed 5.0 >= 0 && counter.position_lookups > 0 then (
      Core_log.info (fun m -> m "Performance Report (%.1fs elapsed):" elapsed);
      Core_log.info (fun m ->
          m "  Position lookups: %d (%.2f per second)" counter.position_lookups
            (Float.of_int counter.position_lookups /. elapsed));
      Core_log.info (fun m ->
          m "  Stats lookups: %d (%.2f per second)" counter.stats_lookups
            (Float.of_int counter.stats_lookups /. elapsed));
      Core_log.info (fun m ->
          m "  Blocking lookups: %d (%.2f per second)" counter.blocking_lookups
            (Float.of_int counter.blocking_lookups /. elapsed));
      Core_log.info (fun m ->
          m "  Renderable lookups: %d (%.2f per second)"
            counter.renderable_lookups
            (Float.of_int counter.renderable_lookups /. elapsed));
      Core_log.info (fun m ->
          m "  Total lookup time: %.2f ms (avg %.4f ms per lookup)"
            counter.lookup_time_ms
            (counter.lookup_time_ms
            /. Float.of_int
                 (counter.position_lookups + counter.stats_lookups
                + counter.blocking_lookups + counter.renderable_lookups)));

      (* Reset counters *)
      counter.position_lookups <- 0;
      counter.stats_lookups <- 0;
      counter.blocking_lookups <- 0;
      counter.renderable_lookups <- 0;
      counter.lookup_time_ms <- 0.0;
      counter.last_report_time <- now)
end

(* Create timing wrappers for component access *)
let time_component_lookup component_name f =
  let start_time = Unix.gettimeofday () in
  let result = f () in
  let end_time = Unix.gettimeofday () in
  let elapsed_ms = (end_time -. start_time) *. 1000.0 in

  (* Record timing based on component type *)
  (match component_name with
  | "Position" -> ComponentCounter.record_position_lookup elapsed_ms
  | "Stats" -> ComponentCounter.record_stats_lookup elapsed_ms
  | "Blocking" -> ComponentCounter.record_blocking_lookup elapsed_ms
  | "Renderable" -> ComponentCounter.record_renderable_lookup elapsed_ms
  | _ -> ());

  result

(* Run the performance report *)
let generate_report () = ComponentCounter.report_and_reset ()

(* Initialize component timing wrappers *)
let init () =
  (* We'll hook into the components in a minimally invasive way *)
  Core_log.info (fun m -> m "Initializing performance profiler...")
