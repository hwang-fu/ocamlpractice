(* Closed knight's tour search; presentation lives in bin/. *)

type square = int * int

(* The eight jump offsets; their order is the fixed try/tie order. *)
let offsets = [ 1, 2; 2, 1; 2, -1; 1, -2; -1, -2; -2, -1; -2, 1; -1, 2 ]

(* unvisited squares a knight's move away from (x, y) *)
let moves_from n visited (x, y) =
  List.filter_map
    (fun (dx, dy) ->
       let x' = x + dx
       and y' = y + dy in
       if x' >= 0 && x' < n && y' >= 0 && y' < n && not visited.(x').(y')
       then Some (x', y')
       else None)
    offsets
;;

let closes (x, y) = List.exists (fun (dx, dy) -> x + dx = 0 && y + dy = 0) offsets

(* Exhaustive depth-first search, undoing [visited] in place on backtrack.
   [reorder] arranges the candidate moves and receives the current onward
   count: the identity gives the naive fixed-order search, sorting by
   onward count gives the deterministic Warnsdorff-ordered search. *)
let dfs ~reorder n =
  let visited = Array.make_matrix n n false in
  let moves s = moves_from n visited s in
  let onward_count c = List.length (moves c) in
  let rec go s remaining acc =
    if remaining = 0
    then if closes s then Some (List.rev acc) else None
    else try_candidates (reorder ~onward_count (moves s)) remaining acc
  and try_candidates cs remaining acc =
    match cs with
    | [] -> None
    | ((x, y) as c) :: rest ->
      visited.(x).(y) <- true;
      (match go c (remaining - 1) (c :: acc) with
       | Some _ as found -> found
       | None ->
         visited.(x).(y) <- false;
         try_candidates rest remaining acc)
  in
  visited.(0).(0) <- true;
  go (0, 0) ((n * n) - 1) [ 0, 0 ]
;;

let naive_order ~onward_count:_ cs = cs

let warnsdorff_order ~onward_count cs =
  cs
  |> List.map (fun c -> onward_count c, c)
  |> List.stable_sort (fun (a, _) (b, _) -> compare a b)
  |> List.map snd
;;

let shuffle a =
  for i = Array.length a - 1 downto 1 do
    let j = Random.int (i + 1) in
    let t = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- t
  done
;;

(* One pure greedy Warnsdorff descent, ties broken at random, no
   backtracking: from each square jump to the unvisited neighbor with the
   smallest onward count. Succeeds only if the path covers the board and
   closes; failures are cheap, so the caller just retries. *)
let greedy_attempt n =
  let visited = Array.make_matrix n n false in
  let moves s = moves_from n visited s in
  let onward_count c = List.length (moves c) in
  let best_move s =
    let cs = Array.of_list (moves s) in
    shuffle cs;
    Array.fold_left
      (fun best c ->
         match best with
         | Some (k, _) when k <= onward_count c -> best
         | _ -> Some (onward_count c, c))
      None
      cs
  in
  let rec descend s remaining acc =
    if remaining = 0
    then if closes s then Some (List.rev acc) else None
    else (
      match best_move s with
      | None -> None
      | Some (_, ((x, y) as c)) ->
        visited.(x).(y) <- true;
        descend c (remaining - 1) (c :: acc))
  in
  visited.(0).(0) <- true;
  descend (0, 0) ((n * n) - 1) [ 0, 0 ]
;;

let rec retry_greedy n =
  match greedy_attempt n with
  | Some tour -> tour
  | None -> retry_greedy n
;;

let closed_tour ?(warnsdorff = true) n =
  if n < 1 then invalid_arg "closed_tour: the board size must be positive";
  (* no closed tour on odd boards (parity) or below 6x6: a theorem, so no
     search is needed to answer [None] *)
  if n < 6 || n mod 2 = 1
  then None
  else if not warnsdorff
  then dfs ~reorder:naive_order n
  else if n = 6
  then
    (* the greedy descent almost never closes on the smallest board, while
       the ordered exhaustive search finds a tour immediately there *)
    dfs ~reorder:warnsdorff_order n
  else Some (retry_greedy n)
;;
