;;; test-formatter.el --- Test cider-format-maps.el -*- lexical-binding: t; -*-

;; Load the formatter
(load-file "cider-format-maps.el")

(defun test-format-map (input expected-output description)
  "Test cider-format-map with INPUT, expecting EXPECTED-OUTPUT."
  (let* ((result (cider-format-map input 3))
         (success (string= result expected-output)))
    (message "\n========================================")
    (message "TEST: %s" description)
    (message "INPUT:\n%s" input)
    (message "\nEXPECTED:\n%s" expected-output)
    (message "\nACTUAL:\n%s" result)
    (message "\nRESULT: %s" (if success "✓ PASS" "✗ FAIL"))
    success))

(defun run-all-tests ()
  "Run all formatter tests."
  (let ((tests-passed 0)
        (tests-failed 0))

    ;; Test 1: Simple map
    (if (test-format-map
         "{:a 1, :b 2}"
         "{:a 1,\n   :b 2}"
         "Simple map with two keys")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 2: Nested map
    (if (test-format-map
         "{:a {:b 1, :c 2}, :d 3}"
         "{:a {:b 1,\n       :c 2},\n   :d 3}"
         "Nested map")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 3: Empty map
    (if (test-format-map
         "{}"
         "{}"
         "Empty map (should remain unchanged)")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 4: String with comma (critical bug test)
    (if (test-format-map
         "{:a \"hello, world\", :b 2}"
         "{:a \"hello, world\",\n   :b 2}"
         "String containing comma (should not be split)")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 5: Complex nested from original example
    (if (test-format-map
         "{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}"
         "{:deft.deft-test/side1 1,\n   :deft.deft-test/side2 3,\n   :deft.deft-test/pos {:deft.deft-test/x 1,\n       :deft.deft-test/y 2,\n       :type :deft.deft-test/Position},\n   :type :deft.deft-test/Rectangle}"
         "Complex nested map from original example")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 6: Deeply nested
    (if (test-format-map
         "{:a {:b {:c 1}}}"
         "{:a {:b {:c 1}}}"
         "Deeply nested map with no commas")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 7: Map with trailing comma (edge case)
    (if (test-format-map
         "{:a 1,}"
         "{:a 1,}"
         "Map with trailing comma (should handle gracefully)")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 8: Non-map input (should return original)
    (if (test-format-map
         "[:a 1 :b 2]"
         "[:a 1 :b 2]"
         "Vector (should return unchanged)")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 9: String with multiple quotes
    (if (test-format-map
         "{:a \"hello\", :b \"world, foo\", :c 3}"
         "{:a \"hello\",\n   :b \"world, foo\",\n   :c 3}"
         "Multiple strings with commas")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Test 10: Map with no spaces after commas
    (if (test-format-map
         "{:a 1,:b 2,:c 3}"
         "{:a 1,\n   :b 2,\n   :c 3}"
         "No spaces after commas")
        (setq tests-passed (1+ tests-passed))
      (setq tests-failed (1+ tests-failed)))

    ;; Summary
    (message "\n========================================")
    (message "TEST SUMMARY")
    (message "========================================")
    (message "Tests passed: %d" tests-passed)
    (message "Tests failed: %d" tests-failed)
    (message "Total tests:  %d" (+ tests-passed tests-failed))
    (message "========================================")

    (if (= tests-failed 0)
        (message "\n✓ ALL TESTS PASSED!")
      (message "\n✗ SOME TESTS FAILED!"))

    ;; Exit with appropriate code
    (kill-emacs (if (= tests-failed 0) 0 1))))

;; Run tests
(run-all-tests)
