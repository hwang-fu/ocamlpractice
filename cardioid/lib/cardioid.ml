(* Pure cardioid geometry; drawing lives in bin/main.ml. *)

(* [point a theta] is the point (x, y) of the cardioid of radius [a] at angle
   [theta]:  x = a (1 - sin t) cos t,  y = a (1 - sin t) sin t. *)
let point a theta =
  let r = a *. (1. -. sin theta) in
  r *. cos theta, r *. sin theta
;;
