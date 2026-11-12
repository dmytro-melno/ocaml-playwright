(* What every way of taking a screenshot shares. *)

open Types

let mask (locators : locator list) : Protocol.Common_screenshot_options_mask.t list =
    List.map (fun (locator : locator) -> { Protocol.Common_screenshot_options_mask.frame = locator.l_frame.f_channel; selector = locator.selector }) locators
