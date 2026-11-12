(* Who has whom among the objects of a session.

   A browser has contexts, a context has pages and service workers, a page has frames and
   workers.  Each of these ties is kept at both ends, in two records, and the two ends are not
   told of a change by the same event of the driver: a page is put into its context when the
   context hears of it, and taken out when the page hears that it closed.  So the ties are made
   and undone here, and nowhere else: the two ends agree by construction. *)

open Types

let with_ x list = if List.memq x list then list else list @ [ x ]
let without x list = List.filter (fun y -> y != x) list

(* {1 A browser and its contexts} *)

let add_context (browser : browser) (context : browser_context) =
    context.browser <- Some browser;
    browser.contexts <- with_ context browser.contexts

(* The contexts of a session are told of the selector engines that are registered later. *)
let add_to_session (context : browser_context) =
    let selectors = context.c_session.selectors in
    selectors.all_contexts <- context :: selectors.all_contexts

let remove_context (context : browser_context) =
    Option.iter (fun (browser : browser) -> browser.contexts <- without context browser.contexts) context.browser;
    let selectors = context.c_session.selectors in
    selectors.all_contexts <- without context selectors.all_contexts

(* {1 A context and its pages} *)

let add_page (context : browser_context) (page : page) = context.pages <- with_ page context.pages
let remove_page (page : page) = page.context.pages <- without page page.context.pages

(* {1 A page and its frames} *)

let add_child_frame (parent : frame) (frame : frame) = parent.child_frames <- with_ frame parent.child_frames

let add_frame (page : page) (frame : frame) =
    frame.page <- Some page;
    page.frames <- with_ frame page.frames;
    Option.iter (fun parent -> add_child_frame parent frame) frame.parent_frame

let remove_frame (page : page) (frame : frame) =
    page.frames <- without frame page.frames;
    frame.detached <- true;
    Option.iter (fun (parent : frame) -> parent.child_frames <- without frame parent.child_frames) frame.parent_frame

(* {1 Workers} *)

let add_worker (page : page) (worker : worker) =
    worker.w_page <- Some page;
    page.workers <- with_ worker page.workers

let add_service_worker (context : browser_context) (worker : worker) =
    worker.w_context <- Some context;
    context.service_workers <- with_ worker context.service_workers

let remove_worker (worker : worker) =
    Option.iter (fun (page : page) -> page.workers <- without worker page.workers) worker.w_page;
    Option.iter (fun (context : browser_context) -> context.service_workers <- without worker context.service_workers) worker.w_context
