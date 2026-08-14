(* Backtracking N-queens solver over persistent integer sets. *)

module S = Set.Make (Int)

(* [map f s] is the image of the set [s] under [f]. *)
let map f s = S.fold (fun x acc -> S.add (f x) acc) s S.empty

(* [upto n] is the set {0, 1, ..., n}. *)
let rec upto n = if n < 0 then S.empty else S.add n (upto (n - 1))

(* [go cols d1 d2] counts the solutions extending the current partial
   placement: [cols] are the still-free columns, [d1]/[d2] the columns
   attacked in the current row along left/right diagonals. The sets are
   persistent, which makes backtracking implicit: a recursive call never
   modifies its caller's sets, so trying the next candidate needs no undo. *)
let rec go cols d1 d2 =
  if S.is_empty cols
  then 1
  else
    S.fold
      (fun c acc ->
         let d1 = map succ (S.add c d1) in
         let d2 = map pred (S.add c d2) in
         acc + go (S.remove c cols) d1 d2)
      (S.diff (S.diff cols d1) d2)
      0
;;

(* [count n] is the number of solutions of the n-queens problem. *)
let count n = go (upto (n - 1)) S.empty S.empty
