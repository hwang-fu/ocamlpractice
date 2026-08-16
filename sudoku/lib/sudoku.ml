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
   possible. *)
let full_mask = 0b1_1111_1111
let bit d = 1 lsl (d - 1)
let has m d = m land bit d <> 0

let popcount m =
  let rec go m acc = if m = 0 then acc else go (m lsr 1) (acc + (m land 1)) in
  go m 0
;;

let singleton_digit m = List.find (has m) all_digits

let units_of c =
  let r = c / 9
  and col = c mod 9 in
  [ Row r; Col col; Box ((r / 3 * 3) + (col / 3)) ]
;;

let cells_of = function
  | Row r -> List.init 9 (fun i -> (r * 9) + i)
  | Col c -> List.init 9 (fun i -> (i * 9) + c)
  | Box b ->
    let r0 = b / 3 * 3
    and c0 = b mod 3 * 3 in
    List.init 9 (fun i -> ((r0 + (i / 3)) * 9) + c0 + (i mod 3))
;;

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

(* [place] records [step], writes the digit, and erases it from all peers'
   candidate sets; a peer emptied by the erasure is a contradiction. *)
let place digits cands trace c d step =
  trace := step :: !trace;
  (* a digit eliminated from this very cell cannot be placed here: this
     catches contradictory givens the moment they arrive *)
  if not (has cands.(c) d)
  then (
    trace := Contradiction c :: !trace;
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
           trace := Contradiction p :: !trace;
           raise Dead)))
    peers.(c)
;;

(* Run naked singles and hidden singles to the fixpoint. *)
let rec propagate digits cands trace =
  let fired = ref false in
  for c = 0 to 80 do
    if digits.(c) = 0 && popcount cands.(c) = 1
    then (
      let d = singleton_digit cands.(c) in
      place digits cands trace c d (Naked (c, d));
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
                  place digits cands trace c d (Hidden (c, d, u));
                  fired := true
                | _ -> ()))
           all_digits)
      all_units;
  if !fired then propagate digits cands trace
;;

let mrv digits cands =
  let best = ref (-1) in
  for c = 0 to 80 do
    if digits.(c) = 0 && (!best = -1 || popcount cands.(c) < popcount cands.(!best))
    then best := c
  done;
  !best
;;

let rec search digits cands trace =
  match propagate digits cands trace with
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
          (match place digits' cands' trace c d (Guess (c, d)) with
           | exception Dead ->
             trace := Backtrack :: !trace;
             try_digits rest
           | () ->
             (match search digits' cands' trace with
              | Some _ as solved -> solved
              | None ->
                trace := Backtrack :: !trace;
                try_digits rest))
      in
      try_digits (List.filter (has cands.(c)) all_digits))
;;

let solve grid =
  let trace = ref [] in
  let digits = Array.make 81 0
  and cands = Array.make 81 full_mask in
  match
    Array.iteri
      (fun c d -> if d <> 0 then place digits cands trace c d (Given (c, d)))
      grid
  with
  | exception Dead -> List.rev !trace, None
  | () -> List.rev !trace, search digits cands trace
;;

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

let to_string grid =
  String.init 81 (fun i ->
    if grid.(i) = 0 then '.' else Char.chr (grid.(i) + Char.code '0'))
;;
