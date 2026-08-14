let close (x1, y1) (x2, y2) = Float.abs (x1 -. x2) < 1e-9 && Float.abs (y1 -. y2) < 1e-9

let () =
  let a = 0., 0.
  and b = 9., 0. in
  (* depth 0 is just the segment *)
  assert (Koch_snowflake.koch 0 a b = [ a; b ]);
  (* depth 1 on a horizontal segment: the five classic points, with the bump
     to the left of travel (positive y) *)
  (match Koch_snowflake.koch 1 a b with
   | [ p1; p2; p3; p4; p5 ] ->
     assert (close p1 (0., 0.));
     assert (close p2 (3., 0.));
     assert (close p3 (4.5, 1.5 *. sqrt 3.));
     assert (close p4 (6., 0.));
     assert (close p5 (9., 0.))
   | _ -> assert false);
  (* depth n has 4^n + 1 points and preserves both endpoints *)
  let pow4 n = 1 lsl (2 * n) in
  List.iter
    (fun n ->
       let pts = Koch_snowflake.koch n a b in
       assert (List.length pts = pow4 n + 1);
       assert (close (List.hd pts) a);
       assert (close (List.nth pts (pow4 n)) b))
    [ 1; 2; 3; 4; 5 ];
  print_endline "all tests passed"
;;
