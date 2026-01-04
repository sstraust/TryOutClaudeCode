;;; cider-format-maps.el --- Format Clojure maps in CIDER output -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: Your Name
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (cider "1.0"))
;; Keywords: clojure, cider, formatting

;;; Commentary:

;; This package provides automatic formatting of Clojure maps in CIDER output.
;; When evaluating expressions with C-x C-e, maps will be formatted with proper
;; indentation while preserving syntax highlighting and other CIDER features.

;;; Code:

(require 'cider-eval)
(require 'cider-overlays)

(defgroup cider-format-maps nil
  "Automatic formatting of Clojure maps in CIDER output."
  :group 'cider)

(defcustom cider-format-maps-enabled t
  "Whether to enable automatic map formatting in CIDER output."
  :type 'boolean
  :group 'cider-format-maps)

(defun cider-format-maps--format-map-string (str)
  "Format a Clojure map string STR with proper indentation.
This function parses the map and formats it with each key-value
pair on a new line, properly indented."
  (if (not (string-match-p "^{" (string-trim str)))
      str
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (let ((indent-stack '())  ; Stack to track indentation positions
            (result "")
            (current-indent 0))
        (while (not (eobp))
          (let ((char (char-after)))
            (cond
             ;; Opening brace
             ((eq char ?{)
              (setq result (concat result (string char)))
              ;; Push current position for alignment
              (push (length result) indent-stack)
              (setq current-indent (+ current-indent 2))
              (forward-char)
              ;; Add newline and indent after opening brace if followed by keyword
              (when (looking-at "[ \t]*:")
                (skip-chars-forward " \t")
                (setq result (concat result "\n" (make-string current-indent ?\s)))))

             ;; Closing brace
             ((eq char ?})
              (when indent-stack
                (pop indent-stack)
                (setq current-indent (max 0 (- current-indent 2))))
              (setq result (concat result (string char)))
              (forward-char))

             ;; Comma - trigger newline and indent
             ((eq char ?,)
              (setq result (concat result ", "))
              (forward-char)
              ;; Skip whitespace after comma
              (skip-chars-forward " \t")
              ;; Add newline and indentation unless we're at end or closing brace
              (unless (or (eobp) (eq (char-after) ?}))
                (setq result (concat result "\n" (make-string current-indent ?\s)))))

             ;; Regular character
             (t
              (setq result (concat result (string char)))
              (forward-char)))))
        result))))

(defun cider-format-maps--should-format-p (value)
  "Return non-nil if VALUE should be formatted as a map."
  (and cider-format-maps-enabled
       (stringp value)
       (string-match-p "^{.*}$" (string-trim value))
       ;; Check if it's actually a map (contains colons for keywords)
       (string-match-p ":" value)))

(defvar cider-format-maps--original-insert-eval-result nil
  "Original function definition for `cider--display-interactive-eval-result'.")

(defun cider-format-maps--display-result-advice (value &rest args)
  "Advice for formatting map results.
VALUE is the result to display, ARGS are additional arguments."
  (let ((formatted-value
         (if (cider-format-maps--should-format-p value)
             (cider-format-maps--format-map-string value)
           value)))
    (apply cider-format-maps--original-insert-eval-result formatted-value args)))

;;;###autoload
(defun cider-format-maps-enable ()
  "Enable automatic map formatting in CIDER output."
  (interactive)
  (setq cider-format-maps-enabled t)
  (when (fboundp 'cider--display-interactive-eval-result)
    (advice-add 'cider--display-interactive-eval-result
                :around #'cider-format-maps--wrap-display-result))
  (message "CIDER map formatting enabled"))

;;;###autoload
(defun cider-format-maps-disable ()
  "Disable automatic map formatting in CIDER output."
  (interactive)
  (setq cider-format-maps-enabled nil)
  (advice-remove 'cider--display-interactive-eval-result
                 #'cider-format-maps--wrap-display-result)
  (message "CIDER map formatting disabled"))

(defun cider-format-maps--wrap-display-result (orig-fun value &rest args)
  "Wrap ORIG-FUN to format VALUE before display.
ARGS are passed through to the original function."
  (let ((formatted-value
         (if (cider-format-maps--should-format-p value)
             (cider-format-maps--format-map-string value)
           value)))
    (apply orig-fun formatted-value args)))

;;;###autoload
(define-minor-mode cider-format-maps-mode
  "Minor mode for automatic Clojure map formatting in CIDER."
  :global t
  :group 'cider-format-maps
  :lighter " CiderFmt"
  (if cider-format-maps-mode
      (cider-format-maps-enable)
    (cider-format-maps-disable)))

;; Auto-enable when CIDER is loaded
;;;###autoload
(with-eval-after-load 'cider
  (cider-format-maps-enable))

(provide 'cider-format-maps)
;;; cider-format-maps.el ends here
