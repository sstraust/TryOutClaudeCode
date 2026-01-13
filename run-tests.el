#!/usr/bin/env emacs --script
;;; run-tests.el --- Test the type formatter

(add-to-list 'load-path "/home/user/TryOutClaudeCode")
(require 'type-formatter)

(setq type-formatter-debug t)

(defun test-formatter-on-file (filename)
  "Test formatter on FILENAME and show before/after."
  (message "\n========================================")
  (message "Testing: %s" filename)
  (message "========================================")

  (with-temp-buffer
    (insert-file-contents filename)
    (let ((before (buffer-string)))
      (message "\nBEFORE:\n%s" before)

      (goto-char (point-min))
      (condition-case err
          (progn
            (type-formatter-format-buffer)
            (let ((after (buffer-string)))
              (message "\nAFTER:\n%s" after)
              (if (string= before after)
                  (message "\n✗ NO CHANGE")
                (message "\n✓ CHANGED"))))
        (error
         (message "\n✗ ERROR: %s" err))))))

;; Run tests
(message "Starting formatter tests...\n")

(test-formatter-on-file "/home/user/TryOutClaudeCode/test1.txt")
(test-formatter-on-file "/home/user/TryOutClaudeCode/test2.txt")
(test-formatter-on-file "/home/user/TryOutClaudeCode/test3.txt")
(test-formatter-on-file "/home/user/TryOutClaudeCode/test4.txt")

(message "\n========================================")
(message "Tests complete")
(message "========================================")
