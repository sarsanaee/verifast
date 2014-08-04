open Lexer
open Ast

open Ast_writer

let load _ =
  let launch = 
    try Sys.getenv "VERIFAST_JAVA_AST_SERVER"  
    with Not_found ->
      let ast_server_filename = "ast_server-415b386.jar" in
      let error_message =
        "\nYou specified the option -javac to use the STANCE Java frontend. " ^
        Printf.sprintf "However, to use the STANCE Java frontend, you need to retrieve the file %s from: \n" ast_server_filename ^
            "\t https://bitbucket.org/gijsv/stance-java-frontend \n" ^
        "Then you must set the environment variable VERIFAST_JAVA_AST_SERVER as follows: \n" ^
            Printf.sprintf "\t export VERIFAST_JAVA_AST_SERVER=\"java -jar path/to/%s\" \n" ast_server_filename
      in
      Printf.printf "%s" error_message;
      failwith error_message
  in
  Java_frontend.attach(launch)

let unload _ =
  Java_frontend.detach()

let found_java_spec_files = ref []

let build_context paths jars = 
  let rec recurse_specs javaspecs jars =
    match jars with
    | j::rest ->
(*         Printf.printf "\nLooking at jar file %s\n" j; *)
        let jar = (Filename.chop_extension j) ^ ".jarspec" in
        let (jars, specs) = Parser.parse_jarspec_file_core jar in
(*        List.iter (fun p -> Printf.printf "Found jars --------> %s\n" p) jars;
        List.iter (fun p -> Printf.printf "Found javas   --------> %s\n" p) specs;*)
        let path_dir = Filename.dirname jar in
        let jars = (List.map (Util.concat path_dir) jars) in
        let specs = (List.map (Util.concat path_dir) specs) in
(*        List.iter (fun p -> Printf.printf "Selected jarsrc --------> %s\n" p) jars;
        List.iter (fun p -> Printf.printf "Selected spec   --------> %s\n" p) specs;*)
        let check_dup l =
          match l with 
          | [] -> false
          | x::rest -> List.mem x rest
        in
        if check_dup jars then
          raise (ParseException (dummy_loc, "Include cycle in jarspec files"));
        recurse_specs (specs @ javaspecs) (jars @ rest)
    | [] -> javaspecs
  in
  recurse_specs [] jars

let parse_java_files_with_frontend (paths: string list) (jars: string list) (reportRange: range_kind -> loc -> unit) reportShouldFail: package list =
  let (rt_paths, paths) =
    List.partition (fun p -> Filename.dirname p = Util.rtdir) paths
  in
  let context_new = build_context paths jars in
  found_java_spec_files := Util.list_remove_dups (!found_java_spec_files @ context_new);
  let context_for_paths = List.filter (fun x -> not (List.mem ((Filename.chop_extension x) ^ ".javaspec") paths)) !found_java_spec_files in
  let context_for_paths = List.filter (fun x -> not (List.mem ((Filename.chop_extension x) ^ ".java") paths)) context_for_paths in
(*  Printf.printf "\n----------------------------------\n%s\n" "-Buildup context:";
  List.iter (fun p -> Printf.printf "- -> %s\n" p) !found_java_spec_files;
  Printf.printf "Using context: %s\n" "";
  List.iter (fun p -> Printf.printf "- -> %s\n" p) context_for_paths;
  Printf.printf "----------------------------------\n\n%s" "";*)
  let result =
    match paths with
    | [] -> []
    | _ ->
      if not (Java_frontend.is_attached ()) then load();
        let ann_checker = new Annotation_type_checker.dummy_ann_type_checker () in
        let packages = 
          try
            let options = 
              [Java_frontend.desugar; 
              Java_frontend.keep_assertions;
              Java_frontend.keep_super_call_first;
              Java_frontend.bodyless_methods_own_trailing_annotations;
              Java_frontend.accept_spec_files]
            in
            Java_frontend.asts_from_java_files paths ~context:context_for_paths options ann_checker
          with
            Java_frontend.JavaFrontendException(l, m) -> 
              let message = 
                String.concat " |" (Misc.split_string '\n' m)
              in
              match l with
              | General_ast.NoSource -> raise (Parser.CompilationError message)
              | _ -> raise (Lexer.ParseException(Ast_translator.translate_location l, message))
        in
        let annotations = ann_checker#retrieve_annotations () in
        Ast_translator.translate_asts packages annotations
   in
   (List.map (fun x -> Parser.parse_java_file_old x reportRange reportShouldFail) rt_paths) @ result 

let parse_java_files (paths: string list) (jars: string list) (reportRange: range_kind -> loc -> unit) reportShouldFail use_java_frontend: package list =
(*  Printf.printf "\n++++++++++++++++++++++++++++++++++\n%s\n" "+Parsing files:";
  List.iter (fun p -> Printf.printf "+ -> %s\n" p) paths;
  Printf.printf "+\n%s\n" "+With jars:";
  List.iter (fun p -> Printf.printf "+ -> %s\n" p) jars;
  Printf.printf "++++++++++++++++++++++++++++++++++\n\n%s" "";*)
  if use_java_frontend then
    parse_java_files_with_frontend paths jars reportRange reportShouldFail
  else
    List.map (fun x -> Parser.parse_java_file_old x reportRange reportShouldFail) paths

