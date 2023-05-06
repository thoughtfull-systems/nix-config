;;; my.el --- General code and configuration  -*- lexical-binding: t; -*-

;; Copyright (c) 2023 Paul Stadig

;; Version: 0.0.0

;;; Commentary:

;; None

;;; Code:
(defvar my-custom-file "~/.config/emacs/custom.el")

(load my-custom-file t)

(defun my-switch-buffer (&optional prefix)
  (interactive "p")
  (if (eq prefix 4)
      (ibuffer)
    (call-interactively 'switch-to-buffer)))

(deftheme my)

(custom-theme-set-variables
 'my
 '(auto-save-visited-mode t)
 '(backup-directory-alist '(("." . "~/.config/emacs/backups")))
 '(custom-file my-custom-file)
 '(desktop-restore-frames nil)
 '(fringe-mode 1)
 '(global-whitespace-mode t)
 '(indent-tabs-mode nil)
 '(inhibit-startup-echo-area-message (getenv "USER"))
 '(inhibit-startup-screen t)
 '(menu-bar-mode nil)
 '(save-interprogram-paste-before-kill t)
 '(save-place-mode t)
 '(savehist-mode t)
 '(scroll-bar-mode nil)
 '(show-paren-delay 0.25)
 '(tool-bar-mode nil)
 '(whitespace-action '(auto-cleanup))
 '(whitespace-global-modes '(prog-mode))
 '(whitespace-line-column nil)
 '(whitespace-style '(face trailing lines-tail missing-newline-at-eof empty indentation
                           space-after-tab space-before-tab)))

(custom-theme-set-faces
 'my
 '(default ((t (:height 110 :family "Source Code Pro")))))

(provide-theme 'my)
(enable-theme 'my)

(provide 'my)
;;; my.el ends here
