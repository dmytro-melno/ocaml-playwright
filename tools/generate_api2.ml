
[@@@ocaml.warning "-37-27-32-69-33"]

open Yaml

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

    type top_def =
        | Object of object_
        | Enum of enum_
        | Interface of interface_
    type root = {
        top_defs : (string * top_def) list
    }
end

module Parser = struct
    let failwithf fmt = Printf.ksprintf failwith fmt

    let get_dict = function
        | `O d -> d
        | `Null -> []
        | _ -> failwith "Expected dict"

    let get_list = function
        | `A l -> l
        | `Null -> []
        | _ -> failwith "Expected list"

    let get_string = function
        | `String s -> s
        | _ -> failwith "Expected string"

    let opt_dict k d =
        match List.assoc_opt k d with
        | Some (`O v) -> v
        | Some `Null | None -> []
        | _ -> failwithf "Expected dict for key %s" k

    let opt_string k d =
        match List.assoc_opt k d with
        | Some (`String v) -> Some v
        | _ -> None

    let opt_list k d =
        match List.assoc_opt k d with
        | Some (`A v) -> v
        | Some `Null -> []
        | _ -> []

    let rec parse_type env name v =
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

    let parse_top_def env name d =
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
        | "interface" ->
            let extends = opt_string "extends" d in
            let initializer_ = parse_initializer env d in
            let commands = opt_dict "commands" d |> List.map (fun (k, v) -> parse_command env k (get_dict v)) in
            let events = opt_dict "events" d |> List.map (fun (k, v) -> parse_event env k (get_dict v)) in
            Some (Types.Interface { extends; initializer_; commands; events })
        | "mixin" -> None
        | _ -> failwithf "Unknown top-level type: %s" type_str

    let parse path =
        let content = In_channel.with_open_text path In_channel.input_all in
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

        let top_defs =
            top_dict |> List.filter_map (fun (name, v) ->
                let d = get_dict v in
                Option.map (fun def -> (name, def)) (parse_top_def mixins name d)
            )
        in
        { Types.top_defs }
end

(* module Render = struct
    open Printf

    module Sig = struct
        let interface_body interface =
            let command name types = sprintf "val %s : %s" name types in
            commands |> command
        let render interfaces = fun w ->
            w "mopdule rec ";
            w (interfaces |> List.map interface_body |> String.concat "\nand\n");
            w "\nend\n"
    end
end *)
