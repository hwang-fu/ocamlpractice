(* Execution-time measurement utilities. *)

let cpu_time () = (Unix.times ()).Unix.tms_utime

let time f =
  let start = cpu_time () in
  f ();
  let stop = cpu_time () in
  stop -. start
;;
