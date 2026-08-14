open Graphics

let window_width = 1200
let window_height = 600
let discs = 5
let move_delay = 0.5

(* scene geometry, in pixels *)
let base_y = 80
let peg_height = 300
let disc_height = 30
let min_disc_width = 80
let max_disc_width = 260
let peg_x p = ((2 * p) + 1) * window_width / 6

(* disc sizes run 1 (smallest) to [discs]; width interpolates linearly *)
let disc_width d =
  min_disc_width + ((max_disc_width - min_disc_width) * (d - 1) / max 1 (discs - 1))
;;

(* blue for small discs shading to red for large ones *)
let disc_color d = rgb (40 + (40 * d)) 80 (200 - (30 * d))

(* [pegs] is an array of three stacks, top disc first. *)
let draw_scene pegs =
  clear_graph ();
  set_color black;
  fill_rect 100 (base_y - 10) (window_width - 200) 10;
  for p = 0 to 2 do
    fill_rect (peg_x p - 4) base_y 8 peg_height
  done;
  Array.iteri
    (fun p stack ->
       let height = List.length stack in
       List.iteri
         (fun i d ->
            let n_below = height - 1 - i in
            let w = disc_width d in
            set_color (disc_color d);
            fill_rect (peg_x p - (w / 2)) (base_y + (n_below * disc_height)) w disc_height)
         stack)
    pegs;
  synchronize ()
;;

let apply pegs (src, dst) =
  match pegs.(src) with
  | [] -> invalid_arg "apply: empty source peg"
  | d :: rest ->
    pegs.(src) <- rest;
    pegs.(dst) <- d :: pegs.(dst)
;;

let run () =
  open_graph (Printf.sprintf " %dx%d" window_width window_height);
  set_window_title "Tower of Hanoi";
  (* draw frames off-screen and flip them with [synchronize]: redrawing the
     whole scene directly would flicker *)
  auto_synchronize false;
  let pegs = [| List.init discs (fun i -> i + 1); []; [] |] in
  draw_scene pegs;
  List.iter
    (fun mv ->
       Unix.sleepf move_delay;
       apply pegs mv;
       draw_scene pegs)
    (Hanoi.solve discs);
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
