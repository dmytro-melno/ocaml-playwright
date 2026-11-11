(lang dune 3.10)

(name playwright)

(generate_opam_files true)

(source
 (github dmytro-melno/ocaml-playwright))

(authors "Dmytro Melnychuk")

(maintainers "Dmytro Melnychuk")

(license MIT)

(package
 (name playwright)
 (synopsis "Browser automation with Playwright for OCaml")
 (description
  "A client for the Playwright browser automation driver, built on Eio.\nIt drives Chromium, Firefox and WebKit through the same API as the official Playwright\nlibraries: auto-waiting locators, network interception, tracing and more.")
 (depends
  (ocaml
   (>= 5.2.0))
  (eio
   (>= 1.0))
  (cstruct
   (>= 6.0.0))
  (yojson
   (>= 3.0.0))
  (base64
   (>= 3.0.0))
  (eio_main
   (and
    :with-test
    (>= 1.0)))
  (alcotest
   (and
    :with-test
    (>= 1.7.0)))
  (yaml
   (and
    :with-test
    (>= 3.0.0)))
  (digestif :with-test)))
