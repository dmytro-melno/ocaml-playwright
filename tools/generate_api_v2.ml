(* [@@@ocaml.warning "-37-27-32-69-33"] *)
[@@@ocaml.warning "-69"]

module Types = struct
    type type_ =
        | Optional of type_
        | StringType
        | IntType
        | FloatType
        | BooleanType
        | BinaryType
        | JsonType
        | AnyType
        | ObjectType of object_
        | ArrayType of array_
        | EnumType of enum_
        | TypeRef of string
    and object_ = {
        properties : (string * type_) list;
    }
    and enum_ = {
        literals : string list;
    }
    and array_ = {
        of_type : type_;
    }

    type command = {
        name : string;
        title : string option;
        parameters : object_;
        returns : object_;
    }
    type event = {
        name : string;
        parameters : object_;
    }
    type interface_ = {
        extends : string option;
        initializer_ : object_ option;
        commands : command list;
        events : event list;
    }

    type top_typedef =
        | Object of object_
        | Enum of enum_
    type root = {
        top_defs : (string * top_typedef) list;
        interfaces : (string * interface_) list
    }
end

module Parser = struct
    let failwithf fmt = Printf.ksprintf failwith fmt

    let get_dict = function
        | `O d -> d
        | `Null -> []
        | _ -> failwith "Expected dict"

    let opt_dict k d =
        match List.assoc_opt k d with
        | Some (`O v) -> v
        | Some `Null | None -> []
        | _ -> failwithf "Expected dict for key %s" k

    let opt_string k d =
        match List.assoc_opt k d with
        | Some (`String v) -> Some v
        | _ -> None

    let rec parse_type env _name v =
        let make_opt is_opt t = if is_opt then Types.Optional t else t in
        match v with
        | `String s ->
            let s = String.trim s in
            let is_opt = String.ends_with ~suffix:"?" s in
            let base = if is_opt then String.sub s 0 (String.length s - 1) else s in
            let t = match base with
                | "string" -> Types.StringType
                | "int" -> Types.IntType
                | "float" -> Types.FloatType
                | "boolean" -> Types.BooleanType
                | "binary" -> Types.BinaryType
                | "json" -> Types.JsonType
                | "any" -> Types.AnyType
                | other -> Types.TypeRef other
            in
            make_opt is_opt t
        | `O d ->
            let type_str = opt_string "type" d |> Option.value ~default:"object" in
            let is_opt = String.ends_with ~suffix:"?" type_str in
            let base = if is_opt then String.sub type_str 0 (String.length type_str - 1) else type_str in
            let t = match base with
                | "object" -> Types.ObjectType (parse_object env d)
                | "array" -> Types.ArrayType { of_type = parse_type env "items" (List.assoc "items" d) }
                | "enum" ->
                    let literals =
                        match List.assoc_opt "literals" d with
                        | Some (`A l) ->
                            l |> List.map (function
                                | `String s -> s
                                | `Float f ->
                                    let s = string_of_float f in
                                    if String.ends_with ~suffix:"." s then String.sub s 0 (String.length s - 1) else s
                                | `Null -> "null"
                                | _ -> failwith "unknown literal"
                            )
                        | _ -> []
                    in
                    Types.EnumType { literals }
                | _ -> failwithf "Unknown complex type: %s" base
            in
            make_opt is_opt t
        | _ -> failwith "Expected string or dict for type"

    and parse_properties env props_d =
        let rec resolve_props d =
            d |> List.concat_map (fun (k, v) ->
                if String.starts_with ~prefix:"$mixin" k then
                    let mixin_name = match v with `String s -> s | _ -> failwith "mixin expected string" in
                    let mixin_props = match List.assoc_opt mixin_name env with Some p -> p | None -> failwithf "mixin %s not found" mixin_name in
                    resolve_props mixin_props
                else
                    [(k, v)]
            )
        in
        let resolved_props = resolve_props props_d in
        let properties = resolved_props |> List.map (fun (k, v) -> (k, parse_type env k v)) in
        { Types.properties }

    and parse_object env d =
        parse_properties env (opt_dict "properties" d)

    let parse_command env name d =
        let title = opt_string "title" d in
        let parameters = parse_properties env (opt_dict "parameters" d) in
        let returns = parse_properties env (opt_dict "returns" d) in
        { Types.name; title; parameters; returns }

    let parse_event env name d =
        let parameters = parse_properties env (opt_dict "parameters" d) in
        { Types.name; parameters }

    let parse_initializer env d =
        match List.assoc_opt "initializer" d with
        | Some (`O init) -> Some (parse_properties env init)
        | _ -> None

    let parse_top_typedef env _name d =
        let type_str = opt_string "type" d |> Option.value ~default:"object" in
        match type_str with
        | "object" -> Some (Types.Object (parse_object env d))
        | "enum" ->
            let literals =
                match List.assoc_opt "literals" d with
                | Some (`A l) ->
                    l |> List.map (function
                        | `String s -> s
                        | `Float f ->
                            let s = string_of_float f in
                            if String.ends_with ~suffix:"." s then String.sub s 0 (String.length s - 1) else s
                        | `Null -> "null"
                        | _ -> failwith "unknown literal"
                    )
                | _ -> []
            in
            Some (Types.Enum { literals })
        | "interface"
        | "mixin" -> None
        | _ -> failwithf "Unknown top-level type: %s" type_str

    let parse_interface env _name d =
        if opt_string "type" d = Some "interface" then
            let extends = opt_string "extends" d in
            let initializer_ = parse_initializer env d in
            let commands = opt_dict "commands" d |> List.map (fun (k, v) -> parse_command env k (get_dict v)) in
            let events = opt_dict "events" d |> List.map (fun (k, v) -> parse_event env k (get_dict v)) in
            Some (Types.{ extends; initializer_; commands; events })
        else None

    let parse content =
        let yaml = Yaml.of_string_exn content in
        let top_dict = get_dict yaml in

        let mixins =
            top_dict |> List.filter_map (fun (name, v) ->
                let d = get_dict v in
                if opt_string "type" d = Some "mixin" then
                    Some (name, opt_dict "properties" d)
                else None
            )
        in

        let interfaces =
            top_dict |> List.filter (fun (_name, v) ->
                opt_string "type" (get_dict v) = Some "interface"
            )
        in

        let top_defs =
            top_dict |> List.filter_map (fun (name, v) ->
                let d = get_dict v in
                Option.map (fun def -> (name, def)) (parse_top_typedef mixins name d)
            )
        in
        let interfaces =
            interfaces |> List.filter_map (fun (name, v) ->
                let d = get_dict v in
                Option.map (fun def -> (name, def)) (parse_interface mixins name d)
            )
        in
        Types.{ top_defs; interfaces }
end

module Render = struct
    open Printf

    let to_ocaml_name ?(is_type=false) s =
        let is_upper c = c >= 'A' && c <= 'Z' in
        let to_lower c = Char.lowercase_ascii c in
        let buf = Buffer.create (String.length s * 2) in
        s |> String.iteri (fun i c ->
            if is_upper c then (
            if i > 0 && s.[i-1] <> '_' && s.[i-1] <> '-' &&
                not (is_upper s.[i-1] && (i+1 = String.length s || is_upper s.[i+1])) then
                Buffer.add_char buf '_';
            Buffer.add_char buf (to_lower c)
            ) else if c = '-' || c = '$' || c = '.' || c = '@' || c = '{' || c = '}' || c = '|' || c = '"' || c = ' ' then Buffer.add_char buf '_'
            else Buffer.add_char buf c
        );
        let res = Buffer.contents buf in
        let res = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
        let res = Re.replace_string (Re.Pcre.regexp "^_+") ~by:"" res in
        let res = Re.replace_string (Re.Pcre.regexp "_+$") ~by:"" res in
        let res = if is_type && String.length res > 0 && res.[0] >= 'A' && res.[0] <= 'Z' then
            String.lowercase_ascii (String.sub res 0 1) ^ String.sub res 1 (String.length res - 1)
        else res in
        match res with
        | "type" | "object" | "class" | "end" | "begin" | "in" | "let" | "match" | "with" | "open" | "include"
        | "function" | "method" | "val" | "virtual" | "constraint" | "exception" | "module" | "sig" | "struct"
        | "fun" | "rec" | "mutable" | "private" | "new" | "to" | "downto" | "lazy" | "assert" | "and" | "if"
        | "then" | "else" | "do" | "do_" | "done" | "while" | "for" | "try" | "as" | "when" -> res ^ "_"
        | _ -> res

    let to_ocaml_variant_name s =
        if s = "-inf" then "Minus_inf" else
        if s = "-0" then "Minus_zero" else
        let s = to_ocaml_name ~is_type:false s in
        if s = "" then "Empty" else
        if s.[0] >= '0' && s.[0] <= '9' then "V_" ^ s else
        String.capitalize_ascii s

    let make_yojson_functions_for_variant literals =
        let yojson_sigs = "    val of_yojson : Yojson.Safe.t -> (t, string) result\n    val to_yojson : t -> Yojson.Safe.t" in
        let out_buf = Buffer.create 0x100 in
        let w fmt = bprintf out_buf fmt in
        w "    let to_yojson = function\n";
        literals |> List.iter (fun lit ->
            w "        | `%s -> `String \"%s\"" (to_ocaml_variant_name lit) lit
        );
        w "    let of_yojson = function\n";
        literals |> List.iter (fun lit ->
            w "        | `String \"%s\" -> Ok `%s" lit (to_ocaml_variant_name lit)
        );
        w "        | _ -> Error \"invalid variant\"";
        yojson_sigs, Buffer.contents out_buf

    let rec inline_type_ name ty (acc : (string * string * string) list) : (string * string * string) list * string =
        let open Types in
        match ty with
        | StringType -> acc, "string"
        | IntType -> acc, "int"
        | FloatType -> acc, "float"
        | BooleanType -> acc, "bool"
        | BinaryType -> acc, "string"
        | JsonType -> acc, "Yojson.Safe.t"
        | AnyType -> acc, "Yojson.Safe.t"
        | ObjectType {properties} ->
            let name = String.capitalize_ascii name in
            let ty_name = sprintf "%s.t" name in
            let tymod_name = sprintf "%s" name in
            (object_ tymod_name properties acc), ty_name
        | ArrayType {of_type} ->
            let acc, ty_name = inline_type_ name of_type acc in
            acc, sprintf "%s array" ty_name
        | EnumType {literals} ->
            let name = String.capitalize_ascii name in
            let ty_name = sprintf "%s.t" name in
            let tymod_name = sprintf "%s" name in
            (enum_ tymod_name literals acc), ty_name
        | TypeRef ty_name -> acc, sprintf "%s.t" ty_name
        | Optional ty ->
            let acc, ty_name = inline_type_ name ty acc in
            acc, sprintf "%s option" ty_name
    and object_ ty_name properties acc =
        let acc, fields = object_body properties acc in
        let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in
        (ty_name, ty_body, ty_body) :: acc
    and enum_ ty_name (literals : string list) acc =
        let ctors_decl = literals |> List.map (fun literal -> sprintf "        | `%s" (to_ocaml_variant_name literal)) |> String.concat "\n" in
        let yojson_sigs, yojson_defs = make_yojson_functions_for_variant literals in
        let ty_body_sig = sprintf "[\n%s\n    ]\n%s\n" ctors_decl yojson_sigs in
        let ty_body_struct = sprintf "[\n%s\n    ]\n%s\n" ctors_decl yojson_defs in
        (ty_name, ty_body_sig, ty_body_struct) :: acc
    and object_body properties acc =
        let acc, fields =
            properties |> List.fold_left_map (fun acc (name, ty) ->
                let is_opt, ty = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                let acc, ty_name = inline_type_ name ty acc in
                let opt_attr = if is_opt then sprintf " [@default None]" else "" in
                let ty_name = if is_opt then ty_name ^ " option" else ty_name in
                acc, sprintf "        %s : %s [@key \"%s\"]%s;" (to_ocaml_name name) ty_name name opt_attr
            ) acc
        in
        let fields = fields |> String.concat "\n" in
        acc, fields
    and enum_body (literals : string list) acc =
        let ctors = literals |> List.map (fun literal -> sprintf "        `%s [@name \"%s\"]" (to_ocaml_variant_name literal) literal) |> String.concat "\n        | " in
        acc, ctors

    let arg_type (arg_name : string) (ty : Types.type_) acc =
        let open Types in
        let is_opt, ty = match ty with | Optional ty -> true, ty | ty -> false, ty in
        let acc, ty_name = inline_type_ arg_name ty acc in
        acc, ty_name, is_opt
    let args_types properties =
        properties |> List.fold_left_map (fun acc (name, ty) ->
            let ocaml_name = to_ocaml_name name in
            let acc, ty_name, is_opt = arg_type ocaml_name ty acc in
            acc, (name, ocaml_name, ty_name, is_opt)
        ) []

    (* let is_positional arg_name = match arg_name with "url" | "selector" | "text" | "expression" | "value" -> true | _ -> false *)
    let is_positional _arg_name = false

    module Sig = struct
        let interface interfaces interface_name (interface : Types.interface_) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            let local_defs_names = ref [] in
            interface.initializer_ |> (function
                | Some {Types.properties} ->
                    let local_type_defs, def_body = object_body properties [] in
                    let local_type_defs =
                        local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                            if List.mem ty_name !local_defs_names then None else (
                                local_defs_names := ty_name :: !local_defs_names;
                                Some (ty_name, ty_body_sig, ty_body_struct)
                            )
                        )
                    in
                    let local_type_defs =
                        let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]\n" def_body in
                        ("Initializer", ty_body, ty_body) :: local_type_defs
                    in
                    let local_type_def_mods =
                        local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, _ty_body_struct) ->
                            if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end\n" ty_name ty_body_sig
                            else sprintf "    and %s : sig type t = %s\n    end\n" ty_name ty_body_sig) |> String.concat "\n"
                    in
                    w "%s" local_type_def_mods;

                    w "    type %s_t\n" (to_ocaml_name interface_name);
                    w "    type t = %s_t obj\n" (to_ocaml_name interface_name);
                    w "    val to_yojson : t -> Yojson.Safe.t\n";
                    w "    val of_yojson : Yojson.Safe.t -> (t, string) result\n\n";


                    w "    (* Initializer getters *)\n";
                    properties |> List.iter (fun (field_name, ty) ->
                        let is_opt, ty_inner = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                        match ty_inner with
                        | Types.TypeRef t when List.mem_assoc t interfaces ->
                            let field_name_ocaml = to_ocaml_name field_name in
                            let ty_name_out = if is_opt then sprintf "%s.t option" t else sprintf "%s.t" t in
                            w "    val %s : t -> %s\n" field_name_ocaml ty_name_out
                        | _ -> ()
                    );
                | None ->

                    w "    type %s_t\n" (to_ocaml_name interface_name);
                    w "    type t = %s_t obj\n" (to_ocaml_name interface_name);
                    w "    val to_yojson : t -> Yojson.Safe.t\n";
                    w "    val of_yojson : Yojson.Safe.t -> (t, string) result\n\n";

            );
            w "\n";
            let rec get_all_commands iface =
                let base_cmds = match iface.Types.extends with
                    | Some base_name ->
                        (match List.assoc_opt base_name interfaces with
                        | Some base_iface -> get_all_commands base_iface
                        | None -> [])
                    | None -> []
                in
                base_cmds @ iface.Types.commands
            in
            let rec get_all_events iface =
                let base_events = match iface.Types.extends with
                    | Some base_name ->
                        (match List.assoc_opt base_name interfaces with
                        | Some base_iface -> get_all_events base_iface
                        | None -> [])
                    | None -> []
                in
                base_events @ iface.Types.events
            in
            w "    (* Events *)\n";
            get_all_events interface |> List.iter (fun (ev : Types.event) ->
                let fn_name = "on_" ^ to_ocaml_name ev.name in
                let wait_fn_name = "wait_for_" ^ to_ocaml_name ev.name in

                let local_type_defs, args = args_types ev.parameters.properties in
                let has_params = (List.length args > 0) in

                if has_params then begin
                    let ty_name = sprintf "%sEvent" (String.capitalize_ascii ev.name) in
                    let local_type_defs, fields = object_body ev.parameters.properties local_type_defs in
                    let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in
                    let local_type_defs = (ty_name, ty_body, ty_body) :: local_type_defs in

                    let local_type_defs =
                        local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                            if List.mem ty_name !local_defs_names then None else (
                                local_defs_names := ty_name :: !local_defs_names;
                                Some (ty_name, ty_body_sig, ty_body_struct)
                            )
                        )
                    in

                    let local_type_def_mods =
                        local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, _ty_body_struct) ->
                            if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end\n" ty_name ty_body_sig
                            else sprintf "    and %s : sig type t = %s\n    end\n" ty_name ty_body_sig) |> String.concat "\n"
                    in
                    if local_type_defs <> [] then (
                        w "\n%s\n" local_type_def_mods;
                    );

                    let arg_ty_name = sprintf "%s.t" ty_name in
                    w "    val %s : t -> (%s -> unit) -> unit\n" fn_name arg_ty_name;
                    w "    val %s : ?predicate:(%s -> bool) -> t -> %s\n" wait_fn_name arg_ty_name arg_ty_name;
                end else begin
                    w "    val %s : t -> (unit -> unit) -> unit\n" fn_name;
                    w "    val %s : t -> unit\n" wait_fn_name;
                end
            );
            w "    (* Commands *)\n";
            get_all_commands interface |> List.iter (fun (cmd : Types.command) ->
                let local_type_defs, args = args_types cmd.parameters.properties in
                let args_sig =
                    args |> List.map (fun (orig_name, name, ty, is_opt) ->
                        let is_opt = is_opt || orig_name = "timeout" in
                        let is_pos = is_positional orig_name in
                        if is_opt then sprintf "?%s:%s" name ty
                        else if is_pos then ty
                        else sprintf "%s:%s" name ty
                    ) |> String.concat " -> "
                in
                let local_type_defs, res_t = match cmd.returns.properties with
                    | [] -> local_type_defs, "unit"
                    | [name, ty] ->
                        let local_type_defs, ty_name = inline_type_ name ty local_type_defs in
                        local_type_defs, ty_name
                    | properties ->
                        let ty_name = sprintf "%sResult" (String.capitalize_ascii cmd.name) in
                        let acc, fields = object_body properties local_type_defs in
                        let local_type_defs = let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in (ty_name, ty_body, ty_body) :: acc in
                        local_type_defs, (sprintf "%s.t" ty_name)
                in
                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body_sig, ty_body_struct)
                        )
                    )
                in
                let local_type_def_mods =
                    local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, _ty_body_struct) ->
                        if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end\n" ty_name ty_body_sig
                        else sprintf "    and %s : sig type t = %s\n    end\n" ty_name ty_body_sig) |> String.concat "\n"
                in
                if local_type_defs <> [] then (
                    w "\n";
                    w "%s\n" local_type_def_mods;
                );
                let args_sig = if args_sig <> "" then sprintf "%s -> t" args_sig else "t" in
                let fn_name = to_ocaml_name cmd.name in
                let fn_name_raw = if fn_name = "evaluate_expression" || fn_name = "eval_on_selector" || fn_name = "eval_on_selector_all" || fn_name = "evaluate_expression_handle" || fn_name = "wait_for_function" || fn_name = "json_value" || fn_name = "dispatch_event" || fn_name = "expect" || fn_name = "reject" || fn_name = "resolve" then fn_name ^ "_raw" else fn_name in
                w "    val %s : %s -> %s\n" fn_name_raw args_sig res_t;
            );
            if interface_name = "Page" then begin
                w "\n    (* Frame Proxy Commands *)\n";
                let frame_iface = List.assoc "Frame" interfaces in
                let rec get_all_commands iface =
                    let base_cmds = match iface.Types.extends with
                        | Some base_name ->
                            (match List.assoc_opt base_name interfaces with
                            | Some base_iface -> get_all_commands base_iface
                            | None -> [])
                        | None -> []
                    in
                    base_cmds @ iface.Types.commands
                in
                let page_cmds = get_all_commands interface |> List.map (fun (c : Types.command) -> c.name) in
                let proxy_cmds = get_all_commands frame_iface |> List.filter (fun (c : Types.command) -> not (List.mem c.name page_cmds)) in
                proxy_cmds |> List.iter (fun (cmd : Types.command) ->
                    let local_type_defs_args, args = args_types cmd.parameters.properties in
                    let local_type_defs_ret, _res_t = match cmd.returns.properties with
                        | [] -> [], "unit"
                        | [name, ty] -> inline_type_ name ty []
                        | properties ->
                            let ty_name = sprintf "%sResult" (String.capitalize_ascii cmd.name) in
                            let acc, _fields = object_body properties [] in
                            (ty_name, "", "") :: acc, ""
                    in
                    let local_names = (local_type_defs_args @ local_type_defs_ret) |> List.map (fun (n,_,_) -> n) in
                    let fix_ty ty =
                        List.fold_left (fun acc loc ->
                            let rex = Re.compile (Re.str (loc ^ ".t")) in
                            Re.replace_string rex ~by:("Frame." ^ loc ^ ".t") acc
                        ) ty local_names
                    in
                    let args_sig =
                        args |> List.map (fun (orig_name, name, ty, is_opt) ->
                            let ty = fix_ty ty in
                            let is_opt = is_opt || orig_name = "timeout" in
                            let is_pos = is_positional orig_name in
                            if is_opt then sprintf "?%s:%s" name ty
                            else if is_pos then ty
                            else sprintf "%s:%s" name ty
                        ) |> String.concat " -> "
                    in
                    let res_t = match cmd.returns.properties with
                        | [] -> "unit"
                        | [name, ty] -> let _, ty_name = inline_type_ name ty [] in fix_ty ty_name
                        | _properties ->
                            let ty_name = sprintf "%sResult" (String.capitalize_ascii cmd.name) in
                            fix_ty (sprintf "%s.t" ty_name)
                    in
                    let args_sig = if args_sig <> "" then sprintf "%s -> t" args_sig else "t" in
                    let fn_name = to_ocaml_name cmd.name in
                    let fn_name_raw = if fn_name = "evaluate_expression" || fn_name = "eval_on_selector" || fn_name = "eval_on_selector_all" || fn_name = "evaluate_expression_handle" || fn_name = "wait_for_function" || fn_name = "json_value" || fn_name = "dispatch_event" || fn_name = "expect" || fn_name = "reject" || fn_name = "resolve" then fn_name ^ "_raw" else fn_name in
                    w "    val %s : %s -> %s\n" fn_name_raw args_sig res_t;
                );
            end
        let render (root : Types.root) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            w "[@@@ocaml.warning \"-30-39-32\"]\n\n";
            w "exception Error of string\n\n";
            w "type 'a obj = { conn: Connection.t; guid: string }\n";
            
            
            w "module Channel : sig type t = { guid: string } [@@deriving yojson {strict = false}] end\n";
            root.top_defs |> List.iter (fun (name, def) ->
                let local_type_defs, def_body = match def with
                    | Types.Object {properties} ->
                        let local_type_defs, fields = object_body properties [] in
                        let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in
                        local_type_defs, ty_body
                    | Types.Enum {literals} ->
                        let local_type_defs, ctors = enum_body literals [] in
                        let yojson_sigs, _yojson_defs = make_yojson_functions_for_variant literals in
                        let ty_body_sig = sprintf "[\n%s\n    ]\n%s\n" ctors yojson_sigs in
                        local_type_defs, ty_body_sig
                in
                let def_body = def_body |> Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" in
                let local_defs_names = ref [] in
                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, _ty_body_struct) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body_sig)
                        )
                    )
                    |> List.map (fun (ty_name, ty_body_sig) -> ty_name, Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"Wrap.t" ty_body_sig)
                    |> List.map (fun (ty_name, ty_body_sig) -> ty_name, ty_body_sig)
                in
                w "module %s : sig\n" name;
                let local_type_defs = ("Wrap", def_body) :: local_type_defs in
                let local_type_def_mods =
                    local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig) ->
                        if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end\n" ty_name ty_body_sig
                        else sprintf "    and %s : sig type t = %s\n    end\n" ty_name ty_body_sig) |> String.concat "\n"
                in
                w "%s" local_type_def_mods;
                w "    type t = Wrap.t [@@deriving yojson {strict = false}]\n\n";
                w "end\n\n";
            );
            List.hd root.interfaces |> (fun (name, iface) ->
                w "module rec %s : sig\n" name;
                interface root.interfaces name iface out_buf;
                w "end\n"
            );
            List.tl root.interfaces |> List.iter (fun (name, iface) ->
                w "and %s : sig\n" name;
                interface root.interfaces name iface out_buf;
                w "end\n"
            )
    end

    module Mod = struct
        let interface interfaces interface_name (interface : Types.interface_) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            let local_defs_names = ref [] in
            interface.initializer_ |> (function
                | Some {Types.properties} ->
                    let local_type_defs, def_body = object_body properties [] in
                    let local_type_defs =
                        local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                            if List.mem ty_name !local_defs_names then None else (
                                local_defs_names := ty_name :: !local_defs_names;
                                Some (ty_name, ty_body_sig, ty_body_struct)
                            )
                        )
                    in
                    let local_type_defs =
                        let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]\n" def_body in
                        ("Initializer", ty_body, ty_body) :: local_type_defs
                    in
                    let local_type_def_mods =
                        local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, ty_body_struct) ->
                            if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct
                            else sprintf "    and %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct
                        ) |> String.concat "\n"
                    in
                    w "%s" local_type_def_mods;

                    w "    type %s_t\n" (to_ocaml_name interface_name);
                    w "    type t = %s_t obj\n" (to_ocaml_name interface_name);
                    w "    let to_yojson (t:t) = `Assoc [(\"guid\", `String t.guid)]\n";
                    w "    let of_yojson _ = Result.Error \"of_yojson not implemented for obj\"\n\n";


                    w "    (* Initializer getters *)\n";
                    properties |> List.iter (fun (field_name, ty) ->
                        let is_opt, ty_inner = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                        match ty_inner with
                        | Types.TypeRef t when List.mem_assoc t interfaces ->
                            let field_name_ocaml = to_ocaml_name field_name in
                            w "    let %s t =\n" field_name_ocaml;
                            w "    match Hashtbl.find_opt t.conn.objects t.guid with\n";
                            w "    | Some obj ->\n";
                            w "        let open Yojson.Safe.Util in\n";
                            if is_opt then begin
                                w "        (try Some ({ conn = t.conn; guid = member \"%s\" obj.initializer_ |> member \"guid\" |> to_string } : %s.t)\n" field_name t;
                                w "        with _ -> None)\n";
                            end else begin
                                w "        (try ({ conn = t.conn; guid = member \"%s\" obj.initializer_ |> member \"guid\" |> to_string } : %s.t)\n" field_name t;
                                w "        with _ -> failwith \"Missing required initializer property %s\")\n" field_name;
                            end;
                            w "    | None -> failwith \"Object not found in connection\"\n";
                        | _ -> ()
                    );
                | None ->

                    w "    type %s_t\n" (to_ocaml_name interface_name);
                    w "    type t = %s_t obj\n" (to_ocaml_name interface_name);
                    w "    let to_yojson (t:t) = `Assoc [(\"guid\", `String t.guid)]\n";
                    w "    let of_yojson _ = Result.Error \"of_yojson not implemented for obj\"\n\n";

            );
            w "\n";
            let rec get_all_events iface =
                let base_events = match iface.Types.extends with
                    | Some base_name ->
                        (match List.assoc_opt base_name interfaces with
                        | Some base_iface -> get_all_events base_iface
                        | None -> [])
                    | None -> []
                in
                base_events @ iface.Types.events
            in
            get_all_events interface |> List.iter (fun (ev : Types.event) ->
                let fn_name = "on_" ^ to_ocaml_name ev.name in
                let wait_fn_name = "wait_for_" ^ to_ocaml_name ev.name in

                let local_type_defs, args = args_types ev.parameters.properties in
                let has_params = (List.length args > 0) in

                if has_params then begin
                    let ty_name = sprintf "%sEvent" (String.capitalize_ascii ev.name) in
                    let local_type_defs, fields = object_body ev.parameters.properties local_type_defs in
                    let local_type_defs = let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in (ty_name, ty_body, ty_body) :: local_type_defs in

                    let local_type_defs =
                        local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                            if List.mem ty_name !local_defs_names then None else (
                                local_defs_names := ty_name :: !local_defs_names;
                                Some (ty_name, ty_body_sig, ty_body_struct)
                            )
                        )
                    in

                    let local_type_def_mods =
                        local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, ty_body_struct) ->
                            if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct
                            else sprintf "    and %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct) |> String.concat "\n"
                    in
                    if local_type_defs <> [] then (
                        w "\n%s\n" local_type_def_mods;
                    );

                    let arg_ty_name = sprintf "%s" ty_name in

                    w "    let %s (t : t) cb =\n" fn_name;
                    w "        let _id = Connection.add_listener t.conn t.guid \"%s\" (fun msg ->\n" ev.name;
                    w "            match %s.of_yojson msg with\n" arg_ty_name;
                    w "            | Ok ev -> cb ev\n";
                    w "            | Error _ -> ()\n";
                    w "        ) in ()\n\n";

                    w "    let %s ?predicate (t : t) =\n" wait_fn_name;
                    w "        let p, r = Eio.Promise.create () in\n";
                    w "        let id = ref (-1) in\n";
                    w "        id := Connection.add_listener t.conn t.guid \"%s\" (fun msg ->\n" ev.name;
                    w "            match %s.of_yojson msg with\n" arg_ty_name;
                    w "            | Ok ev ->\n";
                    w "                let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in\n";
                    w "                if is_match then begin\n";
                    w "                    Connection.remove_listener t.conn t.guid \"%s\" !id;\n" ev.name;
                    w "                    if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev\n";
                    w "                end\n";
                    w "            | Error _ -> ()\n";
                    w "        );\n";
                    w "        Eio.Promise.await p\n\n";
                end else begin
                    w "    let %s (t : t) cb =\n" fn_name;
                    w "        let _id = Connection.add_listener t.conn t.guid \"%s\" (fun _msg -> cb ()) in ()\n\n" ev.name;

                    w "    let %s (t : t) =\n" wait_fn_name;
                    w "        let p, r = Eio.Promise.create () in\n";
                    w "        let id = ref (-1) in\n";
                    w "        id := Connection.add_listener t.conn t.guid \"%s\" (fun _msg ->\n" ev.name;
                    w "            Connection.remove_listener t.conn t.guid \"%s\" !id;\n" ev.name;
                    w "            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ()\n";
                    w "        );\n";
                    w "        Eio.Promise.await p\n\n";
                end
            );
            let rec get_all_commands iface =
                let base_cmds = match iface.Types.extends with
                    | Some base_name ->
                        (match List.assoc_opt base_name interfaces with
                        | Some base_iface -> get_all_commands base_iface
                        | None -> [])
                    | None -> []
                in
                base_cmds @ iface.Types.commands
            in
            get_all_commands interface |> List.iter (fun (cmd : Types.command) ->
                let local_type_defs, args = args_types cmd.parameters.properties in

                let local_type_defs, res_t = match cmd.returns.properties with
                    | [] -> local_type_defs, "unit"
                    | [name, ty] ->
                        let local_type_defs, ty_name = inline_type_ name ty local_type_defs in
                        local_type_defs, ty_name
                    | properties ->
                        let ty_name = sprintf "%sResult" (String.capitalize_ascii cmd.name) in
                        let acc, fields = object_body properties local_type_defs in
                        let ty_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in
                        let local_type_defs = (ty_name, ty_body, ty_body) :: acc in
                        local_type_defs, (sprintf "%s.t" ty_name)
                in

                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body_sig, ty_body_struct)
                        )
                    )
                in
                let local_type_def_mods =
                    local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, ty_body_struct) ->
                        if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct
                        else sprintf "    and %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct) |> String.concat "\n"
                in
                if local_type_defs <> [] then (
                    w "\n";
                    w "%s\n" local_type_def_mods;
                );

                let args_args =
                    args |> List.map (fun (orig_name, name, _ty, is_opt) ->
                        let is_opt = is_opt || orig_name = "timeout" in
                        let is_pos = is_positional orig_name in
                        if is_opt then sprintf "?%s" name
                        else if is_pos then sprintf "%s" name
                        else sprintf "~%s" name
                    ) |> String.concat " "
                in

                let args_args = if args_args <> "" then sprintf "%s (t:t)" args_args else "(t:t)" in
                (* let params = "Obj.magic \"<unimplemented>\"" in
                let res_parser = "Obj.magic \"<unimplemented>\"" in *)

                let rec get_encoder ty ty_name =
                    match ty with
                    | Types.Optional inner ->
                        sprintf "(fun v -> match v with Some x -> (%s) x | None -> `Null)" (get_encoder inner ty_name)
                    | Types.ArrayType {of_type} ->
                        let inner_ty_name = if String.ends_with ~suffix:" array" ty_name then String.sub ty_name 0 (String.length ty_name - 6) else ty_name in
                        sprintf "(fun l -> `List (List.map (%s) (Array.to_list l)))" (get_encoder of_type inner_ty_name)
                    | Types.StringType -> "fun s -> `String s"
                    | Types.IntType -> "fun i -> `Int i"
                    | Types.FloatType -> "fun f -> `Float f"
                    | Types.BooleanType -> "fun b -> `Bool b"
                    | Types.BinaryType -> "fun s -> `String (Base64.encode_exn s)"
                    | Types.JsonType -> "Stdlib.Fun.id"
                    | Types.AnyType -> "Stdlib.Fun.id"
                    | Types.TypeRef t ->
                        if List.mem_assoc t interfaces then
                            sprintf "(fun (x : %s.t) -> `Assoc [(\"guid\", `String x.guid)])" t
                        else
                            sprintf "%s.to_yojson" t
                    | Types.ObjectType _ | Types.EnumType _ ->
                        if String.ends_with ~suffix:".t" ty_name then
                            sprintf "%s.to_yojson" (String.sub ty_name 0 (String.length ty_name - 2))
                        else
                            sprintf "%s_to_yojson" ty_name
                in

                let rec get_decoder ty ty_name =
                    match ty with
                    | Types.Optional inner ->
                        sprintf "(fun v -> match v with `Null -> None | _ -> Some ((%s) v))" (get_decoder inner ty_name)
                    | Types.ArrayType {of_type} ->
                        let inner_ty_name = if String.ends_with ~suffix:" array" ty_name then String.sub ty_name 0 (String.length ty_name - 6) else ty_name in
                        sprintf "(fun v -> Array.of_list (List.map (%s) (Yojson.Safe.Util.to_list v)))" (get_decoder of_type inner_ty_name)
                    | Types.StringType -> "Yojson.Safe.Util.to_string"
                    | Types.IntType -> "Yojson.Safe.Util.to_int"
                    | Types.FloatType -> "Yojson.Safe.Util.to_float"
                    | Types.BooleanType -> "Yojson.Safe.Util.to_bool"
                    | Types.BinaryType -> "(fun v -> Base64.decode_exn (Yojson.Safe.Util.to_string v))"
                    | Types.JsonType -> "Stdlib.Fun.id"
                    | Types.AnyType -> "Stdlib.Fun.id"
                    | Types.TypeRef t ->
                        if List.mem_assoc t interfaces then
                            sprintf "(fun v -> let guid = Yojson.Safe.Util.member \"guid\" v |> Yojson.Safe.Util.to_string in ({ conn = t.conn; guid } : %s.t))" t
                        else
                            sprintf "(fun v -> match %s.of_yojson v with Ok x -> x | Error e -> failwith e)" t
                    | Types.ObjectType _ | Types.EnumType _ ->
                        if String.ends_with ~suffix:".t" ty_name then
                            sprintf "(fun v -> match %s.of_yojson v with Ok x -> x | Error e -> failwith e)" (String.sub ty_name 0 (String.length ty_name - 2))
                        else
                            sprintf "(fun v -> match %s_of_yojson v with Ok x -> x | Error e -> failwith e)" ty_name
                in

                let assoc_list =
                    args |> List.filter_map (fun (orig_name, name, ty_name, is_opt) ->
                        let ty = List.assoc orig_name cmd.parameters.properties in
                        let _is_opt_inner, ty = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                        let base_encoder = get_encoder ty ty_name in

                        let is_opt_arg = is_opt || orig_name = "timeout" in
                        if is_opt_arg then
                        if orig_name = "timeout" && not is_opt then
                        Some (sprintf "        (match %s with | Some v -> [(\"%s\", (%s) v)] | None -> [(\"timeout\", `Float 30000.0)]);" name orig_name base_encoder)
                        else
                        Some (sprintf "        (match %s with | Some v -> [(\"%s\", (%s) v)] | None -> []);" name orig_name base_encoder)
                        else
                        Some (sprintf "        [\"%s\", (%s) %s];" orig_name base_encoder name)
                    ) |> String.concat "\n"
                in

                let params = if args = [] then "`Assoc []" else sprintf "`Assoc (List.concat [\n%s\n    ])" assoc_list in

                let res_parser = match cmd.returns.properties with
                    | [] -> "ignore res"
                    | [name, ty] ->
                        let is_opt, ty = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                        let _, ty_name = inline_type_ name ty [] in
                        let base_decoder = get_decoder ty ty_name in
                        if is_opt then
                            sprintf "(match Yojson.Safe.Util.member \"%s\" res with | `Null -> None | v -> Some ((%s) v))" name base_decoder
                        else
                            sprintf "(match Yojson.Safe.Util.member \"%s\" res with | `Null -> failwith \"%s is null\" | v -> (%s) v)" name name base_decoder
                    | _properties ->
                        let module_name = String.capitalize_ascii cmd.name ^ "Result" in
                        sprintf "(match %s.of_yojson res with Ok x -> x | Error e -> failwith e)" module_name
                in

                let fn_name = to_ocaml_name cmd.name in
                let fn_name_raw = if fn_name = "evaluate_expression" || fn_name = "eval_on_selector" || fn_name = "eval_on_selector_all" || fn_name = "evaluate_expression_handle" || fn_name = "wait_for_function" || fn_name = "json_value" || fn_name = "dispatch_event" || fn_name = "expect" || fn_name = "reject" || fn_name = "resolve" then fn_name ^ "_raw" else fn_name in
                w "    let %s %s : %s =\n" fn_name_raw args_args res_t;
                w "        let params = %s in\n" params;
                w "        match Connection.send_message t.conn ~guid:t.guid ~method_:\"%s\" ~params with\n" cmd.name;
                w "        | Ok res -> %s\n" res_parser;
                w "        | Error e -> raise (Error e)\n";
            );
            if interface_name = "Page" then begin
                w "\n    (* Frame Proxy Commands *)\n";
                let frame_iface = List.assoc "Frame" interfaces in
                let rec get_all_commands iface =
                    let base_cmds = match iface.Types.extends with
                        | Some base_name ->
                            (match List.assoc_opt base_name interfaces with
                            | Some base_iface -> get_all_commands base_iface
                            | None -> [])
                        | None -> []
                    in
                    base_cmds @ iface.Types.commands
                in
                let page_cmds = get_all_commands interface |> List.map (fun (c : Types.command) -> c.name) in
                let proxy_cmds = get_all_commands frame_iface |> List.filter (fun (c : Types.command) -> not (List.mem c.name page_cmds)) in
                proxy_cmds |> List.iter (fun (cmd : Types.command) ->
                    let _local_type_defs_args, args = args_types cmd.parameters.properties in
                    let args_args =
                        args |> List.map (fun (orig_name, name, _ty, is_opt) ->
                            let is_opt = is_opt || orig_name = "timeout" in
                            let is_pos = is_positional orig_name in
                            if is_opt then sprintf "?%s" name
                            else if is_pos then sprintf "%s" name
                            else sprintf "~%s" name
                        ) |> String.concat " "
                    in
                    let fn_name = to_ocaml_name cmd.name in
                    let call_args = if args_args <> "" then sprintf "%s (main_frame t)" args_args else "(main_frame t)" in
                    let args_args = if args_args <> "" then sprintf "%s (t:t)" args_args else "(t:t)" in
                    let fn_name_raw = if fn_name = "evaluate_expression" || fn_name = "eval_on_selector" || fn_name = "eval_on_selector_all" || fn_name = "evaluate_expression_handle" || fn_name = "wait_for_function" || fn_name = "json_value" || fn_name = "dispatch_event" || fn_name = "expect" || fn_name = "reject" || fn_name = "resolve" then fn_name ^ "_raw" else fn_name in
                    w "    let %s %s =\n" fn_name_raw args_args;
                    w "        Frame.%s %s\n" fn_name_raw call_args;
                );
            end

        let render (root : Types.root) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            w "[@@@ocaml.warning \"-30-39-32\"]\n\n";
            w "exception Error of string\n\n";
            w "type 'a obj = { conn: Connection.t; guid: string }\n";
            w "let internal_obj_to_yojson _ = failwith \"internal_obj_to_yojson called\"\nlet internal_obj_of_yojson _ = failwith \"internal_obj_of_yojson: <probably should never be called>\"\n";
            
            
            w "module Channel = struct type t = { guid: string } [@@deriving yojson {strict = false}] end\n";
            root.top_defs |> List.iter (fun (name, def) ->
                let local_type_defs, def_body_for_sig, def_body_for_struct = match def with
                    | Types.Object {properties} ->
                        let local_type_defs, fields = object_body properties [] in
                        let def_body = sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields in
                        local_type_defs, def_body, def_body
                    | Types.Enum {literals} ->
                        let ctors_decl = literals |> List.map (fun literal -> sprintf "        | `%s [@name \"%s\"]" (to_ocaml_variant_name literal) literal) |> String.concat "\n" in
                        let yojson_sigs, yojson_defs = make_yojson_functions_for_variant literals in
                        let ty_body_sig = sprintf "[\n%s\n    ]\n%s\n" ctors_decl yojson_sigs in
                        let ty_body_struct = sprintf "[\n%s\n    ]\n%s\n" ctors_decl yojson_defs in
                        [], ty_body_sig, ty_body_struct
                in
                let def_body_for_sig = def_body_for_sig |> Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" in
                let def_body_for_struct = def_body_for_struct |> Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" in
                let local_defs_names = ref [] in
                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body_sig, ty_body_struct)
                        )
                    )
                    |> List.map (fun (ty_name, ty_body_sig, ty_body_struct) ->
                        ty_name,
                        Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"Wrap.t" ty_body_sig,
                        Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"Wrap.t" ty_body_struct
                    )
                in
                w "module %s = struct\n" name;
                let local_type_defs = ("Wrap", def_body_for_sig, def_body_for_struct) :: local_type_defs in
                let local_type_def_mods =
                    local_type_defs |> List.mapi (fun i (ty_name, ty_body_sig, ty_body_struct) ->
                        if i = 0 then sprintf "    module rec %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct
                        else sprintf "    and %s : sig type t = %s\n    end = struct type t = %s\n    end\n" ty_name ty_body_sig ty_body_struct
                    ) |> String.concat "\n"
                in
                w "%s" local_type_def_mods;
                w "    type t = Wrap.t\n    [@@deriving yojson {strict = false}]\n    \n";
                w "end\n\n";
            );
            List.hd root.interfaces |> (fun (name, iface) ->
                w "module rec %s : sig\n" name;
                Sig.interface root.interfaces name iface out_buf;
                w "end = struct\n";
                interface root.interfaces name iface out_buf;
                w "end\n"
            );
            List.tl root.interfaces |> List.iter (fun (name, iface) ->
                w "and %s : sig\n" name;
                Sig.interface root.interfaces name iface out_buf;
                w "end = struct\n";
                interface root.interfaces name iface out_buf;
                w "end\n"
            )
    end
end


let () =
    let yaml_file = if Array.length Sys.argv > 2 then Sys.argv.(2) else "protocol/protocol.yml" in
    let content = In_channel.with_open_text yaml_file In_channel.input_all in
    let parsed = Parser.parse content in
    let out_buf = Buffer.create 0x1000 in
    if Array.length Sys.argv > 1 && Sys.argv.(1) = "ml" then
        Render.Mod.render parsed out_buf
    else
        Render.Sig.render parsed out_buf;
    print_string (Buffer.contents out_buf)
