module R = Redux
module Sp = Smtlibprover
module S = Smtlib
module P = Proverapi
module C = Combineprovers

(* Disabled for now, can't figure out how to put a print term function --Solal
let _ =
  Verifast.register_prover "Redux+SMTLib"
    "(experimental) run Redux and dump the session to a file in SMTLib format."
    (
      fun client ->
      let redux_ctxt =
        (new R.context ():
           R.context :> (unit, R.symbol, (R.symbol, R.termnode) R.term) P.context)
      in
      let smtlib_ctxt =
        Sp.dump_smtlib_ctxt
          "redux_dump.smt2"
          ["dump"; "I"; "Q"; "NDT"; "LIA"; "LRA"]
      in
      client#run (C.combine redux_ctxt smtlib_ctxt C.Sync)
    )
*)
