let close x y = Float.abs (x -. y) < 1e-9

let () =
  (* theta = 0: the curve starts at (a, 0) *)
  let x, y = Cardioid.point 50. 0. in
  assert (close x 50.);
  assert (close y 0.);
  (* theta = pi/2: the cusp, at the origin whatever [a] is *)
  let x, y = Cardioid.point 50. (Float.pi /. 2.) in
  assert (close x 0.);
  assert (close y 0.);
  (* theta = -pi/2: the bottom of the heart, (0, -2a) *)
  let x, y = Cardioid.point 50. (-.Float.pi /. 2.) in
  assert (close x 0.);
  assert (close y (-100.));
  print_endline "all tests passed"
;;
