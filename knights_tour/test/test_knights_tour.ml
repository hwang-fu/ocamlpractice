let is_knight_move (x1, y1) (x2, y2) =
  let dx = abs (x1 - x2)
  and dy = abs (y1 - y2) in
  (dx = 1 && dy = 2) || (dx = 2 && dy = 1)
;;

(* A closed tour must: have n^2 squares, start at (0, 0), stay on the
   board, repeat no square, chain by knight moves, and close the loop. *)
let assert_valid_closed n tour =
  assert (List.length tour = n * n);
  assert (List.hd tour = (0, 0));
  assert (List.for_all (fun (x, y) -> x >= 0 && x < n && y >= 0 && y < n) tour);
  assert (List.length (List.sort_uniq compare tour) = n * n);
  let rec chained = function
    | a :: (b :: _ as rest) -> is_knight_move a b && chained rest
    | _ -> true
  in
  assert (chained tour);
  let last = List.nth tour ((n * n) - 1) in
  assert (is_knight_move last (0, 0))
;;

let check n =
  match Knights_tour.closed_tour n with
  | None -> assert false
  | Some tour -> assert_valid_closed n tour
;;

let () =
  (* deterministic randomized search for reproducible test runs *)
  Random.init 42;
  (* mathematics says no: boards below 6 and odd boards, in either mode *)
  List.iter
    (fun n ->
       assert (Knights_tour.closed_tour n = None);
       assert (Knights_tour.closed_tour ~warnsdorff:false n = None))
    [ 1; 2; 3; 4; 5; 7; 9 ];
  (* the warnsdorff search finds closed tours across even sizes *)
  List.iter check [ 6; 8; 10; 12; 14; 16 ];
  print_endline "all tests passed"
;;
