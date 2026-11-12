(* Records a trace: every action with screenshots and snapshots of the page before and after.

     dune exec examples/trace.exe
     ocaml-playwright show-trace trace.zip

   The second command opens the trace viewer; https://trace.playwright.dev shows a trace too. *)

open Playwright

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch (chromium pw) ?executable_path:(Sys.getenv_opt "CHROMIUM_PATH") in
    let context = Browser.new_context browser in
    let tracing = BrowserContext.tracing context in
    Tracing.start tracing ~screenshots:true ~snapshots:true ~title:"Search form";
    let page = BrowserContext.new_page context in
    Page.set_content page
        {|<form onsubmit="event.preventDefault(); document.querySelector('output').textContent = 'No results for ' + query.value">
            <label>Search <input name="query"></label> <button>Go</button> <output></output>
          </form>|};
    Tracing.group tracing "Fill in the form";
    Page.get_by_label page "Search" |> Locator.fill "ocaml";
    Page.get_by_role page `Button ~name:"Go" |> Locator.click;
    Tracing.group_end tracing;
    Expect.to_have_text "No results for ocaml" (Page.locator page "output");
    Tracing.stop tracing ~path:"trace.zip";
    print_endline "saved trace.zip";
    Browser.close browser
