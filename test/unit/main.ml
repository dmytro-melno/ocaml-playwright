let () = Alcotest.run "playwright (unit)" (Test_wire.tests @ Test_values.tests @ Test_support.tests)
