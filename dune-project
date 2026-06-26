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
  eio
  eio_linux
  yojson
  ppx_deriving_yojson
  yaml
 ))
