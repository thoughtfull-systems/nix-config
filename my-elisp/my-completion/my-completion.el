;;; my-completion.el --- minibuffer completion  -*- lexical-binding: t; -*-

;; Copyright (c) 2023 Paul Stadig

;; Version: 0.0.0

;;; Commentary:

;; None

;;; Code:
(require 'use-package)

(use-package icomplete
  :bind
  (:map icomplete-minibuffer-map
        ("C-<return>" . icomplete-force-complete)
        ("<return>" . icomplete-force-complete-and-exit)))

(use-package orderless)

(deftheme my-completion)

(custom-theme-set-variables
 'my-completion
 '(completion-auto-help 'lazy)
 '(completion-category-overrides '((file (styles basic partial-completion orderless))))
 '(completion-cycle-threshold 3)
 '(completion-styles '(orderless))
 '(completions-detailed t)
 '(icomplete-show-matches-on-no-input t)
 '(icomplete-vertical-mode t)
 '(orderless-matching-styles
   '(orderless-regexp orderless-literal orderless-initialism orderless-prefixes))
 '(read-buffer-completion-ignore-case t)
 '(read-file-name-completion-ignore-case t))

(custom-theme-set-faces
 'my-completion
 '(completions-common-part ((t (:inherit orderless-match-face-0))))
 '(icomplete-selected-match ((t nil))))

(provide-theme 'my-completion)
(enable-theme 'my-completion)

(provide 'my-completion)
;;; my-completion.el ends here
