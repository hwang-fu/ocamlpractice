let () =
  (* members of the set: the sequence never escapes *)
  assert (Mandelbrot.in_set 0. 0.);
  assert (Mandelbrot.in_set (-1.) 0.);
  assert (Mandelbrot.in_set (-2.) 0.);
  assert (Mandelbrot.in_set 0.25 0.);
  (* (1, 0) escapes at step 3: 0 -> 1 -> 2 -> 5 *)
  assert (Mandelbrot.escape 1. 0. = Some 3);
  (* far outside: escape on the first step *)
  assert (Mandelbrot.escape 3. 0. = Some 1);
  (* members stay members when k grows *)
  assert (Mandelbrot.in_set ~k:1000 (-1.) 0.);
  print_endline "all tests passed"
;;
