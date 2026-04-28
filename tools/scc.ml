
module SCC = struct
  type node = {
    id: string;
    mutable index: int;
    mutable lowlink: int;
    mutable on_stack: bool;
    deps: string list;
  }

  let scc (nodes : (string * string list) list) =
    let index = ref 0 in
    let stack = Stack.create () in
    let map = Hashtbl.create (List.length nodes) in
    List.iter (fun (id, deps) ->
      Hashtbl.add map id { id; index = -1; lowlink = -1; on_stack = false; deps }
    ) nodes;
    let sccs = ref [] in
    let rec strongconnect v =
      v.index <- !index;
      v.lowlink <- !index;
      incr index;
      Stack.push v stack;
      v.on_stack <- true;
      List.iter (fun w_id ->
        match Hashtbl.find_opt map w_id with
        | Some w ->
            if w.index = -1 then begin
              strongconnect w;
              v.lowlink <- min v.lowlink w.lowlink
            end else if w.on_stack then
              v.lowlink <- min v.lowlink w.index
        | None -> ()
      ) v.deps;
      if v.lowlink = v.index then begin
        let scc = ref [] in
        let rec pop_scc () =
          let w = Stack.pop stack in
          w.on_stack <- false;
          scc := w.id :: !scc;
          if w.id <> v.id then pop_scc ()
        in
        pop_scc ();
        sccs := !scc :: !sccs
      end
    in
    Hashtbl.iter (fun _ v ->
      if v.index = -1 then strongconnect v
    ) map;
    List.rev !sccs
end
