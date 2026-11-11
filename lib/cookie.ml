(* Cookies, as the browser reports them and as they are given to it. *)

type same_site = [ `Strict | `Lax | `None ]

type t = {
    name : string;
    value : string;
    domain : string;
    path : string;
    expires : float;
    http_only : bool;
    secure : bool;
    same_site : same_site;
    partition_key : string option;
}

type init = Protocol.Set_network_cookie.t

let make ?url ?domain ?path ?expires ?http_only ?secure ?(same_site : same_site option) ?partition_key name ~value : init =
    { name; value; url; domain; path; expires; http_only; secure; same_site; partition_key; cr_has_cross_site_ancestor = None }

let to_init (c : t) : init =
    { name = c.name; value = c.value; url = None; domain = Some c.domain; path = Some c.path; expires = Some c.expires;
      http_only = Some c.http_only; secure = Some c.secure; same_site = Some c.same_site; partition_key = c.partition_key;
      cr_has_cross_site_ancestor = None }

let of_protocol (c : Protocol.Network_cookie.t) : t =
    { name = c.name; value = c.value; domain = c.domain; path = c.path; expires = c.expires; http_only = c.http_only; secure = c.secure;
      same_site = c.same_site; partition_key = c.partition_key }
