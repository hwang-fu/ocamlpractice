let () =
  let expected = [ 1, 1; 2, 0; 3, 0; 4, 2; 5, 10; 6, 4; 7, 40; 8, 92 ] in
  List.iter (fun (n, k) -> assert (N_queens.count n = k)) expected;
  (* solutions must agree with count... *)
  List.iter (fun (n, k) -> assert (List.length (N_queens.solutions n) = k)) expected;
  (* ...and the two 4-queens boards are known exactly *)
  assert (N_queens.solutions 4 = [ [ 1; 3; 0; 2 ]; [ 2; 0; 3; 1 ] ]);
  print_endline "all tests passed"
;;
