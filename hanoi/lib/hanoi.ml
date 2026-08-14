(* Tower of Hanoi solver; drawing lives in bin/main.ml. *)

type move = int * int

(* [solve n] is the move sequence carrying [n] discs from peg 0 to peg 2:
   move the top n-1 discs onto the spare peg, carry the biggest disc across,
   bring the n-1 back on top of it. [acc] holds the moves that come after
   the current sub-problem, so the list is built back to front in linear
   time. *)
let solve n =
  let rec go n src aux dst acc =
    if n = 0
    then acc
    else go (n - 1) src dst aux ((src, dst) :: go (n - 1) aux src dst acc)
  in
  go n 0 1 2 []
;;
