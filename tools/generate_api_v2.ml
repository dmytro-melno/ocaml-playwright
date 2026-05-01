
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

    let rec inline_type_ name ty (acc : (string * string) list) : (string * string) list * string =
        let open Types in
        match ty with
        | StringType -> acc, "string"
        | IntType -> acc, "int"
        | FloatType -> acc, "float"
        | BooleanType -> acc, "bool"
        | BinaryType -> acc, "string"
        | JsonType -> acc, "json"
        | AnyType -> acc, "any"
        | ObjectType {properties} ->
            let ty_name = sprintf "%s_t" (to_ocaml_name name) in
            (object_ ty_name properties acc), ty_name
        | ArrayType {of_type} ->
            let acc, ty_name = inline_type_ name of_type acc in
            acc, sprintf "%s array" ty_name
        | EnumType {literals} ->
            let ty_name = sprintf "%s_t" (to_ocaml_name name) in
            (enum_ ty_name literals acc), ty_name
        | TypeRef ty_name -> acc, sprintf "%s.t" ty_name
        | Optional ty ->
            let acc, ty_name = inline_type_ name ty acc in
            acc, sprintf "%s option" ty_name
    and object_ ty_name properties acc =
        let acc, fields = object_body properties acc in
        (ty_name, sprintf "{\n%s\n    }" fields) :: acc
    and enum_ ty_name (literals : string list) acc =
        let ctors_decl = literals |> List.map (fun literal -> sprintf "        | `%s [@name \"%s\"]" (to_ocaml_variant_name literal) literal) |> String.concat "\n" in
        (ty_name, sprintf "[\n%s\n    ] [@@deriving yojson]\n" ctors_decl) :: acc
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

    let strip_attrs code = Re.replace_string (Re.Pcre.regexp " \\[@.*?\\]") ~by:"" code

    module Sig = struct
        let interface interfaces (interface : Types.interface_) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            let local_defs_names = ref [] in
            interface.initializer_ |> (function
                | Some {Types.properties} ->
                    let local_type_defs, def_body = object_body properties [] in
                    let local_type_defs =
                        local_type_defs |> List.filter_map (fun (ty_name, ty_body) ->
                            if List.mem ty_name !local_defs_names then None else (
                                local_defs_names := ty_name :: !local_defs_names;
                                Some (ty_name, ty_body)
                            )
                        )
                    in
                    w "    type t = {\n%s\n%s\n    }\n    [@@deriving yojson {strict = false}]\n\n" (strip_attrs def_body) "        __internal_obj : obj";
                    w "%s\n" ((local_type_defs |> List.map (fun (ty_name, ty_body) -> sprintf "\n    and %s = %s" ty_name (strip_attrs ty_body)) |> String.concat ""))
                | None ->
                    w "    type t [@@deriving yojson]\n";
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
            get_all_commands interface |> List.iter (fun (cmd : Types.command) ->
                let local_type_defs, args = args_types cmd.parameters.properties in
                let args_sig = args |> List.map (fun (_, name, ty, is_opt) -> if is_opt then sprintf "?%s:%s" name ty else sprintf "%s:%s" name ty) |> String.concat " -> " in
                let local_type_defs, res_t, _ = match cmd.returns.properties with
                    | [] -> local_type_defs, "unit", []
                    | [name, ty] ->
                        let local_type_defs, ty_name = inline_type_ name ty local_type_defs in
                        local_type_defs, ty_name, [name, ty]
                    | properties ->
                        let ty_name = sprintf "%s_res_t" (to_ocaml_name cmd.name) in
                        let acc, fields = object_body properties local_type_defs in
                        let local_type_defs = (ty_name, sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields) :: acc in
                        local_type_defs, ty_name, properties
                in
                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body)
                        )
                    )
                in
                if local_type_defs <> [] then (
                    w "\n";
                    w "%s\n" (local_type_defs |> List.mapi (fun i (ty_name, ty_body) -> if i = 0 then sprintf "    type %s = %s\n" ty_name (strip_attrs ty_body) else sprintf "    and %s = %s\n" ty_name (strip_attrs ty_body)) |> String.concat "\n");
                );
                let args_sig = if args_sig <> "" then sprintf "%s -> t" args_sig else "t" in
                w "    val %s : %s -> %s\n" (to_ocaml_name cmd.name) args_sig res_t;
            )
        let render (root : Types.root) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            w "[@@@ocaml.warning \"-30-39-32\"]\n\n";
            w "type obj = { conn: Connection.t; guid: string }\n";
            w "type any = Yojson.Safe.t\n";
            w "type json = Yojson.Safe.t\n\n";
            w "module Channel : sig type t = { guid: string } [@@deriving yojson] end\n";
            root.top_defs |> List.iter (fun (name, def) ->
                let local_type_defs, def_body = match def with
                    | Types.Object {properties} ->
                        let local_type_defs, fields = object_body properties [] in
                        local_type_defs, sprintf "{\n%s\n    }" fields
                    | Types.Enum {literals} ->
                        let local_type_defs, ctors = enum_body literals [] in
                        local_type_defs, sprintf "[\n%s\n    ]" ctors
                in
                let def_body = def_body |> Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" in
                let def_body = strip_attrs def_body in
                let local_defs_names = ref [] in
                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body)
                        )
                    )
                    |> List.map (fun (ty_name, ty_body) -> ty_name, Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" ty_body)
                    |> List.map (fun (ty_name, ty_body) -> ty_name, strip_attrs ty_body)
                in
                w "module %s : sig\n" name;
                let and_defs = local_type_defs |> List.map (fun (ty_name, ty_body) -> sprintf "\n    and %s = %s" ty_name ty_body) |> String.concat "" in
                w "    type t = %s\n    [@@deriving yojson {strict = false}]\n    %s\n" def_body and_defs;
                w "end\n\n";
            );
            List.hd root.interfaces |> (fun (name, iface) ->
                w "module rec %s : sig\n" name;
                interface root.interfaces iface out_buf;
                w "end\n"
            );
            List.tl root.interfaces |> List.iter (fun (name, iface) ->
                w "and %s : sig\n" name;
                interface root.interfaces iface out_buf;
                w "end\n"
            )
    end

    module Mod = struct
        let interface interfaces (interface : Types.interface_) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            let local_defs_names = ref [] in
            interface.initializer_ |> (function
                | Some {Types.properties} ->
                    let local_type_defs, def_body = object_body properties [] in
                    let local_type_defs =
                        local_type_defs |> List.filter_map (fun (ty_name, ty_body) ->
                            if List.mem ty_name !local_defs_names then None else (
                                local_defs_names := ty_name :: !local_defs_names;
                                Some (ty_name, ty_body)
                            )
                        )
                    in
                    w "    type t = {\n%s\n%s\n    } [@@deriving yojson {strict = false}]\n" def_body "        __internal_obj : obj [@default {conn = Obj.magic (); guid = \"\"}]";
                    if local_type_defs <> [] then (
                        w "%s\n" (local_type_defs |> List.map (fun (ty_name, ty_body) -> sprintf "    and %s = %s\n" ty_name ty_body) |> String.concat "\n");
                    );
                | None ->
                    w "    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = \"\"}] } [@@deriving yojson {strict = false}]\n";
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
            get_all_commands interface |> List.iter (fun (cmd : Types.command) ->
                let local_type_defs, args = args_types cmd.parameters.properties in

                let local_type_defs, res_t, _returns_props = match cmd.returns.properties with
                    | [] -> local_type_defs, "unit", []
                    | [name, ty] ->
                        let local_type_defs, ty_name = inline_type_ name ty local_type_defs in
                        local_type_defs, ty_name, [name, ty]
                    | properties ->
                        let ty_name = sprintf "%s_res_t" (to_ocaml_name cmd.name) in
                        let acc, fields = object_body properties local_type_defs in
                        let local_type_defs = (ty_name, sprintf "{\n%s\n    } [@@deriving yojson {strict = false}]" fields) :: acc in
                        local_type_defs, ty_name, properties
                in

                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body)
                        )
                    )
                in
                if local_type_defs <> [] then (
                    w "\n";
                    w "%s\n" (local_type_defs |> List.mapi (fun i (ty_name, ty_body) -> if i = 0 then sprintf "    type %s = %s\n" ty_name ty_body else sprintf "    and %s = %s\n" ty_name ty_body) |> String.concat "\n");
                );

                let args_args = args |> List.map (fun (_orig_name, name, _ty, is_opt) ->
                    if is_opt then sprintf "?%s" name else sprintf "~%s" name
                ) |> String.concat " " in

                let args_args = if args_args <> "" then sprintf "%s (t:t)" args_args else "(t:t)" in

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
                    | Types.JsonType -> "json_to_yojson"
                    | Types.AnyType -> "any_to_yojson"
                    | Types.TypeRef t -> sprintf "%s.to_yojson" t
                    | Types.ObjectType _ | Types.EnumType _ -> sprintf "%s_to_yojson" ty_name
                in

                let rec get_decoder ty ty_name =
                    match ty with
                    | Types.Optional inner ->
                        sprintf "(fun v -> match v with `Null -> Ok None | _ -> match (%s) v with Ok r -> Ok (Some r) | Error e -> Error e)" (get_decoder inner ty_name)
                    | Types.ArrayType {of_type} ->
                        let inner_ty_name = if String.ends_with ~suffix:" array" ty_name then String.sub ty_name 0 (String.length ty_name - 6) else ty_name in
                        sprintf "(fun v -> try Ok (Array.of_list (List.map (fun item -> match (%s) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)" (get_decoder of_type inner_ty_name)
                    | Types.StringType -> "fun v -> Ok (Yojson.Safe.Util.to_string v)"
                    | Types.IntType -> "fun v -> Ok (Yojson.Safe.Util.to_int v)"
                    | Types.FloatType -> "fun v -> Ok (Yojson.Safe.Util.to_float v)"
                    | Types.BooleanType -> "fun v -> Ok (Yojson.Safe.Util.to_bool v)"
                    | Types.BinaryType -> "fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))"
                    | Types.JsonType -> "json_of_yojson"
                    | Types.AnyType -> "any_of_yojson"
                    | Types.TypeRef t -> sprintf "%s.of_yojson" t
                    | Types.ObjectType _ | Types.EnumType _ -> sprintf "%s_of_yojson" ty_name
                in

                let assoc_list = args |> List.filter_map (fun (orig_name, name, ty_name, is_opt) ->
                    let ty = List.assoc orig_name cmd.parameters.properties in
                    let _is_opt_inner, ty = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                    let base_encoder = get_encoder ty ty_name in

                    if is_opt then
                        Some (sprintf "        (match %s with | Some v -> [(\"%s\", (%s) v)] | None -> []);" name orig_name base_encoder)
                    else
                        Some (sprintf "        [\"%s\", (%s) %s];" orig_name base_encoder name)
                ) |> String.concat "\n" in

                let params = if args = [] then "`Assoc []" else sprintf "`Assoc (List.concat [\n%s\n    ])" assoc_list in

                let res_parser = match cmd.returns.properties with
                    | [] -> "Ok ()"
                    | [name, ty] ->
                        let is_opt, ty = match ty with | Types.Optional ty -> true, ty | ty -> false, ty in
                        let _, ty_name = inline_type_ name ty [] in
                        let base_decoder = get_decoder ty ty_name in
                        if is_opt then
                            sprintf "(match Yojson.Safe.Util.member \"%s\" res with | `Null -> Ok None | v -> match (%s) v with Ok r -> Ok (Some r) | Error e -> Error e)" name base_decoder
                        else
                            sprintf "(match Yojson.Safe.Util.member \"%s\" res with | `Null -> Error \"%s is null\" | v -> (%s) v)" name name base_decoder
                    | _properties -> sprintf "%s_of_yojson res" res_t
                in


                w "    let %s %s : (%s, string) result =\n" (to_ocaml_name cmd.name) args_args res_t;
                w "        let params = %s in\n" params;
                w "        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:\"%s\" ~params with\n" cmd.name;
                w "        | Ok res -> %s\n" res_parser;
                w "        | Error e -> Error e\n";
            )

        let render (root : Types.root) = fun out_buf ->
            let w fmt = bprintf out_buf fmt in
            w "[@@@ocaml.warning \"-30-39-32\"]\n\n";
            w "type obj = { conn: Connection.t; guid: string }\n";
            w "let obj_to_yojson _ = `Null\nlet obj_of_yojson _ = Ok { conn = Obj.magic (); guid = \"\" }\n";
            w "type any = Yojson.Safe.t\n";
            w "let any_to_yojson (x: any) = x\nlet any_of_yojson (x: any) = Ok x\n";
            w "type json = Yojson.Safe.t\n";
            w "let json_to_yojson (x: json) = x\nlet json_of_yojson (x: json) = Ok x\n\n";
            w "module Channel = struct type t = { guid: string } [@@deriving yojson] end\n";
            root.top_defs |> List.iter (fun (name, def) ->
                let local_type_defs, def_body = match def with
                    | Types.Object {properties} ->
                        let local_type_defs, fields = object_body properties [] in
                        local_type_defs, sprintf "{\n%s\n    }" fields
                    | Types.Enum {literals} ->
                        let ctors_decl = literals |> List.map (fun literal -> sprintf "        | `%s [@name \"%s\"]" (to_ocaml_variant_name literal) literal) |> String.concat "\n" in
                        [], sprintf "[\n%s\n    ]" ctors_decl
                in
                let def_body = def_body |> Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" in
                let local_defs_names = ref [] in
                let local_type_defs =
                    local_type_defs |> List.filter_map (fun (ty_name, ty_body) ->
                        if List.mem ty_name !local_defs_names then None else (
                            local_defs_names := ty_name :: !local_defs_names;
                            Some (ty_name, ty_body)
                        )
                    )
                    |> List.map (fun (ty_name, ty_body) -> ty_name, Re.replace_string (Re.compile @@ Re.str (sprintf "%s.t" name)) ~by:"t" ty_body)
                in
                let and_defs = local_type_defs |> List.map (fun (ty_name, ty_body) -> sprintf "\n    and %s = %s" ty_name ty_body) |> String.concat "" in
                w "module %s = struct\n" name;
                w "    type t = %s\n    [@@deriving yojson {strict = false}]\n    %s\n" def_body and_defs;
                w "end\n\n";
            );
            List.hd root.interfaces |> (fun (name, iface) ->
                w "module rec %s : sig\n" name;
                Sig.interface root.interfaces iface out_buf;
                w "end = struct\n";
                interface root.interfaces iface out_buf;
                w "end\n"
            );
            List.tl root.interfaces |> List.iter (fun (name, iface) ->
                w "and %s : sig\n" name;
                Sig.interface root.interfaces iface out_buf;
                w "end = struct\n";
                interface root.interfaces iface out_buf;
                w "end\n"
            )
    end
end


let () =
    let content = In_channel.with_open_text "deps/playwright/packages/protocol/src/protocol.yml" In_channel.input_all in
    let parsed = Parser.parse content in
    let out_buf = Buffer.create 0x1000 in
    if Array.length Sys.argv > 1 && Sys.argv.(1) = "ml" then
        Render.Mod.render parsed out_buf
    else
        Render.Sig.render parsed out_buf;
    print_string (Buffer.contents out_buf)
