(lang dune 3.10)
(name playwright)
(generate_opam_files true)

(source
 (github dmytro-melno/ocaml-playwright))

(authors "Dmytro Melnychuk")
(maintainers "Dmytro Melnychuk")

(package
 (name playwright)
 (synopsis "OCaml bindings for Playwright")
 (description "OCaml bindings for Playwright generated from protocol.yml")
 (license MIT)
 (depends
  (ocaml (>= 5.0.0))
  dune
  (eio (>= 0.12))
  (eio_linux (>= 0.12))
  (eio_main (and :with-test (>= 0.12)))
  (yojson (>= 1.6.0))
  (ppx_deriving_yojson (>= 3.10.0))
  (yaml (>= 3.0.1))
  (base64 (>= 3.0.0))
  (camlzip (>= 1.14))
  (re (>= 1.9.0))
 ))
