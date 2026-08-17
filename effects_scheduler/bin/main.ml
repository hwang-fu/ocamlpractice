(* Demos: watch tasks interleave, then compose results with promises. *)

let () =
  print_endline "-- spawn and yield --";
  Effects_scheduler.run (fun () ->
    Effects_scheduler.spawn (fun () ->
      for i = 1 to 3 do
        Printf.printf "task A, step %d\n" i;
        Effects_scheduler.yield ()
      done);
    Effects_scheduler.spawn (fun () ->
      for i = 1 to 3 do
        Printf.printf "task B, step %d\n" i;
        Effects_scheduler.yield ()
      done));
  print_endline "-- async and await --";
  Effects_scheduler.run (fun () ->
    let sum =
      Effects_scheduler.async (fun () ->
        let total = ref 0 in
        for i = 1 to 5 do
          total := !total + i;
          Printf.printf "summing:      %d\n" !total;
          Effects_scheduler.yield ()
        done;
        !total)
    in
    let product =
      Effects_scheduler.async (fun () ->
        let total = ref 1 in
        for i = 1 to 5 do
          total := !total * i;
          Printf.printf "multiplying:  %d\n" !total;
          Effects_scheduler.yield ()
        done;
        !total)
    in
    Printf.printf
      "sum = %d, product = %d\n"
      (Effects_scheduler.await sum)
      (Effects_scheduler.await product))
;;
