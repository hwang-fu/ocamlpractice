(* Norvig's classic examples: the first yields to propagation alone, the
   second forces guessing. *)
let easy =
  "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
;;

let hard =
  "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
;;

let parse_exn s =
  match Sudoku.parse s with
  | Ok g -> g
  | Error e -> failwith e
;;

(* A valid solution has each digit exactly once per row, column and box,
   and keeps every given of the original puzzle. *)
let assert_valid_solution givens solution =
  let unit_ok cells =
    List.sort compare (List.map (fun c -> solution.(c)) cells)
    = [ 1; 2; 3; 4; 5; 6; 7; 8; 9 ]
  in
  for i = 0 to 8 do
    assert (unit_ok (List.init 9 (fun j -> (i * 9) + j)));
    assert (unit_ok (List.init 9 (fun j -> (j * 9) + i)));
    let r0 = i / 3 * 3
    and c0 = i mod 3 * 3 in
    assert (unit_ok (List.init 9 (fun j -> ((r0 + (j / 3)) * 9) + c0 + (j mod 3))))
  done;
  Array.iteri (fun c d -> if d <> 0 then assert (solution.(c) = d)) givens
;;

let has_guess trace =
  List.exists
    (function
      | Sudoku.Guess _ -> true
      | _ -> false)
    trace
;;

let () =
  (* parsing *)
  assert (Sudoku.parse "123" = Error "expected 81 characters, got 3");
  (match Sudoku.parse (String.make 80 '.' ^ "x") with
   | Error _ -> ()
   | Ok _ -> assert false);
  (* round trip on the dot-style spelling; '0' empties parse but print as '.' *)
  assert (Sudoku.to_string (parse_exn hard) = hard);
  (* the easy puzzle dissolves under propagation alone: no guesses *)
  let givens = parse_exn easy in
  (match Sudoku.solve givens with
   | trace, Some solution ->
     assert_valid_solution givens solution;
     assert (not (has_guess trace))
   | _, None -> assert false);
  (* the hard puzzle needs search *)
  let givens = parse_exn hard in
  (match Sudoku.solve givens with
   | trace, Some solution ->
     assert_valid_solution givens solution;
     assert (has_guess trace)
   | _, None -> assert false);
  (* an empty grid is solvable (many solutions; any valid one is fine) *)
  let empty = parse_exn (String.make 81 '.') in
  (match Sudoku.solve empty with
   | _, Some solution -> assert_valid_solution empty solution
   | _, None -> assert false);
  (* contradictory givens: two 5s in one row *)
  let bad = parse_exn ("55" ^ String.make 79 '.') in
  (match Sudoku.solve bad with
   | trace, None ->
     assert (
       List.exists
         (function
           | Sudoku.Contradiction _ -> true
           | _ -> false)
         trace)
   | _, Some _ -> assert false);
  print_endline "all tests passed"
;;
