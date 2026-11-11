let () =
    Harness.run @@ fun t ->
    Alcotest.run ~and_exit:false "playwright (browser)" (Test_pages.tests t @ Test_locators.tests t @ Test_events.tests t @ Test_network.tests t)
