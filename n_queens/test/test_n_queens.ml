let () =
  let expected = [ 1, 1; 2, 0; 3, 0; 4, 2; 5, 10; 6, 4; 7, 40; 8, 92 ] in
  List.iter (fun (n, k) -> assert (N_queens.count n = k)) expected;
  print_endline "all tests passed"
;;
