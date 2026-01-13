;;; test-elisp.el --- Test the Emacs Lisp formatter directly -*- lexical-binding: t; -*-

(load-file "cider-format-maps.el")

(defun test-format (input expected description)
  "Test formatting INPUT against EXPECTED with DESCRIPTION."
  (let* ((result (cider-format-map input 3))
         (pass (string= result expected)))
    (message "\n%s" (make-string 70 ?=))
    (message "TEST: %s" description)
    (message "INPUT:\n%s" input)
    (message "\nEXPECTED:")
    (dolist (line (split-string expected "\n"))
      (message "=> %s" line))
    (message "\nACTUAL:")
    (dolist (line (split-string result "\n"))
      (message "=> %s" line))
    (message "\nRESULT: %s" (if pass "✓ PASS" "✗ FAIL"))
    pass))

(defun run-tests ()
  "Run all formatter tests."
  (let ((passed 0)
        (failed 0))

    ;; Test 1: Simple map without :type
    (if (test-format
         "{:a 1, :b 2}"
         "{:a 1,\n    :b 2}"
         "Simple map - order preserved")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Test 2: Map with :type at end
    (if (test-format
         "{:a 1, :b 2, :type :Foo}"
         "{:type :Foo,\n    :a 1,\n    :b 2}"
         "Map with :type at end - :type moves to front, others keep order")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Test 3: Map with :type in middle
    (if (test-format
         "{:a 1, :type :Foo, :b 2, :c 3}"
         "{:type :Foo,\n    :a 1,\n    :b 2,\n    :c 3}"
         "Map with :type in middle - preserves order of :a, :b, :c")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Test 4: Empty map
    (if (test-format
         "{}"
         "{}"
         "Empty map")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Test 5: String with comma
    (if (test-format
         "{:a \"hello, world\", :b 2}"
         "{:a \"hello, world\",\n    :b 2}"
         "String with comma - not broken")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Test 6: Nested maps with :type
    (if (test-format
         "{:x {:a 1, :type :A}, :y {:b 2, :type :B}, :type :Root}"
         "{:type :Root,\n    :x {:type :A,\n        :a 1},\n    :y {:type :B,\n        :b 2}}"
         "Nested maps - :type first at each level")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Test 7: Complex example
    (if (test-format
         "{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}"
         "{:type :deft.deft-test/Rectangle,\n    :deft.deft-test/side1 1,\n    :deft.deft-test/side2 3,\n    :deft.deft-test/pos {:type :deft.deft-test/Position,\n                         :deft.deft-test/x 1,\n                         :deft.deft-test/y 2}}"
         "Complex example - order preserved, :type first, aligned")
        (setq passed (1+ passed))
      (setq failed (1+ failed)))

    ;; Summary
    (message "\n%s" (make-string 70 ?=))
    (message "SUMMARY: %d passed, %d failed" passed failed)
    (message "%s" (make-string 70 ?=))

    (if (= failed 0)
        (progn
          (message "\n✓ ALL TESTS PASSED!")
          (kill-emacs 0))
      (progn
        (message "\n✗ SOME TESTS FAILED!")
        (kill-emacs 1)))))

(run-tests)
