(* camlp5r pa_macro.cmo *)
(* This file has been generated by program: do not edit! *)
(* Copyright (c) INRIA 2007 *)

(* Experimental AST quotations while running the normal parser and
   its possible extensions and meta-ifying the nodes. Antiquotations
   work only in "strict" mode. *)

(* #load "pa_extend.cmo";; *)
(* #load "q_MLast.cmo";; *)

let not_impl f x =
  let desc =
    if Obj.is_block (Obj.repr x) then
      "tag = " ^ string_of_int (Obj.tag (Obj.repr x))
    else "int_val = " ^ string_of_int (Obj.magic x)
  in
  failwith ("q_ast.ml: " ^ f ^ ", not impl: " ^ desc)
;;

let call_with r v f a =
  let saved = !r in
  try r := v; let b = f a in r := saved; b with e -> r := saved; raise e
;;

let eval_anti entry loc typ str =
  let loc =
    let sh =
      if typ = "" then String.length "$"
      else String.length "$" + String.length typ + String.length ":"
    in
    let len = String.length str in Ploc.sub loc sh len
  in
  let r =
    try
      call_with Plexer.force_antiquot_loc false (Grammar.Entry.parse entry)
        (Stream.of_string str)
    with Ploc.Exc (loc1, exc) ->
      let shift = Ploc.first_pos loc in
      let loc =
        Ploc.make (Ploc.line_nb loc + Ploc.line_nb loc1 - 1)
          (if Ploc.line_nb loc1 = 1 then Ploc.bol_pos loc
           else shift + Ploc.bol_pos loc1)
          (shift + Ploc.first_pos loc1, shift + Ploc.last_pos loc1)
      in
      raise (Ploc.Exc (loc, exc))
  in
  loc, r
;;

let get_anti_loc s =
  try
    let i = String.index s ':' in
    let (j, len) =
      let rec loop j =
        if j = String.length s then i, 0
        else
          match s.[j] with
            ':' -> j, j - i - 1
          | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> loop (j + 1)
          | _ -> i, 0
      in
      loop (i + 1)
    in
    let kind = String.sub s (i + 1) len in
    let loc =
      let k = String.index s ',' in
      let bp = int_of_string (String.sub s 0 k) in
      let ep = int_of_string (String.sub s (k + 1) (i - k - 1)) in
      Ploc.make_unlined (bp, ep)
    in
    Some (loc, kind, String.sub s (j + 1) (String.length s - j - 1))
  with Not_found | Failure _ -> None
;;

module Meta =
  struct
    open MLast;;
    let loc = Ploc.dummy;;
    let ln () = MLast.ExLid (loc, !(Ploc.name));;
    let e_vala elem e = elem e;;
    let p_vala elem p = elem p;;
    let e_xtr loc s =
      match get_anti_loc s with
        Some (loc, typ, str) ->
          begin match typ with
            "" ->
              let (loc, r) = eval_anti Pcaml.expr_eoi loc "" str in
              MLast.ExAnt (loc, r)
          | "anti" ->
              let (loc, r) = eval_anti Pcaml.expr_eoi loc "anti" str in
              let r = MLast.ExAnt (loc, r) in
              MLast.ExApp
                (loc,
                 MLast.ExApp
                   (loc,
                    MLast.ExAcc
                      (loc, MLast.ExUid (loc, "MLast"),
                       MLast.ExUid (loc, "ExAnt")),
                    MLast.ExLid (loc, "loc")),
                 r)
          | _ -> assert false
          end
      | _ -> assert false
    ;;
    let p_xtr loc s =
      match get_anti_loc s with
        Some (loc, typ, str) ->
          begin match typ with
            "" ->
              let (loc, r) = eval_anti Pcaml.patt_eoi loc "" str in
              MLast.PaAnt (loc, r)
          | "anti" ->
              let (loc, r) = eval_anti Pcaml.patt_eoi loc "anti" str in
              let r = MLast.PaAnt (loc, r) in
              MLast.PaApp
                (loc,
                 MLast.PaApp
                   (loc,
                    MLast.PaAcc
                      (loc, MLast.PaUid (loc, "MLast"),
                       MLast.PaUid (loc, "PaAnt")),
                    MLast.PaLid (loc, "loc")),
                 r)
          | _ -> assert false
          end
      | _ -> assert false
    ;;
    let e_list elem el =
      let rec loop el =
        match el with
          [] -> MLast.ExUid (loc, "[]")
        | e :: el ->
            MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExUid (loc, "::"), elem e),
               loop el)
      in
      loop el
    ;;
    let p_list elem el =
      let rec loop el =
        match el with
          [] -> MLast.PaUid (loc, "[]")
        | e :: el ->
            MLast.PaApp
              (loc, MLast.PaApp (loc, MLast.PaUid (loc, "::"), elem e),
               loop el)
      in
      loop el
    ;;
    let e_option elem oe =
      match oe with
        None -> MLast.ExUid (loc, "None")
      | Some e -> MLast.ExApp (loc, MLast.ExUid (loc, "Some"), elem e)
    ;;
    let p_option elem oe =
      match oe with
        None -> MLast.PaUid (loc, "None")
      | Some e -> MLast.PaApp (loc, MLast.PaUid (loc, "Some"), elem e)
    ;;
    let e_bool b =
      if b then MLast.ExUid (loc, "True") else MLast.ExUid (loc, "False")
    ;;
    let p_bool b =
      if b then MLast.PaUid (loc, "True") else MLast.PaUid (loc, "False")
    ;;
    let e_string s = MLast.ExStr (loc, s);;
    let p_string s = MLast.PaStr (loc, s);;
    let e_node con el =
      List.fold_left (fun e1 e2 -> MLast.ExApp (loc, e1, e2))
        (MLast.ExApp
           (loc,
            MLast.ExAcc
              (loc, MLast.ExUid (loc, "MLast"), MLast.ExUid (loc, con)),
            ln ()))
        el
    ;;
    let p_node con pl =
      List.fold_left (fun p1 p2 -> MLast.PaApp (loc, p1, p2))
        (MLast.PaApp
           (loc,
            MLast.PaAcc
              (loc, MLast.PaUid (loc, "MLast"), MLast.PaUid (loc, con)),
            MLast.PaAny loc))
        pl
    ;;
    let rec e_ctyp =
      function
        TyAcc (_, t1, t2) -> e_node "TyAcc" [e_ctyp t1; e_ctyp t2]
      | TyAli (_, t1, t2) -> e_node "TyAli" [e_ctyp t1; e_ctyp t2]
      | TyArr (_, t1, t2) -> e_node "TyArr" [e_ctyp t1; e_ctyp t2]
      | TyAny _ -> e_node "TyAny" []
      | TyApp (_, t1, t2) -> e_node "TyApp" [e_ctyp t1; e_ctyp t2]
      | TyLid (_, s) -> e_node "TyLid" [e_vala e_string s]
      | TyMan (_, t1, t2) -> e_node "TyMan" [e_ctyp t1; e_ctyp t2]
      | TyPol (_, lv, t) ->
          e_node "TyPol" [e_vala (e_list e_string) lv; e_ctyp t]
      | TyQuo (_, s) -> e_node "TyQuo" [e_vala e_string s]
      | TyRec (_, lld) ->
          let lld =
            e_vala
              (e_list
                 (fun (loc, lab, mf, t) ->
                    MLast.ExTup
                      (loc,
                       [ln (); MLast.ExStr (loc, lab); e_bool mf; e_ctyp t])))
              lld
          in
          e_node "TyRec" [lld]
      | TySum (_, lcd) ->
          let lcd =
            e_vala
              (e_list
                 (fun (loc, lab, lt) ->
                    let lt = e_vala (e_list e_ctyp) lt in
                    MLast.ExTup (loc, [ln (); e_vala e_string lab; lt])))
              lcd
          in
          e_node "TySum" [lcd]
      | TyTup (_, tl) -> e_node "TyTup" [e_vala (e_list e_ctyp) tl]
      | TyUid (_, s) -> e_node "TyUid" [e_vala e_string s]
      | x -> not_impl "e_ctyp" x
    ;;
    let rec p_ctyp =
      function
        TyArr (_, t1, t2) -> p_node "TyArr" [p_ctyp t1; p_ctyp t2]
      | TyApp (_, t1, t2) -> p_node "TyApp" [p_ctyp t1; p_ctyp t2]
      | TyLid (_, s) -> p_node "TyLid" [p_vala p_string s]
      | TyTup (_, tl) -> p_node "TyTup" [p_vala (p_list p_ctyp) tl]
      | TyUid (_, s) -> p_node "TyUid" [p_vala p_string s]
      | x -> not_impl "p_ctyp" x
    ;;
    let e_class_infos a x = not_impl "e_class_infos" x;;
    let e_type_var x = not_impl "e_type_var" x;;
    let rec e_patt =
      function
        PaAcc (_, p1, p2) -> e_node "PaAcc" [e_patt p1; e_patt p2]
      | PaAli (_, p1, p2) -> e_node "PaAli" [e_patt p1; e_patt p2]
      | PaAny _ -> e_node "PaAny" []
      | PaApp (_, p1, p2) -> e_node "PaApp" [e_patt p1; e_patt p2]
      | PaArr (_, pl) -> e_node "PaArr" [e_vala (e_list e_patt) pl]
      | PaChr (_, s) -> e_node "PaChr" [e_vala e_string s]
      | PaInt (_, s, k) -> e_node "PaInt" [e_vala e_string s; e_string k]
      | PaFlo (_, s) -> e_node "PaFlo" [e_vala e_string s]
      | PaLid (_, s) -> e_node "PaLid" [e_vala e_string s]
      | PaOrp (_, p1, p2) -> e_node "PaOrp" [e_patt p1; e_patt p2]
      | PaRec (_, lpe) ->
          let lpe =
            e_vala
              (e_list (fun (p, e) -> MLast.ExTup (loc, [e_patt p; e_patt e])))
              lpe
          in
          e_node "PaRec" [lpe]
      | PaRng (_, p1, p2) -> e_node "PaRng" [e_patt p1; e_patt p2]
      | PaStr (_, s) -> e_node "PaStr" [e_vala e_string s]
      | PaTup (_, pl) -> e_node "PaTup" [e_vala (e_list e_patt) pl]
      | PaTyc (_, p, t) -> e_node "PaTyc" [e_patt p; e_ctyp t]
      | PaUid (_, s) -> e_node "PaUid" [e_vala e_string s]
      | x -> not_impl "e_patt" x
    ;;
    let rec p_patt =
      function
        PaAcc (_, p1, p2) -> p_node "PaAcc" [p_patt p1; p_patt p2]
      | PaAli (_, p1, p2) -> p_node "PaAli" [p_patt p1; p_patt p2]
      | PaChr (_, s) -> p_node "PaChr" [p_vala p_string s]
      | PaLid (_, s) -> p_node "PaLid" [p_vala p_string s]
      | PaTup (_, pl) -> p_node "PaTup" [p_vala (p_list p_patt) pl]
      | x -> not_impl "p_patt" x
    ;;
    let rec e_expr =
      function
        ExAcc (_, e1, e2) -> e_node "ExAcc" [e_expr e1; e_expr e2]
      | ExApp (_, e1, e2) -> e_node "ExApp" [e_expr e1; e_expr e2]
      | ExAre (_, e1, e2) -> e_node "ExAre" [e_expr e1; e_expr e2]
      | ExArr (_, el) -> e_node "ExArr" [e_vala (e_list e_expr) el]
      | ExAss (_, e1, e2) -> e_node "ExAss" [e_expr e1; e_expr e2]
      | ExAsr (_, e) -> e_node "ExAsr" [e_expr e]
      | ExBae (_, e, el) ->
          e_node "ExBae" [e_expr e; e_vala (e_list e_expr) el]
      | ExChr (_, s) -> e_node "ExChr" [e_vala e_string s]
      | ExCoe (_, e, ot, t) ->
          e_node "ExCoe" [e_expr e; e_option e_ctyp ot; e_ctyp t]
      | ExIfe (_, e1, e2, e3) ->
          e_node "ExIfe" [e_expr e1; e_expr e2; e_expr e3]
      | ExInt (_, s, k) -> e_node "ExInt" [e_vala e_string s; e_string k]
      | ExFlo (_, s) -> e_node "ExFlo" [e_vala e_string s]
      | ExFor (_, i, e1, e2, df, el) ->
          let i = e_vala e_string i in
          let df = e_vala e_bool df in
          let el = e_vala (e_list e_expr) el in
          e_node "ExFor" [i; e_expr e1; e_expr e2; df; el]
      | ExFun (_, pwel) ->
          let pwel =
            e_vala
              (e_list
                 (fun (p, oe, e) ->
                    MLast.ExTup
                      (loc, [e_patt p; e_option e_expr oe; e_expr e])))
              pwel
          in
          e_node "ExFun" [pwel]
      | ExLaz (_, e) -> e_node "ExLaz" [e_expr e]
      | ExLet (_, rf, lpe, e) ->
          let rf = e_vala e_bool rf in
          let lpe =
            e_vala
              (e_list (fun (p, e) -> MLast.ExTup (loc, [e_patt p; e_expr e])))
              lpe
          in
          e_node "ExLet" [rf; lpe; e_expr e]
      | ExLid (_, s) -> e_node "ExLid" [e_vala e_string s]
      | ExLmd (_, i, me, e) ->
          let i = e_vala e_string i in
          let me = e_module_expr me in e_node "ExLmd" [i; me; e_expr e]
      | ExMat (_, e, pwel) ->
          let pwel =
            e_vala
              (e_list
                 (fun (p, oe, e) ->
                    let oe = e_option e_expr oe in
                    MLast.ExTup (loc, [e_patt p; oe; e_expr e])))
              pwel
          in
          e_node "ExMat" [e_expr e; pwel]
      | ExRec (_, lpe, oe) ->
          let lpe =
            e_vala
              (e_list (fun (p, e) -> MLast.ExTup (loc, [e_patt p; e_expr e])))
              lpe
          in
          let oe = e_option e_expr oe in e_node "ExRec" [lpe; oe]
      | ExSeq (_, el) -> e_node "ExSeq" [e_vala (e_list e_expr) el]
      | ExSte (_, e1, e2) -> e_node "ExSte" [e_expr e1; e_expr e2]
      | ExStr (_, s) -> e_node "ExStr" [e_vala e_string s]
      | ExTry (_, e, pwel) ->
          let pwel =
            e_vala
              (e_list
                 (fun (p, oe, e) ->
                    MLast.ExTup
                      (loc, [e_patt p; e_option e_expr oe; e_expr e])))
              pwel
          in
          e_node "ExTry" [e_expr e; pwel]
      | ExTup (_, el) -> e_node "ExTup" [e_vala (e_list e_expr) el]
      | ExTyc (_, e, t) -> e_node "ExTyc" [e_expr e; e_ctyp t]
      | ExUid (_, s) -> e_node "ExUid" [e_vala e_string s]
      | ExWhi (_, e, el) ->
          e_node "ExWhi" [e_expr e; e_vala (e_list e_expr) el]
      | x -> not_impl "e_expr" x
    and p_expr =
      function
        ExAcc (_, e1, e2) -> p_node "ExAcc" [p_expr e1; p_expr e2]
      | ExApp (_, e1, e2) -> p_node "ExApp" [p_expr e1; p_expr e2]
      | ExIfe (_, e1, e2, e3) ->
          p_node "ExIfe" [p_expr e1; p_expr e2; p_expr e3]
      | ExInt (_, s, k) -> p_node "ExInt" [p_vala p_string s; p_string k]
      | ExFlo (_, s) -> p_node "ExFlo" [p_vala p_string s]
      | ExLet (_, rf, lpe, e) ->
          let rf = p_vala p_bool rf in
          let lpe =
            p_vala
              (p_list (fun (p, e) -> MLast.PaTup (loc, [p_patt p; p_expr e])))
              lpe
          in
          p_node "ExLet" [rf; lpe; p_expr e]
      | ExRec (_, lpe, oe) ->
          let lpe =
            p_vala
              (p_list (fun (p, e) -> MLast.PaTup (loc, [p_patt p; p_expr e])))
              lpe
          in
          let oe = p_option p_expr oe in p_node "ExRec" [lpe; oe]
      | ExLid (_, s) -> p_node "ExLid" [p_vala p_string s]
      | ExStr (_, s) -> p_node "ExStr" [p_vala p_string s]
      | ExTup (_, el) -> p_node "ExTup" [p_vala (p_list p_expr) el]
      | ExUid (_, s) -> p_node "ExUid" [p_vala p_string s]
      | x -> not_impl "p_expr" x
    and e_module_type =
      function
        MtAcc (_, mt1, mt2) ->
          e_node "MtAcc" [e_module_type mt1; e_module_type mt2]
      | MtApp (_, mt1, mt2) ->
          e_node "MtApp" [e_module_type mt1; e_module_type mt2]
      | MtFun (_, s, mt1, mt2) ->
          e_node "MtFun"
            [e_vala e_string s; e_module_type mt1; e_module_type mt2]
      | MtLid (_, s) -> e_node "MtLid" [e_vala e_string s]
      | MtQuo (_, s) -> e_node "MtQuo" [e_vala e_string s]
      | MtSig (_, sil) -> e_node "MtSig" [e_vala (e_list e_sig_item) sil]
      | MtUid (_, s) -> e_node "MtUid" [e_vala e_string s]
      | MtWit (_, mt, lwc) ->
          e_node "MtWit" [e_module_type mt; e_vala (e_list e_with_constr) lwc]
    and p_module_type x = not_impl "p_module_type" x
    and e_sig_item =
      function
        SgCls (_, cd) ->
          e_node "SgCls" [e_vala (e_list (e_class_infos e_class_type)) cd]
      | SgClt (_, ctd) ->
          e_node "SgClt" [e_vala (e_list (e_class_infos e_class_type)) ctd]
      | SgDcl (_, lsi) -> e_node "SgDcl" [e_vala (e_list e_sig_item) lsi]
      | SgExc (_, s, lt) ->
          let s = e_vala e_string s in
          let lt = e_vala (e_list e_ctyp) lt in e_node "SgExc" [s; lt]
      | SgExt (_, s, t, ls) ->
          let ls = e_vala (e_list e_string) ls in
          e_node "SgExt" [e_vala e_string s; e_ctyp t; ls]
      | SgInc (_, mt) -> e_node "SgInc" [e_module_type mt]
      | SgMod (_, rf, lsmt) ->
          let lsmt =
            e_vala
              (e_list
                 (fun (s, mt) ->
                    MLast.ExTup (loc, [e_string s; e_module_type mt])))
              lsmt
          in
          e_node "SgMod" [e_vala e_bool rf; lsmt]
      | SgMty (_, s, mt) ->
          e_node "SgMty" [e_vala e_string s; e_module_type mt]
      | SgOpn (_, sl) -> e_node "SgOpn" [e_vala (e_list e_string) sl]
      | SgTyp (_, ltd) -> e_node "SgTyp" [e_vala (e_list e_type_decl) ltd]
      | SgVal (_, s, t) -> e_node "SgVal" [e_vala e_string s; e_ctyp t]
      | x -> not_impl "e_sig_item" x
    and p_sig_item x = not_impl "p_sig_item" x
    and e_with_constr =
      function
        WcTyp (_, li, ltp, pf, t) ->
          let li = e_vala (e_list e_string) li in
          let ltp = e_vala (e_list e_type_var) ltp in
          let pf = e_vala e_bool pf in
          let t = e_ctyp t in e_node "WcTyp" [li; ltp; pf; t]
      | WcMod (_, li, me) ->
          let li = e_vala (e_list e_string) li in
          let me = e_module_expr me in e_node "WcMod" [li; me]
    and p_with_constr x = not_impl "p_with_constr" x
    and e_module_expr =
      function
        MeAcc (_, me1, me2) ->
          e_node "MeAcc" [e_module_expr me1; e_module_expr me2]
      | MeApp (_, me1, me2) ->
          e_node "MeApp" [e_module_expr me1; e_module_expr me2]
      | MeFun (_, s, mt, me) ->
          e_node "MeFun"
            [e_vala e_string s; e_module_type mt; e_module_expr me]
      | MeStr (_, lsi) -> e_node "MeStr" [e_vala (e_list e_str_item) lsi]
      | MeTyc (_, me, mt) ->
          e_node "MeTyc" [e_module_expr me; e_module_type mt]
      | MeUid (_, s) -> e_node "MeUid" [e_vala e_string s]
    and p_module_expr x = not_impl "p_module_expr" x
    and e_str_item =
      function
        StCls (_, cd) ->
          e_node "StCls" [e_vala (e_list (e_class_infos e_class_expr)) cd]
      | StClt (_, ctd) ->
          e_node "StClt" [e_vala (e_list (e_class_infos e_class_type)) ctd]
      | StDcl (_, lsi) -> e_node "StDcl" [e_vala (e_list e_str_item) lsi]
      | StExc (_, s, lt, ls) ->
          let s = e_vala e_string s in
          let lt = e_vala (e_list e_ctyp) lt in
          let ls = e_vala (e_list e_string) ls in e_node "StExc" [s; lt; ls]
      | StExp (_, e) -> e_node "StExp" [e_expr e]
      | StExt (_, s, t, ls) ->
          let ls = e_vala (e_list e_string) ls in
          e_node "StExt" [e_vala e_string s; e_ctyp t; ls]
      | StInc (_, me) -> e_node "StInc" [e_module_expr me]
      | StMod (_, rf, lsme) ->
          let lsme =
            e_vala
              (e_list
                 (fun (s, me) ->
                    MLast.ExTup (loc, [e_string s; e_module_expr me])))
              lsme
          in
          e_node "StMod" [e_vala e_bool rf; lsme]
      | StMty (_, s, mt) ->
          e_node "StMty" [e_vala e_string s; e_module_type mt]
      | StOpn (_, sl) -> e_node "StOpn" [e_vala (e_list e_string) sl]
      | StTyp (_, ltd) -> e_node "StTyp" [e_vala (e_list e_type_decl) ltd]
      | StVal (_, rf, lpe) ->
          let lpe =
            e_vala
              (e_list (fun (p, e) -> MLast.ExTup (loc, [e_patt p; e_expr e])))
              lpe
          in
          e_node "StVal" [e_vala e_bool rf; lpe]
      | x -> not_impl "e_str_item" x
    and p_str_item x = not_impl "p_str_item" x
    and e_type_decl x = not_impl "e_type_decl" x
    and e_class_type =
      function
        CtCon (_, ls, lt) ->
          e_node "CtCon"
            [e_vala (e_list e_string) ls; e_vala (e_list e_ctyp) lt]
      | CtFun (_, t, ct) -> e_node "CtFun" [e_ctyp t; e_class_type ct]
      | CtSig (_, ot, lcsi) ->
          e_node "CtSig"
            [e_vala (e_option e_ctyp) ot;
             e_vala (e_list e_class_sig_item) lcsi]
    and p_class_type x = not_impl "p_class_type" x
    and e_class_sig_item x = not_impl "e_class_sig_item" x
    and p_class_sig_item x = not_impl "p_class_sig_item" x
    and e_class_expr =
      function
        CeApp (_, ce, e) -> e_node "CeApp" [e_class_expr ce; e_expr e]
      | CeCon (_, c, l) ->
          let c = e_vala (e_list e_string) c in
          e_node "CeCon" [c; e_vala (e_list e_ctyp) l]
      | CeFun (_, p, ce) -> e_node "CeFun" [e_patt p; e_class_expr ce]
      | CeLet (_, rf, lb, ce) ->
          e_node "CeLet" [e_vala e_bool rf; e_class_expr ce]
      | CeStr (_, ocsp, lcsi) ->
          let ocsp = e_vala (e_option e_patt) ocsp in
          let lcsi = e_vala (e_list e_class_str_item) lcsi in
          e_node "CeStr" [ocsp; lcsi]
      | CeTyc (_, ce, ct) -> e_node "CeTyc" [e_class_expr ce; e_class_type ct]
    and p_class_expr x = not_impl "p_class_expr" x
    and e_class_str_item =
      function
        CrCtr (_, t1, t2) -> e_node "CrCtr" [e_ctyp t1; e_ctyp t2]
      | CrDcl (_, lcsi) ->
          e_node "CrDcl" [e_vala (e_list e_class_str_item) lcsi]
      | CrInh (_, ce, os) ->
          e_node "CrInh" [e_class_expr ce; e_vala (e_option e_string) os]
      | CrIni (_, e) -> e_node "CrIni" [e_expr e]
      | CrMth (_, s, pf, e, ot) ->
          e_node "CrMth"
            [e_vala e_string s; e_vala e_bool pf; e_expr e;
             e_vala (e_option e_ctyp) ot]
      | CrVal (_, s, rf, e) ->
          e_node "CrVal" [e_vala e_string s; e_vala e_bool rf; e_expr e]
      | CrVir (_, s, pf, t) ->
          e_node "CrVir" [e_vala e_string s; e_vala e_bool pf; e_ctyp t]
    and p_class_str_item x = not_impl "p_class_str_item" x;;
  end
;;

let expr_eoi = Grammar.Entry.create Pcaml.gram "expr";;
let patt_eoi = Grammar.Entry.create Pcaml.gram "patt";;
let ctyp_eoi = Grammar.Entry.create Pcaml.gram "type";;
let str_item_eoi = Grammar.Entry.create Pcaml.gram "str_item";;
let sig_item_eoi = Grammar.Entry.create Pcaml.gram "sig_item";;
let module_expr_eoi = Grammar.Entry.create Pcaml.gram "module_expr";;
let module_type_eoi = Grammar.Entry.create Pcaml.gram "module_type";;
let with_constr_eoi = Grammar.Entry.create Pcaml.gram "with_constr";;
let class_expr_eoi = Grammar.Entry.create Pcaml.gram "class_expr";;
let class_type_eoi = Grammar.Entry.create Pcaml.gram "class_type";;
let class_str_item_eoi = Grammar.Entry.create Pcaml.gram "class_str_item";;
let class_sig_item_eoi = Grammar.Entry.create Pcaml.gram "class_sig_item";;

Grammar.extend
  [Grammar.Entry.obj (expr_eoi : 'expr_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj (Pcaml.expr : 'Pcaml__expr Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__expr) (loc : Ploc.t) -> (x : 'expr_eoi))]];
   Grammar.Entry.obj (patt_eoi : 'patt_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj (Pcaml.patt : 'Pcaml__patt Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__patt) (loc : Ploc.t) -> (x : 'patt_eoi))]];
   Grammar.Entry.obj (ctyp_eoi : 'ctyp_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj (Pcaml.ctyp : 'Pcaml__ctyp Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__ctyp) (loc : Ploc.t) -> (x : 'ctyp_eoi))]];
   Grammar.Entry.obj (sig_item_eoi : 'sig_item_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.sig_item : 'Pcaml__sig_item Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__sig_item) (loc : Ploc.t) -> (x : 'sig_item_eoi))]];
   Grammar.Entry.obj (str_item_eoi : 'str_item_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.str_item : 'Pcaml__str_item Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__str_item) (loc : Ploc.t) -> (x : 'str_item_eoi))]];
   Grammar.Entry.obj (module_expr_eoi : 'module_expr_eoi Grammar.Entry.e),
   None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.module_expr : 'Pcaml__module_expr Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__module_expr) (loc : Ploc.t) ->
          (x : 'module_expr_eoi))]];
   Grammar.Entry.obj (module_type_eoi : 'module_type_eoi Grammar.Entry.e),
   None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.module_type : 'Pcaml__module_type Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__module_type) (loc : Ploc.t) ->
          (x : 'module_type_eoi))]];
   Grammar.Entry.obj (with_constr_eoi : 'with_constr_eoi Grammar.Entry.e),
   None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.with_constr : 'Pcaml__with_constr Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__with_constr) (loc : Ploc.t) ->
          (x : 'with_constr_eoi))]];
   Grammar.Entry.obj (class_expr_eoi : 'class_expr_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.class_expr : 'Pcaml__class_expr Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__class_expr) (loc : Ploc.t) ->
          (x : 'class_expr_eoi))]];
   Grammar.Entry.obj (class_type_eoi : 'class_type_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.class_type : 'Pcaml__class_type Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__class_type) (loc : Ploc.t) ->
          (x : 'class_type_eoi))]];
   Grammar.Entry.obj
     (class_str_item_eoi : 'class_str_item_eoi Grammar.Entry.e),
   None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.class_str_item : 'Pcaml__class_str_item Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__class_str_item) (loc : Ploc.t) ->
          (x : 'class_str_item_eoi))]];
   Grammar.Entry.obj
     (class_sig_item_eoi : 'class_sig_item_eoi Grammar.Entry.e),
   None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.class_sig_item : 'Pcaml__class_sig_item Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__class_sig_item) (loc : Ploc.t) ->
          (x : 'class_sig_item_eoi))]]];;

(* *)

let check_anti_loc s kind =
  try
    let i = String.index s ':' in
    let (j, len) =
      let rec loop j =
        if j = String.length s then i, 0
        else
          match s.[j] with
            ':' -> j, j - i - 1
          | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> loop (j + 1)
          | _ -> i, 0
      in
      loop (i + 1)
    in
    if String.sub s (i + 1) len = kind then
      let loc =
        let k = String.index s ',' in
        let bp = int_of_string (String.sub s 0 k) in
        let ep = int_of_string (String.sub s (k + 1) (i - k - 1)) in
        Ploc.make_unlined (bp, ep)
      in
      loc, String.sub s (j + 1) (String.length s - j - 1)
    else raise Stream.Failure
  with Not_found | Failure _ -> raise Stream.Failure
;;

let check_anti_loc2 s =
  try
    let i = String.index s ':' in
    let (j, len) =
      let rec loop j =
        if j = String.length s then i, 0
        else
          match s.[j] with
            ':' -> j, j - i - 1
          | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> loop (j + 1)
          | _ -> i, 0
      in
      loop (i + 1)
    in
    String.sub s (i + 1) len
  with Not_found | Failure _ -> raise Stream.Failure
;;

let lex = Grammar.glexer Pcaml.gram in
let tok_match = lex.Plexing.tok_match in
lex.Plexing.tok_match <-
  function
    "ANTIQUOT_LOC", p_prm ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = p_prm then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V INT", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aint" || kind = "int" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V INT_l", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aint32" || kind = "int32" then prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V INT_L", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aint64" || kind = "int64" then prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V INT_n", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "anativeint" || kind = "nativeint" then prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V FLOAT", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aflo" || kind = "flo" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V LIDENT", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "alid" || kind = "lid" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V UIDENT", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "auid" || kind = "uid" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V STRING", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "astr" || kind = "str" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V CHAR", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "achr" || kind = "chr" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V LIST", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "alist" || kind = "list" then prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V OPT", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aopt" || kind = "opt" then prm else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V FLAG", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aflag" || kind = "flag" then prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | tok -> tok_match tok;;

(* reinit the entry functions to take the new tok_match into account *)
Grammar.iter_entry Grammar.reinit_entry_functions
  (Grammar.Entry.obj Pcaml.expr);;

let apply_entry e me mp =
  let f s =
    call_with Plexer.force_antiquot_loc true (Grammar.Entry.parse e)
      (Stream.of_string s)
  in
  let expr s = me (f s) in
  let patt s = mp (f s) in Quotation.ExAst (expr, patt)
;;

List.iter (fun (q, f) -> Quotation.add q f)
  ["expr", apply_entry expr_eoi Meta.e_expr Meta.p_expr;
   "patt", apply_entry patt_eoi Meta.e_patt Meta.p_patt;
   "ctyp", apply_entry ctyp_eoi Meta.e_ctyp Meta.p_ctyp;
   "str_item", apply_entry str_item_eoi Meta.e_str_item Meta.p_str_item;
   "sig_item", apply_entry sig_item_eoi Meta.e_sig_item Meta.p_sig_item;
   "module_expr",
   apply_entry module_expr_eoi Meta.e_module_expr Meta.p_module_expr;
   "module_type",
   apply_entry module_type_eoi Meta.e_module_type Meta.p_module_type;
   "with_constr",
   apply_entry with_constr_eoi Meta.e_with_constr Meta.p_with_constr;
   "class_expr",
   apply_entry class_expr_eoi Meta.e_class_expr Meta.p_class_expr;
   "class_type",
   apply_entry class_type_eoi Meta.e_class_type Meta.p_class_type;
   "class_str_item",
   apply_entry class_str_item_eoi Meta.e_class_str_item Meta.p_class_str_item;
   "class_sig_item",
   apply_entry class_sig_item_eoi Meta.e_class_sig_item
     Meta.p_class_sig_item];;

let expr s =
  let e =
    call_with Plexer.force_antiquot_loc true
      (Grammar.Entry.parse Pcaml.expr_eoi) (Stream.of_string s)
  in
  let loc = Ploc.make_unlined (0, 0) in
  if !(Pcaml.strict_mode) then
    MLast.ExApp
      (loc,
       MLast.ExAcc
         (loc, MLast.ExUid (loc, "Ploc"), MLast.ExUid (loc, "VaVal")),
       MLast.ExAnt (loc, e))
  else MLast.ExAnt (loc, e)
in
let patt s =
  let p =
    call_with Plexer.force_antiquot_loc true
      (Grammar.Entry.parse Pcaml.patt_eoi) (Stream.of_string s)
  in
  let loc = Ploc.make_unlined (0, 0) in
  if !(Pcaml.strict_mode) then
    MLast.PaApp
      (loc,
       MLast.PaAcc
         (loc, MLast.PaUid (loc, "Ploc"), MLast.PaUid (loc, "VaVal")),
       MLast.PaAnt (loc, p))
  else MLast.PaAnt (loc, p)
in
Quotation.add "vala" (Quotation.ExAst (expr, patt));;
