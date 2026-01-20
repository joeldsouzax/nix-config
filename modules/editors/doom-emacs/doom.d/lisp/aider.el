;;; aider.el --- 

(require 'comint)
(require 'project)

(defgroup aider nil
  "Aider AI coding assistant."
  :group tools)


(defcustom aider-program "aider"
  "Name of the aider binary"
  :type 'string
  :group 'aider)

(defvar aider-buffer-name "*aider*")

(define-derived-mode aider-mode comint-mode "Aider"
  "Major mode for interactions with Aider."
  (setq comint-prompt-regexp "^> ")
  (setq comint-process-echoes nil))

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


(defun aider-open ()
  "Open the aider buffer."
  (interactive)
  (pop-to-buffer (aider--ensure-running)))

(defun aider-ping ()
  "Send a test message."
  (interactive)
  (let (( buffer (aider--ensure-running)))
    (with-current-buffer buffer
      (goto-char (process-mark (get-buffer-process buffer)))
      (insert "/help")
      (comint-send-input))))

(provide 'aider)
