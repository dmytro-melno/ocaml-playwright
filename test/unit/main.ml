let () = Alcotest.run "playwright (unit)" (Test_wire.tests @ Test_ownership.tests @ Test_process.tests @ Test_events.tests @ Test_values.tests @ Test_support.tests)
