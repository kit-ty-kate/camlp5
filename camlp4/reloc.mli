(* camlp4r *)
(***********************************************************************)
(*                                                                     *)
(*                             Camlp4                                  *)
(*                                                                     *)
(*                Daniel de Rauglaudre, INRIA Rocquencourt             *)
(*                                                                     *)
(*  Copyright 2007 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

(* $Id$ *)

value patt : (MLast.loc -> MLast.loc) -> int -> MLast.patt -> MLast.patt;
value expr : (MLast.loc -> MLast.loc) -> int -> MLast.expr -> MLast.expr;