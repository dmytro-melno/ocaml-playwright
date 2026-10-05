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
  (ocaml (>= 5.2.0))
  dune
  (eio (>= 1.3))
  mtime
  (eio_main (and :with-test (>= 1.3)))
  (yojson (>= 1.6.0))
  (ppx_deriving_yojson (>= 3.10.0))
  (yaml (>= 3.0.1))
  digestif
  (base64 (>= 3.0.0))
  cstruct
  (cohttp-eio (>= 6.3.0))
  http
  uri
  (tls (>= 2.1.3))
  (tls-eio (>= 2.1.3))
  (ca-certs (>= 1.0.3))
  (mirage-crypto-rng (>= 2.4.1))
  domain-name
  (tar (>= 3.5.0))
  (tar-eio (>= 3.5.0))
  (re (>= 1.9.0))
 ))
