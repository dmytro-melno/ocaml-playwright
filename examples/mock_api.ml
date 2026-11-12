(* Tests a page against a mocked backend: requests are intercepted and answered here, and
   assertions wait for the page to catch up.

     dune exec examples/mock_api.exe *)

open Playwright

let app =
    {|<h1>Tasks</h1>
      <ul id="tasks"></ul>
      <input placeholder="New task"> <button>Add</button>
      <script>
        const list = document.querySelector('#tasks'), input = document.querySelector('input');
        const show = task => { const li = document.createElement('li'); li.textContent = task.title; list.append(li); };
        fetch('/api/tasks').then(response => response.json()).then(tasks => tasks.forEach(show));
        document.querySelector('button').onclick = async () => {
          const response = await fetch('/api/tasks', { method: 'POST', body: JSON.stringify({ title: input.value }) });
          show(await response.json());
          input.value = '';
        };
      </script>|}

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch ?executable_path:(Sys.getenv_opt "CHROMIUM_PATH") (chromium pw) in
    let page = BrowserContext.new_page (Browser.new_context browser) in
    (* The application itself is served from here as well. *)
    Page.route page "https://tasks.test/" (Route.fulfill ~content_type:"text/html" ~body:app) |> ignore;
    Page.route page "https://tasks.test/api/tasks"
        (fun route ->
            let request = Route.request route in
            match Request.method_ request with
            | "POST" ->
                let title = Request.post_data request |> Option.get |> Yojson.Safe.from_string |> Yojson.Safe.Util.member "title" in
                Route.fulfill ~status:201 ~json:(`Assoc [ "id", `Int 3; "title", title ]) route
            | _ -> Route.fulfill ~json:(`List [ `Assoc [ "id", `Int 1; "title", `String "Water the plants" ] ]) route)
    |> ignore;
    ignore (Page.goto page "https://tasks.test/");
    let tasks = Page.get_by_role page `Listitem in
    Expect.to_have_texts [ "Water the plants" ] tasks;
    Page.get_by_placeholder page "New task" |> Locator.fill "Read the Playwright guide";
    (* [expect_request] returns the request that the click causes. *)
    let request = Page.expect_request page ~url:"**/api/tasks" (fun () -> Page.get_by_role page `Button ~name:"Add" |> Locator.click) in
    Printf.printf "the page sent: %s\n" (Option.value (Request.post_data request) ~default:"");
    Expect.to_have_texts [ "Water the plants"; "Read the Playwright guide" ] tasks;
    Expect.to_have_value "" (Page.get_by_placeholder page "New task");
    (* A failing assertion says what it waited for and what it found instead. *)
    (match Expect.to_have_count ~timeout:500. 5 tasks with
    | () -> ()
    | exception Playwright.Error error -> Printf.printf "as expected, an assertion that does not hold fails:\n%s\n" error.message);
    Browser.close browser
