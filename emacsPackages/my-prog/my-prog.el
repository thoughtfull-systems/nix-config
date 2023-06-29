;;; my-prog.el --- General programming code and configuration  -*- lexical-binding: t; -*-

;;  Copyright (c) 2023 Paul Stadig

;;  Version: 0.0.0

;;; Commentary:

;; None

;;; Code:

(require 'use-package)
(use-package company
  :hook (prog-mode . company-mode))
(use-package display-line-numbers
  :hook (prog-mode . display-line-numbers-mode))
(use-package eldoc
  :hook ((clojure-mode . eldoc-mode)
         (emacs-lisp-mode . eldoc-mode)))
(use-package emacs-lisp
  :hook (emacs-lisp-mode . eldoc-mode))
(use-package flycheck
  :after (prog-mode)
  :bind (:map prog-mode-map
              ("C-c e n" . flycheck-next-error)
              ("C-c e p" . flycheck-previous-error))
  :commands (flycheck-next-error flycheck-previous-error)
  :hook (prog-mode . flycheck-mode))
(use-package flycheck-pos-tip
  :after (flycheck)
  :commands (flycheck-pos-tip-mode)
  :config (flycheck-pos-tip-mode)
  :if (display-graphic-p)
  ;; :config
  ;; (setq flycheck-display-errors-function #'flycheck-pos-tip-error-messages)
  )
(use-package flyspell
  :hook (prog-mode . flyspell-prog-mode))
(use-package imenu
  :bind (("C-c i" . imenu)
         ("C-c C-i" . imenu)))
(use-package magit-extras)
(use-package paredit
  :hook (emacs-lisp-mode . paredit-mode))

(deftheme my-prog)

(custom-theme-set-variables
 'my-prog
 '(display-line-numbers-minor-tick 10)
 '(display-line-numbers-width-start t)
 ;; electric-indent-mode swaps the default behavior of C-j and RET which is confusing, I prefer the
 ;; default behavior.
 '(electric-indent-mode nil)
 '(emacs-lisp-docstring-fill-column 80)
 '(fill-column 100)
 '(flycheck-emacs-lisp-load-path 'inherit)
 '(sh-basic-offset 2))

(provide-theme 'my-prog)
(enable-theme 'my-prog)

(provide 'my-prog)
;;; my-prog.el ends here
