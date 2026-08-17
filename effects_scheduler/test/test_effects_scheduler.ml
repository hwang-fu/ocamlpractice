(* The tests record who ran when into a buffer, then assert the exact
   interleaving order. *)

let () =
  (* two yielding tasks alternate in lockstep *)
  let log = Buffer.create 64 in
  let say fmt = Printf.ksprintf (Buffer.add_string log) fmt in
  Effects_scheduler.run (fun () ->
    Effects_scheduler.spawn (fun () ->
      for i = 1 to 3 do
        say "A%d " i;
        Effects_scheduler.yield ()
      done);
    Effects_scheduler.spawn (fun () ->
      for i = 1 to 3 do
        say "B%d " i;
        Effects_scheduler.yield ()
      done));
  assert (Buffer.contents log = "A1 B1 A2 B2 A3 B3 ");
  (* a task that never yields runs to completion in one stretch *)
  Buffer.clear log;
  Effects_scheduler.run (fun () ->
    Effects_scheduler.spawn (fun () ->
      say "C1 ";
      say "C2 ");
    Effects_scheduler.spawn (fun () -> say "D1 "));
  assert (Buffer.contents log = "C1 C2 D1 ");
  (* yield with an empty queue is a harmless no-op *)
  Effects_scheduler.run (fun () -> Effects_scheduler.yield ());
  print_endline "all tests passed"
;;
