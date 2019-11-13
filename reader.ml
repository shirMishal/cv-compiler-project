
#use "pc.ml";;

exception X_not_yet_implemented;;
exception X_this_should_not_happen;;
  
type tuple =
  | Int of int
  | Float of float;;
  
type sexpr =
  | Bool of bool
  | Nil
  | Number of tuple

  | Char of char
  | String of string
  | Symbol of string
  | Pair of sexpr * sexpr
  | TaggedSexpr of string * sexpr
  | TagRef of string;;

let rec sexpr_eq s1 s2 =
  match s1, s2 with
  | Bool(b1), Bool(b2) -> b1 = b2
  | Nil, Nil -> true
  | Number(Float f1), Number(Float f2) -> abs_float(f1 -. f2) < 0.001
  | Number(Int n1), Number(Int n2) -> n1 = n2
  | Char(c1), Char(c2) -> c1 = c2
  | String(s1), String(s2) -> s1 = s2
  | Symbol(s1), Symbol(s2) -> s1 = s2
  | Pair(car1, cdr1), Pair(car2, cdr2) -> (sexpr_eq car1 car2) && (sexpr_eq cdr1 cdr2)
  | TaggedSexpr(name1, expr1), TaggedSexpr(name2, expr2) -> (name1 = name2) && (sexpr_eq expr1 expr2) 
  | TagRef(name1), TagRef(name2) -> name1 = name2
  | _ -> false;;
  
module Reader: sig
  val read_sexpr : string -> sexpr
  val read_sexprs : string -> sexpr list
end
= struct
let normalize_scheme_symbol str =
  let s = string_to_list str in
  if (andmap
	(fun ch -> (ch = (lowercase_ascii ch)))
	s) then str
  else Printf.sprintf "|%s|" str;;

let read_sexpr string = raise X_not_yet_implemented ;;

let read_sexprs string = raise X_not_yet_implemented;;
  
end;; (* struct Reader *)


open PC;;
open List;;
exception X_empty_list;;
let parse_true = make_word char_ci "#t ";;
let parse_false = make_word char_ci "#f ";;
let parse_boolean = disj parse_true parse_false;;
(*let parse_boolean = pack parse_boolean_sensitive lowercase_ascii;;*)

(*get parsed list (first in parse_boolean result) returns bool type of sexpr 
example: 
make_boolean ['#';'T';' '];;*)
let make_boolean bool_list = 
  match bool_list with
  | [] -> raise X_empty_list
  | x::xs ->  let c = (lowercase_ascii (nth bool_list 1)) in
              (if (c = 't') then (Bool(true))
              else if (c = 'f') then (Bool(false))
              else raise X_no_match);; 
      

let make_paired nt_left nt_right nt =
  let nt = caten nt_left nt in
  let nt = pack nt (function (_, e) -> e) in
  let nt = caten nt nt_right in
  let nt = pack nt (function (e, _) -> e) in
  nt;;

let make_spaced nt =
  make_paired (star nt_whitespace) (star nt_whitespace) nt;;

(*
let parse_comment = 
  let nt1 = make_paired (char ';') 
			(char '\n') nt_any in
  let nt2 =    in 
  disj nt1 nt2;;
let parse_comment = make_paired (make_spaced(char ';')) (make_spaced(char '\n')) (star(nt_any)) ;;
  
   *)
let parse_comment_ = 
    let nt = caten  (make_spaced(char ';')) (star(const(fun x-> Char.code x<> 10)))  in
    let nt = caten nt (make_spaced (char (Char.chr 10 ))) in
    nt ;;

let parse_minus = char_ci '-';;
let parse_plus = char_ci '+';;
let math_sign_nt = disj (char_ci '-') (char_ci '+');;


let make_nt_digit ch_from ch_to displacement =
    let nt = const (fun ch -> ch_from <= ch && ch <= ch_to) in
    let nt = pack nt (let delta = (Char.code ch_from) - displacement in
		      fun ch -> (Char.code ch) - delta) in nt;;


(**val int : char list = ['-'; '0'; '0'; '0'; '0'; '0'; '1'; '2']
# parse_integer int;;
- : int * char list = (-12, [])
 *)
let parse_integer = 
let nt = make_nt_digit '0' '9' 0 in
let nt = plus nt in
let nt_sign = disj (char_ci '-') (char_ci '+') in
let nt_sign = maybe nt_sign in
let nt = caten nt_sign nt in
let nt = pack nt (fun tuple ->
                  match tuple
                 with
                  | (None, digits) -> List.fold_left  (fun a b -> 10 * a + b) 0 digits
                  | (Some ch, digits) ->  match ch with
                                          | '-' -> -1 * (List.fold_left (fun a b -> 10 * a + b) 0 digits)
                                          | '+' -> List.fold_left (fun a b -> 10 * a + b) 0 digits
                                          | _ -> raise X_this_should_not_happen) in
nt;;