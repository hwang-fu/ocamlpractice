let busy () =
  let s = ref 0 in
  for i = 1 to 300_000_000 do
    s := !s + i
  done;
  ignore (Sys.opaque_identity !s)
;;

let () =
  (* a trivial thunk sits below the clock's resolution *)
  assert (Timeit.time (fun () -> ()) < 0.05);
  (* a heavy loop consumes measurable CPU time *)
  assert (Timeit.time busy > 0.0);
  (* sleeping burns wall-clock time but (almost) no CPU time *)
  assert (Timeit.time (fun () -> Unix.sleepf 0.2) < 0.05);
  print_endline "all tests passed"
;;
