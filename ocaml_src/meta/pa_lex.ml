(* camlp4r *)
(* This file has been generated by program: do not edit! *)
(* Copyright (c) INRIA 2007 *)

(* Simplified syntax of parsers of characters streams *)

(* #load "pa_extend.cmo" *)
(* #load "q_MLast.cmo" *)

open Pcaml;;

(**)
let var () = "buf";;
let empty loc =
  MLast.ExAcc (loc, MLast.ExUid (loc, "B"), MLast.ExLid (loc, "empty"))
;;
let add_char loc c cl =
  MLast.ExApp
    (loc,
     MLast.ExApp
       (loc,
        MLast.ExAcc (loc, MLast.ExUid (loc, "B"), MLast.ExLid (loc, "add")),
        c),
     cl)
;;
let get_buf loc cl =
  MLast.ExApp
    (loc, MLast.ExAcc (loc, MLast.ExUid (loc, "B"), MLast.ExLid (loc, "get")),
     cl)
;;
(*
value var () = "buf";
value empty loc = <:expr< [] >>;
value add_char loc c cl = <:expr< [$c$ :: $cl$] >>;
value get_buf loc cl = <:expr< List.rev $cl$ >>;
*)

let fresh_c cl =
  let n =
    List.fold_left
      (fun n c ->
         match c with
           MLast.ExLid (_, _) -> n + 1
         | _ -> n)
      0 cl
  in
  if n = 0 then "c" else "c" ^ string_of_int n
;;

let accum_chars loc cl =
  List.fold_right (add_char loc) cl (MLast.ExLid (loc, var ()))
;;

let conv_rules loc rl =
  List.map
    (fun (sl, cl, a) ->
       let a =
         let b = accum_chars loc cl in
         match a with
           Some e -> e
         | None -> b
       in
       List.rev sl, None, a)
    rl
;;

let mk_lexer loc rl = Exparser.cparser loc None (conv_rules loc rl);;

let mk_lexer_match loc e rl =
  Exparser.cparser_match loc e None (conv_rules loc rl)
;;

let isolate_char_patt_list =
  let rec loop pl =
    function
      ([Exparser.SpTrm (_, p, None), None], [_], None) :: rl ->
        let p =
          match p with
            MLast.PaChr (_, _) -> p
          | MLast.PaAli (_, p, MLast.PaLid (_, _)) -> p
          | p -> p
        in
        loop (p :: pl) rl
    | rl -> List.rev pl, rl
  in
  loop []
;;

let or_patt_of_patt_list loc =
  function
    p :: pl -> List.fold_left (fun p1 p2 -> MLast.PaOrp (loc, p1, p2)) p pl
  | [] -> invalid_arg "or_patt_of_patt_list"
;;

let isolate_char_patt loc rl =
  match isolate_char_patt_list rl with
    ([] | [_]), _ -> None, rl
  | pl, rl -> Some (or_patt_of_patt_list loc pl), rl
;;

let make_rules loc rl sl cl errk =
  match isolate_char_patt loc rl with
    Some p, [] ->
      let c = fresh_c cl in
      let s =
        let p = MLast.PaAli (loc, p, MLast.PaLid (loc, c)) in
        Exparser.SpTrm (loc, p, None), errk
      in
      s :: sl, MLast.ExLid (loc, c) :: cl
  | x ->
      let rl =
        match x with
          Some p, rl ->
            let r =
              let p = MLast.PaAli (loc, p, MLast.PaLid (loc, "c")) in
              let e = MLast.ExLid (loc, "c") in
              [Exparser.SpTrm (loc, p, None), None], [e], None
            in
            r :: rl
        | None, rl -> rl
      in
      let errk =
        match List.rev rl with
          ([], _, _) :: _ -> Some None
        | _ -> errk
      in
      let sl =
        if cl = [] then sl
        else
          let s =
            let b = accum_chars loc cl in
            let e = Exparser.cparser loc None [[], None, b] in
            Exparser.SpNtr (loc, MLast.PaLid (loc, var ()), e), Some None
          in
          s :: sl
      in
      let s =
        let e = mk_lexer loc rl in
        Exparser.SpNtr (loc, MLast.PaLid (loc, var ()), e), errk
      in
      s :: sl, []
;;

let make_any loc norec sl cl errk =
  let (p, cl) =
    if norec then MLast.PaAny loc, cl
    else
      let c = fresh_c cl in MLast.PaLid (loc, c), MLast.ExLid (loc, c) :: cl
  in
  let s = Exparser.SpTrm (loc, p, None), errk in s :: sl, cl
;;

let next_char s i =
  if i = String.length s then invalid_arg "next_char"
  else if s.[i] = '\\' then
    if i + 1 = String.length s then "\\", i + 1
    else
      match s.[i + 1] with
        '0'..'9' ->
          if i + 3 < String.length s then
            Printf.sprintf "\\%c%c%c" s.[i + 1] s.[i + 2] s.[i + 3], i + 4
          else "\\", i + 1
      | c -> "\\" ^ String.make 1 c, i + 2
  else String.make 1 s.[i], i + 1
;;

let fold_string_chars f s a =
  let rec loop i a =
    if i = String.length s then a
    else let (c, i) = next_char s i in loop i (f c a)
  in
  loop 0 a
;;

let make_or_chars loc s norec sl cl errk =
  let pl =
    let rec loop i =
      if i = String.length s then []
      else
        let (c, i) = next_char s i in
        let p = MLast.PaChr (loc, c) in
        let (p, i) =
          if i < String.length s - 2 && s.[i] = '.' && s.[i + 1] = '.' then
            let (c, i) = next_char s (i + 2) in
            MLast.PaRng (loc, p, MLast.PaChr (loc, c)), i
          else p, i
        in
        p :: loop i
    in
    loop 0
  in
  match pl with
    [] -> sl, cl
  | [MLast.PaChr (_, c)] ->
      let s = Exparser.SpTrm (loc, MLast.PaChr (loc, c), None), errk in
      let cl = if norec then cl else MLast.ExChr (loc, c) :: cl in s :: sl, cl
  | pl ->
      let c = fresh_c cl in
      let s =
        let p =
          let p = or_patt_of_patt_list loc pl in
          if norec then p else MLast.PaAli (loc, p, MLast.PaLid (loc, c))
        in
        Exparser.SpTrm (loc, p, None), errk
      in
      let cl = if norec then cl else MLast.ExLid (loc, c) :: cl in s :: sl, cl
;;

let make_sub_lexer loc f sl cl errk =
  let s =
    let buf = accum_chars loc cl in
    let e = MLast.ExApp (loc, f, buf) in
    let p = MLast.PaLid (loc, var ()) in Exparser.SpNtr (loc, p, e), errk
  in
  s :: sl, []
;;

let make_lookahd loc pll sl cl errk =
  let s = Exparser.SpLhd (loc, pll), errk in s :: sl, cl
;;

let gcl = ref [];;

Grammar.extend
  (let _ = (expr : 'expr Grammar.Entry.e) in
   let grammar_entry_create s =
     Grammar.Entry.create (Grammar.of_entry expr) s
   in
   let rules : 'rules Grammar.Entry.e = grammar_entry_create "rules"
   and rule : 'rule Grammar.Entry.e = grammar_entry_create "rule"
   and symb_list : 'symb_list Grammar.Entry.e =
     grammar_entry_create "symb_list"
   and symbs : 'symbs Grammar.Entry.e = grammar_entry_create "symbs"
   and symb : 'symb Grammar.Entry.e = grammar_entry_create "symb"
   and simple_expr : 'simple_expr Grammar.Entry.e =
     grammar_entry_create "simple_expr"
   and lookahead : 'lookahead Grammar.Entry.e =
     grammar_entry_create "lookahead"
   and lookahead_char : 'lookahead_char Grammar.Entry.e =
     grammar_entry_create "lookahead_char"
   and no_rec : 'no_rec Grammar.Entry.e = grammar_entry_create "no_rec"
   and err_kont : 'err_kont Grammar.Entry.e = grammar_entry_create "err_kont"
   and act : 'act Grammar.Entry.e = grammar_entry_create "act" in
   [Grammar.Entry.obj (expr : 'expr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "match"); Gramext.Sself;
       Gramext.Stoken ("", "with"); Gramext.Stoken ("", "lexer");
       Gramext.Snterm (Grammar.Entry.obj (rules : 'rules Grammar.Entry.e))],
      Gramext.action
        (fun (rl : 'rules) _ _ (e : 'expr) _ (loc : Token.location) ->
           (mk_lexer_match loc e rl : 'expr));
      [Gramext.Stoken ("", "lexer");
       Gramext.Snterm (Grammar.Entry.obj (rules : 'rules Grammar.Entry.e))],
      Gramext.action
        (fun (rl : 'rules) _ (loc : Token.location) ->
           (let rl =
              match isolate_char_patt loc rl with
                Some p, rl ->
                  let p = MLast.PaAli (loc, p, MLast.PaLid (loc, "c")) in
                  let e = MLast.ExLid (loc, "c") in
                  ([Exparser.SpTrm (loc, p, None), None], [e], None) :: rl
              | None, rl -> rl
            in
            MLast.ExFun
              (loc, [MLast.PaLid (loc, var ()), None, mk_lexer loc rl]) :
            'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("", "$"); Gramext.Stoken ("LIDENT", "pos")],
      Gramext.action
        (fun _ _ (loc : Token.location) ->
           (MLast.ExApp
              (loc,
               MLast.ExAcc
                 (loc, MLast.ExUid (loc, "Stream"),
                  MLast.ExLid (loc, "count")),
               MLast.ExLid (loc, Exparser.strm_n)) :
            'expr));
      [Gramext.Stoken ("", "$"); Gramext.Stoken ("LIDENT", "empty")],
      Gramext.action (fun _ _ (loc : Token.location) -> (empty loc : 'expr));
      [Gramext.Stoken ("", "$"); Gramext.Stoken ("LIDENT", "buf")],
      Gramext.action
        (fun _ _ (loc : Token.location) ->
           (get_buf loc (accum_chars loc !gcl) : 'expr));
      [Gramext.Stoken ("", "$"); Gramext.Stoken ("LIDENT", "add");
       Gramext.Snterm
         (Grammar.Entry.obj (simple_expr : 'simple_expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'simple_expr) _ _ (loc : Token.location) ->
           (add_char loc e (accum_chars loc !gcl) : 'expr));
      [Gramext.Stoken ("", "$"); Gramext.Stoken ("LIDENT", "add");
       Gramext.Stoken ("STRING", "")],
      Gramext.action
        (fun (s : string) _ _ (loc : Token.location) ->
           (let rec loop v i =
              if i = String.length s then v
              else
                let (c, i) = next_char s i in
                loop (add_char loc (MLast.ExChr (loc, c)) v) i
            in
            loop (accum_chars loc !gcl) 0 :
            'expr))]];
    Grammar.Entry.obj (rules : 'rules Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "[");
       Gramext.Slist0sep
         (Gramext.Snterm (Grammar.Entry.obj (rule : 'rule Grammar.Entry.e)),
          Gramext.Stoken ("", "|"));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (rl : 'rule list) _ (loc : Token.location) -> (rl : 'rules))]];
    Grammar.Entry.obj (rule : 'rule Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (symb_list : 'symb_list Grammar.Entry.e));
       Gramext.Snterm (Grammar.Entry.obj (act : 'act Grammar.Entry.e))],
      Gramext.action
        (fun (a : 'act) (sl, cl : 'symb_list) (loc : Token.location) ->
           (sl, cl, a : 'rule))]];
    Grammar.Entry.obj (symb_list : 'symb_list Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (symbs : 'symbs Grammar.Entry.e))],
      Gramext.action
        (fun (sl, cl : 'symbs) (loc : Token.location) ->
           (gcl := cl; sl, cl : 'symb_list))]];
    Grammar.Entry.obj (symbs : 'symbs Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Token.location) -> ([], [] : 'symbs));
      [Gramext.Sself;
       Gramext.Snterm (Grammar.Entry.obj (symb : 'symb Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj (err_kont : 'err_kont Grammar.Entry.e))],
      Gramext.action
        (fun (kont : 'err_kont) (f : 'symb) (sl, cl : 'symbs)
           (loc : Token.location) ->
           (f sl cl kont : 'symbs))]];
    Grammar.Entry.obj (symb : 'symb Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (rules : 'rules Grammar.Entry.e))],
      Gramext.action
        (fun (rl : 'rules) (loc : Token.location) ->
           (make_rules loc rl : 'symb));
      [Gramext.Stoken ("", "?="); Gramext.Stoken ("", "[");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (lookahead : 'lookahead Grammar.Entry.e)),
          Gramext.Stoken ("", "|"));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (pll : 'lookahead list) _ _ (loc : Token.location) ->
           (make_lookahd loc pll : 'symb));
      [Gramext.Snterm
         (Grammar.Entry.obj (simple_expr : 'simple_expr Grammar.Entry.e))],
      Gramext.action
        (fun (f : 'simple_expr) (loc : Token.location) ->
           (make_sub_lexer loc f : 'symb));
      [Gramext.Stoken ("STRING", "");
       Gramext.Snterm (Grammar.Entry.obj (no_rec : 'no_rec Grammar.Entry.e))],
      Gramext.action
        (fun (norec : 'no_rec) (s : string) (loc : Token.location) ->
           (make_or_chars loc s norec : 'symb));
      [Gramext.Stoken ("", "_");
       Gramext.Snterm (Grammar.Entry.obj (no_rec : 'no_rec Grammar.Entry.e))],
      Gramext.action
        (fun (norec : 'no_rec) _ (loc : Token.location) ->
           (make_any loc norec : 'symb))]];
    Grammar.Entry.obj (simple_expr : 'simple_expr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "(");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e : 'expr) _ (loc : Token.location) -> (e : 'simple_expr));
      [Gramext.Stoken ("CHAR", "")],
      Gramext.action
        (fun (c : string) (loc : Token.location) ->
           (MLast.ExChr (loc, c) : 'simple_expr));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Token.location) ->
           (MLast.ExLid (loc, i) : 'simple_expr))]];
    Grammar.Entry.obj (lookahead : 'lookahead Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("STRING", "")],
      Gramext.action
        (fun (s : string) (loc : Token.location) ->
           (List.rev
              (fold_string_chars (fun c pl -> MLast.PaChr (loc, c) :: pl) s
                 []) :
            'lookahead));
      [Gramext.Slist1
         (Gramext.Snterm
            (Grammar.Entry.obj
               (lookahead_char : 'lookahead_char Grammar.Entry.e)))],
      Gramext.action
        (fun (pl : 'lookahead_char list) (loc : Token.location) ->
           (pl : 'lookahead))]];
    Grammar.Entry.obj (lookahead_char : 'lookahead_char Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "_")],
      Gramext.action
        (fun _ (loc : Token.location) -> (MLast.PaAny loc : 'lookahead_char));
      [Gramext.Stoken ("CHAR", "")],
      Gramext.action
        (fun (c : string) (loc : Token.location) ->
           (MLast.PaChr (loc, c) : 'lookahead_char))]];
    Grammar.Entry.obj (no_rec : 'no_rec Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Token.location) -> (false : 'no_rec));
      [Gramext.Stoken ("", "/")],
      Gramext.action (fun _ (loc : Token.location) -> (true : 'no_rec))]];
    Grammar.Entry.obj (err_kont : 'err_kont Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Token.location) -> (None : 'err_kont));
      [Gramext.Stoken ("", "?");
       Gramext.Snterm
         (Grammar.Entry.obj (simple_expr : 'simple_expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'simple_expr) _ (loc : Token.location) ->
           (Some (Some e) : 'err_kont));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("STRING", "")],
      Gramext.action
        (fun (s : string) _ (loc : Token.location) ->
           (Some (Some (MLast.ExStr (loc, s))) : 'err_kont));
      [Gramext.Stoken ("", "!")],
      Gramext.action
        (fun _ (loc : Token.location) -> (Some None : 'err_kont))]];
    Grammar.Entry.obj (act : 'act Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Token.location) -> (None : 'act));
      [Gramext.Stoken ("", "->");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (loc : Token.location) -> (Some e : 'act))]]]);;
