#!/usr/bin/env emacs --script
;;; verify-test.el --- Verify the formatter works correctly

(load-file "/home/user/TryOutClaudeCode/type-formatter.el")

(defun verify-test (input-file expected-file)
  "Verify formatting INPUT-FILE produces EXPECTED-FILE."
  (let ((result-buffer (generate-new-buffer "*result*"))
        (expected-buffer (generate-new-buffer "*expected*"))
        (success t))

    (with-current-buffer result-buffer
      (insert-file-contents input-file)
      (type-formatter-format-buffer))

    (with-current-buffer expected-buffer
      (insert-file-contents expected-file))

    (let ((result (with-current-buffer result-buffer (buffer-string)))
          (expected (with-current-buffer expected-buffer (buffer-string))))

      (if (string= result expected)
          (message "✓ PASS: %s" input-file)
        (progn
          (message "✗ FAIL: %s" input-file)
          (message "\nEXPECTED:\n%s" expected)
          (message "\nGOT:\n%s" result)
          (setq success nil))))

    (kill-buffer result-buffer)
    (kill-buffer expected-buffer)

    success))

;; Run verification
(let ((all-pass t))
  (unless (verify-test "/home/user/TryOutClaudeCode/test1.txt"
                       "/home/user/TryOutClaudeCode/expected1.txt")
    (setq all-pass nil))

  (if all-pass
      (message "\n========================================\nALL TESTS PASSED\n========================================")
    (message "\n========================================\nSOME TESTS FAILED\n========================================")))
