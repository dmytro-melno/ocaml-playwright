(** URLs as browsers read them.

    A parser for the {{:https://url.spec.whatwg.org} URL Standard}, which is what JavaScript's
    [new URL(reference, base)] implements and therefore what a page reports as its address.  It
    serves the two places where this library must predict such an address: the URL that an
    assertion expects, and the globs that are resolved against a base URL.

    One part of the standard is left out: the Unicode preparation of host names (UTS 46).  A host
    name with characters outside ASCII is converted to Punycode as it is written, which is right
    when it is in lower case and normalised, as such names nearly always are. *)

type t

(** [parse ?base reference] is the URL that [reference] denotes, relative to [base] if it is
    relative, and [None] where [new URL] would throw: no scheme and no base, an invalid host or
    port, a [base] that is not a URL. *)
val parse : ?base:string -> string -> t option

(** The URL in its normal form: [href] in JavaScript. *)
val to_string : t -> string

(** The scheme, host and port for the schemes that have an origin (["http://example.com:8080"]),
    and ["null"] for the others, as [origin] in JavaScript. *)
val origin : t -> string

(** [resolve ?base reference] is the normal form of [reference], and [reference] itself if it
    cannot be parsed. *)
val resolve : ?base:string -> string -> string
