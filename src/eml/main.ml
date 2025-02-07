(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Command_line :
sig
  val parse : unit -> (string * string) list
end =
struct
  let usage = {|Usage:

  eml FILE
|}

  let input_files =
    ref []

  let workspace_path =
    ref ""

  let options = Arg.align [
    "--workspace",
    Arg.Set_string workspace_path,
    "PATH Relative path to the Dune workspace for better locations";
  ]

  let set_file file =
    input_files := file::!input_files

  let parse () =
    Arg.parse options set_file usage;

    if !input_files = [] then begin
      Arg.usage options usage;
      exit 2
    end;
    let input_files = !input_files in

    let rec build_prefix location prefix path =
      match Filename.basename path with
      | component when component = Filename.parent_dir_name ->
        let directory = Filename.basename location in
        build_prefix
          (Filename.dirname location)
          (Filename.concat directory prefix)
          (Filename.dirname path)
      | "" | "." ->
        prefix
      | s ->
        prerr_endline s;
        Printf.ksprintf failwith
          "The workspace path may contain only %s components"
          Filename.parent_dir_name
    in
    let prefix = build_prefix (Sys.getcwd ()) "" !workspace_path in

    input_files
    |> List.map (fun file -> file, Filename.concat prefix file)
end

let () =
  Command_line.parse ()
  |> List.iter Eml.process_file
