(* Memoized infinite streams; printing lives in bin/.

   A stream is one produced element plus a suspended rest: forcing the
   suspension computes the next cell once, and [Lazy.t] memoizes it, so a
   stream traversed twice does its work once. There is no empty case: these
   are never-ending by construction. *)

type 'a t = Cons of 'a * 'a t Lazy.t

(* [head s] is the first element; already computed, costs nothing. *)
let head (Cons (x, _)) = x

(* [tail s] forces one step of the stream (memoized by [Lazy.t]). *)
let tail (Cons (_, rest)) = Lazy.force rest

(* [take n s] is the list of the first [n] elements. The [n = 1] case
   matters: OCaml evaluates arguments eagerly, so the tempting
   [head s :: take (n - 1) (tail s)] would force one cell beyond the
   last element taken. *)
let rec take n (Cons (x, rest)) =
  if n <= 0 then [] else if n = 1 then [ x ] else x :: take (n - 1) (Lazy.force rest)
;;

(* [map f s] applies [f] elementwise, lazily: elements of the result are
   computed only when reached. *)
let rec map f (Cons (x, rest)) = Cons (f x, lazy (map f (Lazy.force rest)))

(* [filter p s] keeps the elements satisfying [p]. Diverges if the stream
   stops producing satisfying elements: an infinite stream with nothing
   left to keep gives filter nowhere to stop searching. *)
let rec filter p (Cons (x, rest)) =
  if p x then Cons (x, lazy (filter p (Lazy.force rest))) else filter p (Lazy.force rest)
;;

(* [zip_with f s1 s2] combines two streams elementwise. *)
let rec zip_with f (Cons (x, xs)) (Cons (y, ys)) =
  Cons (f x y, lazy (zip_with f (Lazy.force xs) (Lazy.force ys)))
;;

(* [iterate f x] is the stream x, f x, f (f x), ... *)
let rec iterate f x = Cons (x, lazy (iterate f (f x)))

(* [merge s1 s2] merges two strictly ascending streams into one, dropping
   duplicates; the precondition keeps the output ascending too. *)
let rec merge (Cons (x, xs) as sx) (Cons (y, ys) as sy) =
  if x < y
  then Cons (x, lazy (merge (Lazy.force xs) sy))
  else if y < x
  then Cons (y, lazy (merge sx (Lazy.force ys)))
  else Cons (x, lazy (merge (Lazy.force xs) (Lazy.force ys)))
;;

(* [to_seq s] views the stream as a stdlib [Seq.t]. The two designs differ
   underneath: [Seq] re-runs its thunks on every traversal, while streams
   memoize; see the test suite for the observable difference. *)
let rec to_seq s () = Seq.Cons (head s, to_seq (tail s))

(* [of_seq s] converts an infinite [Seq.t]; a finite one is a caller error
   since streams have no empty case. *)
let rec of_seq s =
  match s () with
  | Seq.Nil -> invalid_arg "of_seq: the sequence ended, streams never do"
  | Seq.Cons (x, rest) -> Cons (x, lazy (of_seq rest))
;;

(* the natural numbers 0, 1, 2, ... *)
let nats = iterate succ 0

(* The Fibonacci numbers, defined by zipping the stream with its own tail:
   each element is the sum of the two before it, so the stream is built
   from two shifted copies of itself. Corecursion at its purest: the
   definition consumes what it has already produced. *)
let rec fibs = Cons (0, lazy (Cons (1, lazy (zip_with ( + ) fibs (tail fibs)))))

(* The primes by the lazy sieve: keep the head, then sieve the rest of the
   candidates with one more divisibility filter. Every prime adds a layer
   of [filter], so the sieve deepens as it is consumed. *)
let primes =
  let rec sieve (Cons (p, rest)) =
    Cons (p, lazy (sieve (filter (fun n -> n mod p <> 0) (Lazy.force rest))))
  in
  sieve (iterate succ 2)
;;

(* The Hamming numbers (products of 2, 3 and 5 only), as the classic
   self-referential merge: after 1, every Hamming number is a smaller one
   multiplied by 2, 3 or 5, so the stream is the merge of its own three
   scaled copies. *)
let rec hamming =
  Cons
    ( 1
    , lazy
        (merge
           (map (( * ) 2) hamming)
           (merge (map (( * ) 3) hamming) (map (( * ) 5) hamming))) )
;;
