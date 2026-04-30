(* Remove this warning directive when no longer needed to compile. *)
[@@@ocaml.warning "-37-27-32-69"]

module Types = struct
    type type_ =
        | Optional of type_
        | String
        | Binary
        | Object of object_
        | Array of array_
        | Enum of enum_
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
        title : string;
        parameters : object_;
        returns : object_;
    }
    type event = {
        name : string;
        parameters : object_;
    }
    type interface_ = {
        extends : string option;
        command : command list;
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

module Parse = struct
    let parse (path : string) : Types.root = {top_defs = []}
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