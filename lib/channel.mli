(** The objects of the driver, each known by the interface that it implements.

    A channel is the client's end of an object that lives in the driver.  The connection keeps
    channels of whatever interface ({!any}); everything else works with channels of a known
    one ({!t}), so that a command of a frame cannot be sent to a browser.  {!Protocol} is
    generated on top of this vocabulary. *)

type conn = Connection.t

type any = Connection.channel
(** An object of whatever interface. *)

type -'kind t
(** An object of a known interface.  ['kind] holds a tag for the interface and for each of those
    that it extends, as in [[ `Js_handle | `Element_handle ] t].  Such a channel is accepted
    wherever a [[> `Js_handle ] t] is asked for, and can be coerced to a [[ `Js_handle ] t]. *)

type 'kind kind
(** Tells the objects of an interface from the others. *)

val kind : string list -> 'kind kind
(** For {!Protocol} only, which pairs each kind with its type: the name of the interface, followed
    by the names of those that extend it.  Nothing else gives an interface to a channel. *)

(** {1 From objects of whatever interface} *)

val of_any : 'kind kind -> any -> 'kind t option
val narrow : 'kind kind -> _ t -> 'kind t option

val of_json : 'kind kind -> conn -> Json.t -> 'kind t
(** The object that a message refers to.  Raises {!Error.E} if there is no such object, or if it
    is of another interface: the driver and the client then disagree about the protocol. *)

val any_of_json : conn -> Json.t -> any

(** {1 And back} *)

val any : _ t -> any
val to_json : _ t -> Json.t
val any_to_json : any -> Json.t

(** {1 Objects} *)

val conn : _ t -> conn
val guid : _ t -> string

val is_disposed : _ t -> bool
(** Whether the driver has let go of the object. *)

val parent : 'kind kind -> _ t -> 'kind t option
(** The object that owns this one, if it is of that interface. *)

val ancestor : 'kind kind -> _ t -> 'kind t option
(** The nearest of the objects that own this one, directly or not, that is of that interface. *)

val initializer_ : _ t -> Json.t
(** What the driver announced the object with.  It is kept until the client side of the object is
    built, and for good for objects that have none: see {!Connection.channel}. *)

val listen : _ t -> (string -> Json.t -> unit) -> unit
(** Has the events of the object handled, in place of whatever handled them before.  The handler
    runs in the fiber that reads the messages of the driver: it must not wait for the driver. *)

val on_lost : _ t -> (Error.t -> unit) -> unit
(** What to do when the object goes away with its connection, or with one of its owners, in place
    of what was to be done before. *)

(** {1 Commands} *)

val call : ?timeout:float -> ?orphan:('a -> unit) -> ?abortable:bool -> _ t -> string -> Json.t -> (Json.t -> 'a) -> 'a
(** See {!Connection.call}. *)

val release : ?params:Json.t -> string -> _ t -> unit
(** Gives back what a cancelled command made, with the command of that name.  Nobody is there to
    hear that it could not be done. *)
