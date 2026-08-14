(* Pure Mandelbrot iteration; drawing lives in bin/main.ml. *)

let norm2 x y = (x *. x) +. (y *. y)

(* [escape ?k a b] iterates z <- z^2 + c from z = 0 for c = (a, b). It
   returns [Some n] when the sequence leaves the disk of radius 2 at step [n]
   (the escape time), or [None] if it survives [k] steps, in which case [c]
   is considered a member of the Mandelbrot set. *)
let escape ?(k = 100) a b =
  let rec go x y i =
    if i = k
    then None
    else if norm2 x y > 4.
    then Some i
    else go ((x *. x) -. (y *. y) +. a) ((2. *. x *. y) +. b) (i + 1)
  in
  go 0. 0. 0
;;

let in_set ?k a b = escape ?k a b = None
