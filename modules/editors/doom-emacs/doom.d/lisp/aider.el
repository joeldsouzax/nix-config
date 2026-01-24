;;; lisp/aider.el --- Aider Interface with Transient & TypeScript Support -*- lexical-binding: t; -*-

(require 'comint)
(require 'project)
(require 'transient)
(require 'json)

(defgroup aider nil
  "Aider AI coding assistant."
  :group 'tools)


(defcustom aider-program "aider"
  "Name of the aider binary (uses wrapper from flake)."
  :type 'string
  :group 'aider)

(defcustom aider-context-file ".aider.arch.md"
  "File to store architectural conext and current task."
  :type 'string
  :group 'aider)

(defvar aider-buffer-name "*aider*")


;;; --- 1. Core Process Management ---

(define-derived-mode aider-mode comint-mode "Aider"
  "Major mode for interactions with Aider."
  (setq comint-prompt-regexp "^> ")
  (setq comint-process-echoes nil)
  (setq comint-scroll-to-bottom-on-input t)
  (setq comint-scroll-to-bottom-on-output t))

(defun aider--ensure-running ()
  "Ensure the aider process is running."
  (let* ((buffer (get-buffer aider-buffer-name))
         (proc (and buffer (get-buffer-process buffer))))
    (unless (and proc (process-live-p proc))
      (let* ((proj (project-current t))
             (root (project-root proj))
             (default-directory root))
        (setq buffer (make-comint-in-buffer "aider" aider-buffer-name aider-program nil))
        (with-current-buffer buffer
          (aider-mode))))
    buffer))

(defun aider-send (text &optional echo)
  "Send TEXT to the aider process."
  (let ((buffer (aider--ensure-running)))
    (with-current-buffer buffer
      (goto-char (process-mark (get-buffer-process buffer)))
      (insert text)
      (comint-send-input))
    (when echo (message "Aider: %s" echo))))

(defun aider-switch-to-buffer ()
  "Open the aider buffer in a split window."
  (interactive)
  (pop-to-buffer (aider--ensure-running)))

;;; --- 2. Helper Functions ---

(defun aider--list-modules ()
  "List all modules in libs/modules/."
  (let ((modules-dir (expand-file-name "libs/modules" (project-root (project-current t)))))
    (when (file-directory-p modules-dir)
      (seq-filter (lambda (f) (not (string-prefix-p "." f)))
                  (directory-files modules-dir nil nil t)))))

;;; --- 3. File Opertaions ---

(defun aider-add-current-file ()
  "Add current file to aider context."
  (interactive)
  (if-let ((file (buffer-file-name)))
      (aider-send (concat "/add " file) (format "Added %s" (file-name-nondirectory file)))
    (message "Buffer is not visiting a file")))

(defun aider-drop-file ()
  "Remove current file from aider context."
  (interactive)
  (if-let ((file (buffer-file-name)))
      (aider-send (concat "/drop " file) (format "Dropped %s" (file-name-nondirectory file)))
    (message "Buffer is not visiting a file")))

(defun aider-add-module ()
  "Add entire module to context (for libs/modules/* work)."
  (interactive)
  (let ((module (completing-read "Module: " (aider--list-modules))))
    (aider-send (format "/add libs/modules/%s/**/*.ts" module)
                (format "Added module '%s'" module))))

;;; --- 4. Context Management (.aider.arch.md) ---

;;; --- 4. Context Management (.aider.arch.md) ---

(defun aider--find-adr-files (adr-numbers)
  "Given a string like '001, 003', return list of matching file paths."
  (let* ((root (project-root (project-current t)))
         (adr-dir (expand-file-name "docs/decisions" root))
         (files '()))
    (dolist (num (split-string adr-numbers "[^0-9]+" t))
      ;; Find files starting with the number (e.g. "001-*.md")
      (let ((matches (directory-files adr-dir t (format "^%s-.*\\.md$" num))))
        (when matches
          (push (car matches) files))))
    files))

(defun aider-set-context ()
  "Set task context and AUTO-LOAD referenced ADRs."
  (interactive)
  (let* ((task (read-string "Task description: "))
         (module (completing-read "Module (or 'multiple'): " (cons "None" (aider--list-modules))))
         (pattern (completing-read "Pattern: "
                                   '("Stateful DDD Aggregate"
                                     "Hybrid ES"
                                     "CQRS Query"
                                     "CQRS Command"
                                     "React Router Loader"
                                     "Infrastructure"
                                     "Other")))
         (adrs (read-string "Related ADRs (e.g. '001, 005'): "))
         ;; FORMATTING CHANGED: Matches your new markdown style
         (context-str (format "- **Task:** %s\n- **Module:** %s\n- **Pattern:** %s\n- **Related ADRs:** %s"
                              task module pattern adrs))
         (file (expand-file-name aider-context-file (project-root (project-current t)))))

    ;; Update context in .aider.arch.md
    (with-temp-file file
      (if (file-exists-p file)
          (insert-file-contents file)
        (insert "⚡ System Directives\n\n")) ;; Fallback header if empty
      
      (goto-char (point-min))
      
      ;; CRITICAL FIX: Looks for the correct 📍 header
      (if (re-search-forward "^📍 Current Focus" nil t)
          (delete-region (match-beginning 0) (point-max))
        (goto-char (point-max)))
      
      ;; Re-insert header and new content
      (insert "\n📍 Current Focus (Update Per Session)\n\n")
      (insert context-str)
      (insert "\n"))

    ;; Reset and Load
    (aider-send "/clear" "Cleared session history")
    (aider-send (concat "/add " aider-context-file) "Context Updated")

    ;; Auto-load ADRs
    (let ((adr-files (aider--find-adr-files adrs)))
      (dolist (adr adr-files)
        (aider-send (concat "/add " adr) (format "Loaded ADR: %s" (file-name-nondirectory adr))))
      
      (when (not adr-files)
        (message "Context set (No ADR files found for '%s')" adrs)))))



(defun aider-clear-context ()
  "Clear current task context."
  (interactive)
  (aider-send "/clear")
  (message "Context cleared"))

(defun aider-refresh-context ()
  "Regenerate Effect-TS context via Justfile."
  (interactive)
  (start-process "just-context" "*aider-context*" "just" "context")
  (message "🔮 Aider context refreshed from node_modules"))

;; Hook into your menu or run manually
(transient-define-prefix aider-menu ()
  "Aider AI Developer Dashboard"
  ["Actions"
   ("c" "Refresh Context (Fix Types)" aider-refresh-context)
   ;; ... existing commands ...
   ])

;; --- 5. Prompts & ADRs ---

(defun aider-implement-feature ()
  (interactive)
  (let ((feature (read-string "Feature: ")))
    (aider-send (format "Implement feature: %s. Follow our hexagonal architecture. Use Effect-TS for business logic. Add proper error handling." feature))))

(defun aider-fix-bug ()
  (interactive)
  (let ((bug (read-string "Bug description: ")))
    (aider-send (format "Fix bug: %s. Ensure type safety. Add tests to prevent regression." bug))))

(defun aider-refactor-effect ()
  (interactive)
  (let ((desc (read-string "What to refactor: ")))
    (aider-send (format "Refactor %s to use Effect-TS patterns. Use Effect.gen, TaggedError, and conventions from .aider.arch.md" desc))))

(defun aider-update-adr ()
  (interactive)
  (let* ((adr-dir (expand-file-name "docs/decisions" (project-root (project-current t))))
         (adr (completing-read "ADR to update: " (directory-files adr-dir nil "\\.md$")))
         (change (read-string "What changed? ")))
    (aider-send (format "/add %s/%s" adr-dir adr))
    (aider-send (format "Update ADR %s: %s. Maintain ADR format (Status, Context, Decision, Consequences)." adr change))))

(defun aider-create-adr ()
  (interactive)
  (let ((title (read-string "ADR Title: "))
        (context (read-string "Context: ")))
    (aider-send (format "Create new ADR: '%s'. Context: %s. Use standard ADR format. Reference existing ADRs." title context))))

;;; --- 6. The Transient Menu ---

(transient-define-prefix aider-menu ()
  "Aider AI Developer Dashboard"
  ["Context Management"
   ("c" "Set Task Focus" aider-set-context)
   ("C" "Clear Context" aider-clear-context)
   ("a" "Add Current File" aider-add-current-file)
   ("d" "Drop File" aider-drop-file)
   ("m" "Add Module" aider-add-module)]

  ["Generators (Effect-TS)"
   ("f" "Implement Feature" aider-implement-feature)
   ("b" "Fix Bug" aider-fix-bug)
   ("e" "Refactor Effect" aider-refactor-effect)
   ("t" "Add Tests" (lambda () (interactive) (aider-send "Add comprehensive Effect.test units.")))]

  ["Architecture"
   ("u" "Update ADR" aider-update-adr)
   ("n" "New ADR" aider-create-adr)]

  ["Control"   
   ("g" "Open Magit" magit-status) 
   ("s" "Show Terminal" aider-switch-to-buffer)]
  )

(provide 'aider)
