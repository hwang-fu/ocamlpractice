(* Sudoku solver: constraint propagation + MRV search; drawing lives in
   bin/. Cells are 0..80 row-major; digits are 1..9, 0 meaning empty. *)

type unit_kind =
  | Row of int
  | Col of int
  | Box of int

type step =
  | Given of int * int
  | Naked of int * int
  | Hidden of int * int * unit_kind
  | Guess of int * int
  | Contradiction of int
  | Backtrack

let all_digits = [ 1; 2; 3; 4; 5; 6; 7; 8; 9 ]

(* Candidate sets are 9-bit masks: bit [d - 1] set means digit [d] is still
   possible. [full_mask] is the set of all nine digits, the state of an
   untouched cell. *)
let full_mask = 0b1_1111_1111

(* [bit d] is the mask with only digit [d]'s bit set: bit 3 = 0b100. *)
let bit d = 1 lsl (d - 1)

(* [has m d] tests whether digit [d]'s bit is set in mask [m]. *)
let has m d = m land bit d <> 0

(* [popcount m] counts the set bits of [m]: the size of the candidate set. *)
let popcount m =
  let rec go m acc = if m = 0 then acc else go (m lsr 1) (acc + (m land 1)) in
  go m 0
;;

(* [singleton_digit m] is the digit of a one-element mask (undefined
   otherwise): the digit to place when a naked single fires. *)
let singleton_digit m = List.find (has m) all_digits

(* [units_of c] is the three units cell [c] belongs to. *)
let units_of c =
  let r = c / 9
  and col = c mod 9 in
  [ Row r; Col col; Box ((r / 3 * 3) + (col / 3)) ]
;;

(* [cells_of u] is the nine cells of unit [u], row-major. *)
let cells_of = function
  | Row r -> List.init 9 (fun i -> (r * 9) + i)
  | Col c -> List.init 9 (fun i -> (i * 9) + c)
  | Box b ->
    let r0 = b / 3 * 3
    and c0 = b mod 3 * 3 in
    List.init 9 (fun i -> ((r0 + (i / 3)) * 9) + c0 + (i mod 3))
;;

(* the 27 units of the board: 9 rows, 9 columns, 9 boxes *)
let all_units =
  List.concat_map
    (fun k -> List.init 9 k)
    [ (fun i -> Row i); (fun i -> Col i); (fun i -> Box i) ]
;;

(* the 20 cells sharing a unit with [c] *)
let peers =
  Array.init 81 (fun c ->
    units_of c
    |> List.concat_map cells_of
    |> List.sort_uniq compare
    |> List.filter (fun c' -> c' <> c))
;;

(* Raised when a cell runs out of candidates: the current branch is dead. *)
exception Dead

(* The solving machinery reports its actions through an [emit] callback of
   type [step -> unit]: [solve] passes a trace appender, while the silent
   searches (solution counting, grid generation) pass [ignore]. *)

(* [place] reports [step], writes the digit, and erases it from all peers'
   candidate sets; a peer emptied by the erasure is a contradiction. *)
let place digits cands emit c d step =
  emit step;
  (* a digit eliminated from this very cell cannot be placed here: this
     catches contradictory givens the moment they arrive *)
  if not (has cands.(c) d)
  then (
    emit (Contradiction c);
    raise Dead);
  digits.(c) <- d;
  cands.(c) <- bit d;
  List.iter
    (fun p ->
       if digits.(p) = 0 && has cands.(p) d
       then (
         cands.(p) <- cands.(p) land lnot (bit d);
         if cands.(p) = 0
         then (
           emit (Contradiction p);
           raise Dead)))
    peers.(c)
;;

(* Run naked singles and hidden singles to the fixpoint. *)
let rec propagate digits cands emit =
  let fired = ref false in
  for c = 0 to 80 do
    if digits.(c) = 0 && popcount cands.(c) = 1
    then (
      let d = singleton_digit cands.(c) in
      place digits cands emit c d (Naked (c, d));
      fired := true)
  done;
  if not !fired
  then
    List.iter
      (fun u ->
         let cells = cells_of u in
         List.iter
           (fun d ->
              if not !fired
              then (
                match List.filter (fun c -> digits.(c) = 0 && has cands.(c) d) cells with
                | [ c ] when not (List.exists (fun c' -> digits.(c') = d) cells) ->
                  place digits cands emit c d (Hidden (c, d, u));
                  fired := true
                | _ -> ()))
           all_digits)
      all_units;
  if !fired then propagate digits cands emit
;;

(* [mrv digits cands] is the unresolved cell with the fewest candidates
   (minimum remaining values): the most promising place to guess, since a
   wrong guess there is refuted fastest. Assumes at least one empty cell. *)
let mrv digits cands =
  let best = ref (-1) in
  for c = 0 to 80 do
    if digits.(c) = 0 && (!best = -1 || popcount cands.(c) < popcount cands.(!best))
    then best := c
  done;
  !best
;;

(* [search ?order digits cands emit] propagates to the fixpoint, and if
   cells remain unresolved, guesses at the MRV cell and recurses on a copy
   of the state, so backtracking is simply returning to the caller's
   intact arrays. [order] arranges the candidate digits tried at each
   guess (identity for the deterministic solver, a shuffle for random grid
   generation). Returns the solved digits, or [None] if this branch is
   dead. *)
let rec search ?(order = fun l -> l) digits cands emit =
  match propagate digits cands emit with
  | exception Dead -> None
  | () ->
    if Array.for_all (fun d -> d <> 0) digits
    then Some digits
    else (
      let c = mrv digits cands in
      let rec try_digits = function
        | [] -> None
        | d :: rest ->
          let digits' = Array.copy digits
          and cands' = Array.copy cands in
          (match place digits' cands' emit c d (Guess (c, d)) with
           | exception Dead ->
             emit Backtrack;
             try_digits rest
           | () ->
             (match search ~order digits' cands' emit with
              | Some _ as solved -> solved
              | None ->
                emit Backtrack;
                try_digits rest))
      in
      try_digits (order (List.filter (has cands.(c)) all_digits)))
;;

(* [solve grid] places the givens (catching contradictory ones), runs the
   search, and returns the full reasoning trace either way. *)
let solve grid =
  let trace = ref [] in
  let emit s = trace := s :: !trace in
  let digits = Array.make 81 0
  and cands = Array.make 81 full_mask in
  match
    Array.iteri
      (fun c d -> if d <> 0 then place digits cands emit c d (Given (c, d)))
      grid
  with
  | exception Dead -> List.rev !trace, None
  | () -> List.rev !trace, search digits cands emit
;;

(* [count_search digits cands cap] counts the solutions reachable from
   this state, silently, giving up once [cap] is reached. Unlike [search]
   it keeps exploring after a success: uniqueness checking needs to know
   whether a second solution exists, not what it is. *)
let rec count_search digits cands cap =
  match propagate digits cands ignore with
  | exception Dead -> 0
  | () ->
    if Array.for_all (fun d -> d <> 0) digits
    then 1
    else (
      let c = mrv digits cands in
      let rec try_digits count = function
        | [] -> count
        | d :: rest ->
          if count >= cap
          then count
          else (
            let digits' = Array.copy digits
            and cands' = Array.copy cands in
            let count' =
              match place digits' cands' ignore c d (Guess (c, d)) with
              | exception Dead -> count
              | () -> count + count_search digits' cands' (cap - count)
            in
            try_digits count' rest)
      in
      try_digits 0 (List.filter (has cands.(c)) all_digits))
;;

(* [solution_count ?cap grid] counts the puzzle's solutions up to [cap];
   contradictory givens count as zero. A proper puzzle scores exactly 1. *)
let solution_count ?(cap = 2) grid =
  let digits = Array.make 81 0
  and cands = Array.make 81 full_mask in
  match
    Array.iteri
      (fun c d -> if d <> 0 then place digits cands ignore c d (Given (c, d)))
      grid
  with
  | exception Dead -> 0
  | () -> count_search digits cands cap
;;

(* in-place Fisher-Yates shuffle, drawing on the global [Random] state *)
let shuffle a =
  for i = Array.length a - 1 downto 1 do
    let j = Random.int (i + 1) in
    let t = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- t
  done
;;

(* [shuffle_list l] is a shuffled copy of [l]. *)
let shuffle_list l =
  let a = Array.of_list l in
  shuffle a;
  Array.to_list a
;;

(* [random_solved_grid ()] runs the solver on an empty board with shuffled
   guess order: propagation plus MRV completes it into a random valid
   grid almost without backtracking. *)
let random_solved_grid () =
  let digits = Array.make 81 0
  and cands = Array.make 81 full_mask in
  match search ~order:shuffle_list digits cands ignore with
  | Some grid -> grid
  | None -> assert false (* the empty board always has solutions *)
;;

(* [generate ()] digs a puzzle out of a random solved grid: visit the
   cells in random order, blank each one, and restore it whenever the
   blanking admits a second solution. The result is proper (unique
   solution) and minimal (every remaining given is load-bearing). *)
let generate () =
  let puzzle = random_solved_grid () in
  List.iter
    (fun c ->
       let saved = puzzle.(c) in
       puzzle.(c) <- 0;
       if solution_count puzzle <> 1 then puzzle.(c) <- saved)
    (shuffle_list (List.init 81 (fun c -> c)));
  puzzle
;;

(* [parse s] reads the 81-character format: digits, '.' or '0' for empty.
   The first offending character is reported by position. *)
let parse s =
  if String.length s <> 81
  then Error (Printf.sprintf "expected 81 characters, got %d" (String.length s))
  else (
    let grid = Array.make 81 0 in
    let bad = ref None in
    String.iteri
      (fun i ch ->
         match ch with
         | '1' .. '9' -> grid.(i) <- Char.code ch - Char.code '0'
         | '.' | '0' -> ()
         | _ -> if !bad = None then bad := Some (i, ch))
      s;
    match !bad with
    | Some (i, ch) -> Error (Printf.sprintf "invalid character %C at position %d" ch i)
    | None -> Ok grid)
;;

(* [candidates grid c] is the digits no peer of [c] holds: the pencil marks
   of an empty cell, recomputable from placements alone. *)
let candidates grid c =
  List.filter (fun d -> not (List.exists (fun p -> grid.(p) = d) peers.(c))) all_digits
;;

(* [to_string grid] prints the 81-character format, '.' for empty. *)
let to_string grid =
  String.init 81 (fun i ->
    if grid.(i) = 0 then '.' else Char.chr (grid.(i) + Char.code '0'))
;;
