(lang dune 3.10)
(name playwright)
(generate_opam_files true)

(source
 (github dmytrom/ocaml-playwright))

(authors "dmytrom")
(maintainers "dmytrom")

(package
 (name playwright)
 (synopsis "OCaml bindings for Playwright")
 (description "OCaml bindings for Playwright generated from protocol.yml")
 (depends
  (ocaml (>= 5.0.0))
  dune
  eio_main
  yojson
  ppx_deriving_yojson
  yaml
 ))