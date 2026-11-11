let () =
    Harness.run @@ fun t ->
    Alcotest.run ~and_exit:false "playwright (browser)" (Test_pages.tests t)
