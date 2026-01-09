;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; -------------------- 1. PERSONAL INFORMATION --------------------
(setq user-full-name "Joel DSouza"
      user-mail-address "joeldsouzax@gmail.com")

;; -------------------- 2. DOOM UI & THEME --------------------
(setq doom-theme 'doom-one
      display-line-numbers-type t
      doom-themes-padded-modeline t
      doom-modeline-enable-word-count t
      doom-modeline-battery t)

(add-to-list 'default-frame-alist '(undecorated-round . t))

;; -------------------- 3. ORG MODE --------------------
(setq org-directory "~/org"
      org-ellipsis " ▼ ")

(use-package! mermaid-ts-mode)
(use-package! ob-mermaid)

;; -------------------- 4. TREEMACS (FILE EXPLORER) --------------------
(setq treemacs-project-follow-cleanup t
      treemacs-project-follow-mode t    ; VSCode behavior: auto-scroll to file
      treemacs-peek-mode t
      treemacs-fringe-indicator-mode t
      treemacs-show-cursor t
      treemacs-space-between-root-nodes nil)

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-nerd-icons
  :after treemacs
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package lsp-treemacs :after treemacs)

(after! (treemacs projectile)
  (treemacs-indent-guide-mode 1))

;; -------------------- 5. LSP UI (HOVER/DOCS) --------------------
(after! lsp-ui
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-position 'top-right-corner
        lsp-ui-doc--highlight-ov t
        lsp-ui-peek-show-directory t
        lsp-ui-imenu-enable t
        lsp-ui-imenu-buffer-mode t
        lsp-ui-imenu-buffer-position 'top-edge
        lsp-ui-imenu-auto-refresh t
        lsp-ui-peek-always-show t
        lsp-ui-sideline-show-symbol t
        lsp-ui-sideline-show-code-actions t
        lsp-ui-sideline-show-hover t))

;; -------------------- 6. RUST CONFIGURATION (POWER USER) --------------------
(after! rust-mode
  (setq rust-format-on-save t))

(after! rustic
  (setq rustic-lsp-server 'rust-analyzer)
  (setq rustic-format-on-save t)
  ;; Check everything on save so you don't miss broken tests/benches
  (setq rustic-cargo-check-arguments '("--benches" "--tests" "--all-features"))

  ;; --- 1. VISUAL "X-RAY" HINTS (INLAY HINTS) ---
  ;; These show you what the compiler "sees" invisible to the naked eye.
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  
  ;; Show the inferred type of longer chains (e.g. .iter().map().collect())
  (setq lsp-rust-analyzer-display-chaining-hints t)
  
  ;; Show what a closure returns (helps debug "type mismatch" errors in async blocks)
  (setq lsp-rust-analyzer-display-closure-return-type-hints t)
  
  ;; Show names of parameters in function calls (like Python kwargs)
  (setq lsp-rust-analyzer-display-parameter-hints t)
  
  ;; Show if a variable is a Reference (&), Mutable Reference (&mut), or Move
  (setq lsp-rust-analyzer-binding-mode-hints t)
  
  ;; Show implicit reborrows (helps understand borrow checker magic)
  (setq lsp-rust-analyzer-display-reborrow-hints t)
  
  ;; Show lifetimes, but only when they are confusing/non-trivial
  (setq lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")

  ;; --- 2. MEMORY LAYOUT & OPTIMIZATION ---
  ;; In the hover popup, show Struct Size, Align, and Padding bytes.
  ;; Essential for making "better decisions" about memory layout.
  (setq lsp-rust-analyzer-hover-actions-enable t)

  ;; --- 3. INTERACTIVE "CODE LENS" ---
  ;; This adds "Run | Debug" buttons directly above tests and main()
  ;; and shows reference counts ("3 refs") above functions.
  (add-hook 'rustic-mode-hook #'lsp-lens-mode))

;; --- 4. HUD (HEADS UP DISPLAY) CONFIGURATION ---
(after! lsp-ui
  ;; Make the sidebar info snappy and rich
  (setq lsp-ui-sideline-show-diagnostics t)  ; Show errors on the right
  (setq lsp-ui-sideline-show-hover t)        ; Show type info on the right
  (setq lsp-ui-sideline-show-code-actions t) ; Show "Quick Fix" lightbulbs
  (setq lsp-ui-sideline-delay 0.1)           ; Update almost instantly
  
  ;; Documentation Popup
  (setq lsp-ui-doc-enable t)
  (setq lsp-ui-doc-position 'top-right-corner)
  (setq lsp-ui-doc-max-width 80)
  (setq lsp-ui-doc-max-height 20)
  (setq lsp-ui-doc-delay 0.2))

;; -------------------- 7. NIX CONFIGURATION --------------------
(after! nix-mode
  ;; Format with 'alejandra' (the modern standard) or 'nixfmt'
  ;; Ensure you have 'alejandra' installed: `nix profile install nixpkgs#alejandra`
  (set-formatter! 'alejandra
    '("alejandra" "--quiet" "-")
    :modes '(nix-mode))
  
  ;; Use 'nil' (Nix Language Server) for superior Flake support
  ;; Ensure installed: `nix profile install nixpkgs#nil`
  (setq lsp-disabled-clients '(nix-rnix-lsp)) ;; Disable old rnix
  (add-to-list 'lsp-language-id-configuration '(nix-mode . "nix"))
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection '("nil"))
                    :major-modes '(nix-mode)
                    :priority 1
                    :server-id 'nix-nil)))

;; -------------------- 8. WEB DEV (VSCODE-LIKE SETUP) --------------------
;;

;; ---------------------------------------------------------------------
;; 1. FORCE MODE MAPPING (Crucial for Nix setups)
;; ---------------------------------------------------------------------
;; Because you injected "with-all-grammars", the libraries are there.
;; We just need to tell Emacs to use the modern modes for these files.
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.mjs\\'" . js-ts-mode))

;; ---------------------------------------------------------------------
;; 2. NX MONOREPO FIXES
;; ---------------------------------------------------------------------
(after! lsp-mode
  ;; Nx uses a root tsconfig.base.json. If LSP picks a sub-project root,
  ;; imports will fail. This forces it to look up the directory tree.
  (setq lsp-auto-guess-root t)
  
  ;; Ignore Nx build artifacts to save CPU
  (setq lsp-file-watch-ignored-directories
        (append lsp-file-watch-ignored-directories
                '("[/\\\\]\\.rx\\'" "[/\\\\]dist\\'" "[/\\\\]coverage\\'" ))))

;;; config.el

;; ---------------------------------------------------------------------
;; 3. VITEST INTEGRATION (Via jest-test-mode)
;; ---------------------------------------------------------------------
(use-package! jest-test-mode
  :commands jest-test-mode
  :hook (typescript-ts-mode js-ts-mode tsx-ts-mode) 
  :config
  ;; CRITICAL: Tell it to run 'vitest' instead of 'jest'
  (setq jest-test-command-string "npx vitest") 
  
  ;; Optional: Add " -- run" if you want it to run once and exit, 
  ;; or leave as "npx vitest" to open the watch mode.
  ;; For Emacs integration, running once is usually better for "run at point":
  ;; (setq jest-test-command-string "npx vitest run") 

  (map! :map (typescript-ts-mode-map tsx-ts-mode-map js-ts-mode-map)
        :localleader
        (:prefix ("t" . "testing")
                 "v" #'jest-test-mode        ; Enable the minor mode manually if needed
                 "r" #'jest-test-run         ; Run all tests in file
                 "t" #'jest-test-run-at-point ; Run specific test under cursor
                 "d" #'jest-test-debug)))
;; ---------------------------------------------------------------------
;; 4. UPDATE PRETTIER
;; ---------------------------------------------------------------------
;; Ensure Prettier runs on the new tree-sitter modes
(set-formatter! 'prettier-mode
  '("npx" "prettier" "--stdin-filepath" filepath)
  :modes '(typescript-ts-mode tsx-ts-mode js-ts-mode))



;; ---------------------------------------------------------------------
;; B. TYPESCRIPT / REACT / NEXT.JS (UPDATED FOR TREE-SITTER)
;; ---------------------------------------------------------------------

(after! typescript-ts-mode
  ;; 1. Connect LSP automatically
  (add-hook 'typescript-ts-mode-hook #'lsp!) 
  
  ;; 2. Set specific options
  (setq lsp-clients-typescript-server-args '("--stdio")
        lsp-typescript-suggest-auto-imports t
        lsp-typescript-surveys-enabled nil
        typescript-ts-mode-indent-offset 2)) ;; Ensure 2-space indent

(after! tsx-ts-mode
  (add-hook 'tsx-ts-mode-hook #'lsp!)
  (setq lsp-clients-typescript-server-args '("--stdio")
        lsp-typescript-suggest-auto-imports t
        lsp-typescript-surveys-enabled nil
        typescript-ts-mode-indent-offset 2))
;; ---------------------------------------------------------------------
;; C. TAILWIND CSS
;; ---------------------------------------------------------------------
(use-package! lsp-tailwindcss
  :init
  (setq lsp-tailwindcss-add-on-mode t)
  :config
  (add-to-list 'lsp-tailwindcss-major-modes 'typescript-ts-mode)
  (add-to-list 'lsp-tailwindcss-major-modes 'tsx-ts-mode)
  (add-to-list 'lsp-tailwindcss-major-modes 'js-ts-mode)
  
  ;; Keep these if you still open older file types
  (add-to-list 'lsp-tailwindcss-major-modes 'astro-ts-mode)
  (add-to-list 'lsp-tailwindcss-major-modes 'web-mode))

;; ---------------------------------------------------------------------
;; D. NESTJS / MIKROORM (DECORATORS)
;; ---------------------------------------------------------------------
(setq lsp-javascript-implicit-project-config-experimental-decorators t)

;; ---------------------------------------------------------------------
;; E. ASTRO & GRAMMARS (NIX OPTIMIZED)
;; ---------------------------------------------------------------------
(use-package! astro-ts-mode
  :after lsp-mode
  :config
  (setq astro-ts-mode-indent-offset 2)
  ;; Map .astro files to this mode
  (add-to-list 'auto-mode-alist '("\\.astro\\'" . astro-ts-mode)))




;; F. Misc Web Modes
;; ---------------------------------------------------------------------
(use-package! nginx-mode
  :defer t)


;; MDX Support
(add-to-list 'auto-mode-alist '("\\.\\(mdx\\)$" . markdown-mode))
(when (modulep! +lsp)
  (add-hook 'markdown-mode-local-vars-hook #'lsp! 'append))


(after! lsp-mode
  ;; Force lsp-mode to use the wrapper executable
  (defun lsp-booster--advice-json-parse (old-fn &rest args)
    "Try to parse bytecode instead of json."
    (or (when (equal (following-char) ?#)
          (let ((bytecode (read (current-buffer))))
            (when (byte-code-function-p bytecode)
              (funcall bytecode))))
        (apply old-fn args)))
  (advice-add (if (progn (require 'json)
                         (fboundp 'json-parse-buffer))
                  'json-parse-buffer
                'json-read)
              :around
              #'lsp-booster--advice-json-parse)

  (defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
    "Prepend emacs-lsp-booster command to lsp CMD."
    (let ((orig-result (funcall old-fn cmd test?)))
      (if (and (not test?)                             ;; for check-if-supported
               (not (file-remote-p default-directory)) ;; see lsp-booster#3
               (executable-find "emacs-lsp-booster"))
          (progn
            (message "Using emacs-lsp-booster for %s!" (car orig-result))
            (cons "emacs-lsp-booster" orig-result))
        orig-result)))
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command))



(use-package! just-mode
  :config
  (map! :map just-mode-map
        "C-c C-c" #'just-command-run-recipe))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
