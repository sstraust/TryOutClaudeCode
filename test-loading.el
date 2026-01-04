;;; test-loading.el --- Check if formatter is loaded correctly

;; Test 1: Check if CIDER is available
(if (require 'cider-eval nil t)
    (message "✓ CIDER is loaded")
  (message "✗ CIDER is NOT loaded - formatter won't work without it"))

;; Test 2: Check if our functions are defined
(if (fboundp 'cider-format-map)
    (message "✓ cider-format-map function is defined")
  (message "✗ cider-format-map function is NOT defined"))

;; Test 3: Check if advice is attached
(if (advice-member-p #'cider-format-result 'cider--display-interactive-eval-result)
    (message "✓ Advice is attached to cider--display-interactive-eval-result")
  (message "✗ Advice is NOT attached"))

;; Test 4: Direct function test (without CIDER)
(if (fboundp 'cider-format-map)
    (let ((result (cider-format-map "{:a 1, :type :Foo, :b 2}" 3)))
      (message "Test result: %S" result)
      (if (string-prefix-p "{:type :Foo" result)
          (message "✓ Formatting function works correctly")
        (message "✗ Formatting function returned unexpected result")))
  (message "Cannot test - function not defined"))

(message "\n--- How to use ---")
(message "1. Start a CIDER REPL (M-x cider-jack-in)")
(message "2. In a Clojure buffer, evaluate: {:a 1 :type :Foo :b 2}")
(message "3. Press C-u C-x C-e (not just C-x C-e)")
(message "4. The result should be inserted formatted")
