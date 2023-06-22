;;; my-clojure-dev.el --- Clojure development configuration  -*- lexical-binding: t; -*-

;;  Copyright (c) 2023 Paul Stadig

;;  Version: 0.0.0

;;; Commentary:

;; None

;;; Code:

(require 'use-package)

(use-package my-dev)
(use-package cider
  :after clojure-mode)
(use-package clojure-mode
  :hook ((clojure-mode . paredit-mode)
         (clojure-mode . flycheck-mode)))
(use-package clojure-mode-extra-font-locking
  :after clojure-mode)
(use-package flycheck-clojure
  :after (clojure-mode flycheck))
(use-package flycheck-clj-kondo
  :after (flycheck-clojure)
  :init (flycheck-clojure-setup))

(deftheme my-clojure-dev)
(custom-theme-set-variables
 'my-clojure-dev
 '(cider-preferred-build-tool 'clojure-cli)
 '(cider-repl-history-file "~/.cider-history")
 '(nrepl-log-messages t))
(provide-theme 'my-clojure-dev)
(enable-theme 'my-clojure-dev)
(provide 'my-clojure-dev)
;;; my-clojure-dev.el ends here
