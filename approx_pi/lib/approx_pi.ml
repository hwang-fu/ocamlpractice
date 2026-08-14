(* Pure Monte-Carlo logic; drawing lives in bin/main.ml. *)

(* [in_circle x y] tests whether (x, y) lies in the quarter disk of radius 1
   centered at the origin. *)
let in_circle x y = (x *. x) +. (y *. y) <= 1.0

(* [approx_pi ?plot n] estimates pi from [n] uniform random points in the unit
   square, invoking [plot x y inside] on each point. [plot] defaults to doing
   nothing, so the library stays usable without any graphics. *)
let approx_pi ?(plot = fun _x _y _inside -> ()) n =
  let p = ref 0 in
  for _ = 1 to n do
    let x = Random.float 1.0 in
    let y = Random.float 1.0 in
    let inside = in_circle x y in
    if inside then incr p;
    plot x y inside
  done;
  4.0 *. float !p /. float n
;;
