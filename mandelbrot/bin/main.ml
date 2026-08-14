open Graphics

let width = 1200
let height = 800
let k = 100

(* Viewport: 300 pixels per unit around a configurable center of the complex
   plane. The default (-0.5, 0) frames the whole set, which spans roughly
   [-2, 0.5] x [-1.12, 1.12]. *)
let scale = 300.
let default_a = -0.5
let default_b = 0.

(* Escape-time coloring: interpolate between a dark blue for
   fast escapes (far from the set) and a warm yellow for slow ones (hugging
   the boundary). The square root stretches the low escape times, where most
   pixels live, over more of the gradient. *)
let color_of_escape n =
  let t = sqrt (float n /. float k) in
  let blend lo hi = truncate (((1. -. t) *. float lo) +. (t *. float hi)) in
  rgb (blend 15 255) (blend 15 220) (blend 80 100)
;;

(* Paint every pixel, mapping window coordinates to the plane with
   [to_plane]. *)
let draw ~to_plane =
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

let run center_a center_b =
  open_graph (Printf.sprintf " %dx%d" width height);
  set_window_title "Mandelbrot set";
  let to_plane w h =
    ( center_a +. ((float w -. (float width /. 2.)) /. scale)
    , center_b +. ((float h -. (float height /. 2.)) /. scale) )
  in
  draw ~to_plane;
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;

let () =
  match Sys.argv with
  | [| _ |] -> run default_a default_b
  | [| _; a; b |] ->
    (match float_of_string_opt a, float_of_string_opt b with
     | Some a, Some b -> run a b
     | _ ->
       Printf.eprintf "error: expected two floats, got %S and %S\n" a b;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s [center_a center_b]\n" Sys.argv.(0);
    exit 1
;;
