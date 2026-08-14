open Graphics

let width = 1200
let height = 800
let k = 100

(* Viewport on the complex plane: 300 pixels per unit, centered on (-0.5, 0),
   so the window shows [-2.5, 1.5] x [-4/3, 4/3] -- the set spans roughly
   [-2, 0.5] x [-1.12, 1.12] and sits comfortably inside. *)
let scale = 300.
let center_a = -0.5
let center_b = 0.

let to_plane w h =
  ( center_a +. ((float w -. (float width /. 2.)) /. scale)
  , center_b +. ((float h -. (float height /. 2.)) /. scale) )
;;

(* Escape-time coloring (exercise 2.3): interpolate between a dark blue for
   fast escapes (far from the set) and a warm yellow for slow ones (hugging
   the boundary). The square root stretches the low escape times, where most
   pixels live, over more of the gradient. *)
let color_of_escape n =
  let t = sqrt (float n /. float k) in
  let blend lo hi = truncate (((1. -. t) *. float lo) +. (t *. float hi)) in
  rgb (blend 15 255) (blend 15 220) (blend 80 100)
;;

let draw () =
  for w = 0 to width - 1 do
    for h = 0 to height - 1 do
      let a, b = to_plane w h in
      (match Mandelbrot.escape ~k a b with
       | None -> set_color black
       | Some n -> set_color (color_of_escape n));
      plot w h
    done
  done
;;

let () =
  open_graph (Printf.sprintf " %dx%d" width height);
  set_window_title "Mandelbrot set";
  draw ();
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
