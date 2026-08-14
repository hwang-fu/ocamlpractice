let () =
  (* in_circle: deterministic geometry *)
  assert (Approx_pi.in_circle 0.0 0.0);
  assert (Approx_pi.in_circle 0.5 0.5);
  assert (Approx_pi.in_circle 1.0 0.0);
  (* boundary point *)
  assert (not (Approx_pi.in_circle 0.8 0.8));
  (* approx_pi: reproducible statistical test thanks to a fixed seed *)
  Random.init 42;
  let pi = Approx_pi.approx_pi 1_000_000 in
  assert (Float.abs (pi -. Float.pi) < 0.01);
  print_endline "all tests passed"
;;
