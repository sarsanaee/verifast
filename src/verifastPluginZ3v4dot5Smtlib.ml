module Z = Z3v4dot5prover
module Zn = Z3native
module Sp = Smtlibprover
module S = Smtlib
module P = Proverapi
module C = Combineprovers

(* Disabled for now, can't figure out how to write a print term function --Solal
let _ =
  Verifast.register_prover "Z3v4.5+SMTLib"
    "(experimental) run Z3 version 4.5 and dump the session to a file in SMTLib format."
    (
      fun client ->
      let z3_ctxt =
        (new Z.z3_context():
           Z.z3_context :> (Zn.sort, Zn.func_decl, Zn.ast) P.context)
      in
      let smtlib_ctxt =
        Sp.dump_smtlib_ctxt
          "z3_v4dot5_dump.smt2"
          ["dump"; "I"; "Q"; "NDT"; "LIA"; "LRA"]
      in
      client#run (C.combine z3_ctxt smtlib_ctxt C.Sync)
    )
*)
