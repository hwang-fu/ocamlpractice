(* Pure Koch-curve geometry; drawing lives in bin/main.ml. *)

(* Rotation of the vector (x, y) by [theta] radians. *)
let rotate theta (x, y) =
  (x *. cos theta) -. (y *. sin theta), (x *. sin theta) +. (y *. cos theta)
;;

(* [koch depth a b] is the polyline of the Koch curve of [depth] from [a] to
   [b]: a list of 4^depth + 1 points starting at [a] and ending at [b]. The
   bump of each subdivision grows to the left of the direction of travel.

   [go] prepends its curve's points (except the final endpoint) onto [acc],
   which already holds everything to the right; building the list back to
   front through an accumulator keeps the construction linear, where a
   naive [@] of the four children's lists would repeatedly recopy. *)
let koch depth a b =
  let rec go depth ((ax, ay) as a) ((bx, by) as b) acc =
    if depth = 0
    then a :: acc
    else (
      let dx = (bx -. ax) /. 3.
      and dy = (by -. ay) /. 3. in
      let cx, cy = ax +. dx, ay +. dy in
      let c = cx, cy in
      let e = ax +. (2. *. dx), ay +. (2. *. dy) in
      let rx, ry = rotate (Float.pi /. 3.) (dx, dy) in
      let d = cx +. rx, cy +. ry in
      go
        (depth - 1)
        a
        c
        (go (depth - 1) c d (go (depth - 1) d e (go (depth - 1) e b acc))))
  in
  go depth a b [ b ]
;;
