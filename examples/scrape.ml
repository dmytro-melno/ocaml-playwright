(* Reads structured data from a page: with locators, and with JavaScript evaluated in the page.

     dune exec examples/scrape.exe

   The page is made up here so that the example needs no network. *)

open Playwright

let shop =
    {|<h1>Tea shop</h1>
      <ul>
        <li class="product"><a href="/tea/sencha">Sencha</a> <span class="price">9.50</span> <button>Add to cart</button></li>
        <li class="product"><a href="/tea/assam">Assam</a> <span class="price">7.00</span> <button disabled>Sold out</button></li>
        <li class="product"><a href="/tea/oolong">Oolong</a> <span class="price">12.25</span> <button>Add to cart</button></li>
      </ul>|}

type product = { name : string; price : float; available : bool }

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch ?executable_path:(Sys.getenv_opt "CHROMIUM_PATH") (chromium pw) in
    let page = BrowserContext.new_page (Browser.new_context browser) in
    Page.set_content page shop;
    (* One locator per product, and locators relative to it for the parts. *)
    let products =
        Page.locator page ".product" |> Locator.all
        |> List.map (fun item ->
               { name = Locator.get_by_role `Link item |> Locator.inner_text;
                 price = Locator.locator ".price" item |> Locator.inner_text |> float_of_string;
                 available = Locator.get_by_role `Button item |> Locator.is_enabled })
    in
    List.iter (fun p -> Printf.printf "%-8s %6.2f %s\n" p.name p.price (if p.available then "" else "(sold out)")) products;
    (* The same question answered by the page itself.  The result arrives as a [Js.t]. *)
    let total =
        Page.evaluate page "[...document.querySelectorAll('.price')].reduce((sum, e) => sum + Number(e.textContent), 0)" |> Js.to_float
    in
    Printf.printf "total    %6.2f\n" total;
    (* Locators can be narrowed down by what they contain. *)
    let sold_out = Page.locator page ".product" |> Locator.filter ~has:(Page.get_by_role page `Button ~disabled:true) in
    Printf.printf "sold out: %s\n" (Locator.get_by_role `Link sold_out |> Locator.inner_text);
    Browser.close browser
