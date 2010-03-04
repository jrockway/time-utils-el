;;; flowtimer.el --- let yourself work in sprints

;; Copyright (C) 2010  Jonathan Rockway

;; Author: Jonathan Rockway <jon@jrock.us>
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(defvar flowtimer-timer-started nil
  "Records the time the flowtimer started at.")

(defvar flowtimer--time-string ""
  "The string to be displayed in the mode-line.  Internal use only.")

(defvar flowtimer--timer nil
  "The timer object that calls `flowtimer-update' every minute.  Internal use only.")

(defgroup flowtimer nil "Let Emacs nudge you in the direction of productivity."
  :group 'tools)

(defcustom flowtimer-timer-duration 48
  "How long (in minutes) you want a sprint to be.  Some random HN comment recommended 48 minutes, so that's the default."
  :type 'integer
  :group 'flowtimer)

(defcustom flowtimer-tick-interval 4
  "How frequently (in minutes) you want the remaining time to update.  The time is recalculated every minute or so; this variable only affects the display."
  :type 'integer
  :group 'flowtimer)

(defcustom flowtimer-stop-hook nil
  "Functions to run when the flowtimer expires."
  :type 'hook
  :group 'flowtimer)

(defcustom flowtimer-start-hook nil
  "Functions to run when the flowtimer is started."
  :options '(flowtimer-disable-rcirc-tracking)
  :type 'hook
  :group 'flowtimer)

(define-minor-mode flowtimer-display-mode
  "Global minor mode to display the flowtimer in the mode-line."
  :init-value nil
  :lighter ""
  :global t
  :group 'flowtimer

  (if flowtimer-display-mode
      (and (not (memq 'flowtimer--time-string global-mode-string))
           (setq global-mode-string
                 (append global-mode-string '(flowtimer--time-string))))
    (setq global-mode-string
	  (delete 'flowtimer--time-string global-mode-string))))

(defun flowtimer-update ()
  "Update the flowtimer time string."
  (let* ((timer-time (encode-time 0 flowtimer-timer-duration 0 0 0 0))
         (time-difference
          (ignore-errors (time-subtract (current-time) flowtimer-timer-started)))
         (seconds-remaining
          (ignore-errors (time-subtract timer-time time-difference)))
         (zero (encode-time 0 0 0 0 0 0)))
    (setf flowtimer--time-string
          (cond ((not flowtimer-timer-started) "")
                ((time-less-p zero seconds-remaining)
                 (let ((minutes-remaining (nth 1 (decode-time seconds-remaining))))
                   (format "%s" (flowtimer-round-minutes minutes-remaining))))
                ((time-less-p seconds-remaining zero)
                 (progn (flowtimer-stop) ""))
                 (t "")))))

(defun flowtimer-round-minutes (minutes)
  "Round MINUTES according to `flowtimer-tick-interval'."
  (* flowtimer-tick-interval (ceiling minutes flowtimer-tick-interval)))

(defun flowtimer-stop ()
  "Stop the flowtimer."
  (interactive)
  (setf flowtimer-timer-started nil)
  (flowtimer-display-mode -1)
  (ignore-errors (cancel-timer flowtimer--timer))
  (run-hooks 'flowtimer-stop-hook))

(defun flowtimer-start (prefix)
  "Start the flowtimer.
Customize `flowtimer-timer-duration' to control its duration.  With prefix arg PREFIX, restart the timer if it's already running."
  (interactive "p")
  (when (= prefix 4) (flowtimer-stop))
  (when flowtimer-timer-started
    (error "The flowtimer is already started.  Run with prefix arg to restart."))

  (flowtimer-display-mode t)

  (setf flowtimer-timer-started (current-time))
  (run-hooks 'flowtimer-start-hook)
  (setf flowtimer--timer
        (run-at-time 0 60 #'flowtimer-update)))


;; useful hooks

(defun flowtimer-enable-rcirc-tracking ()
  "Re-enable rcirc tracking.
This is automatically added to your stop hook when
`flowtimer-enable-rcirc-tracking' is run by the start hook, so
you don't need to even know it exists."
  (rcirc-track-minor-mode t))

(defun flowtimer-disable-rcirc-tracking ()
  "Disable rcirc notification while the flowtimer is on."
  (when (not (memq 'flowtimer-enable-rcirc-tracking flowtimer-stop-hook))
    (setq flowtimer-stop-hook
          (cons 'flowtimer-enable-rcirc-tracking flowtimer-stop-hook)))
  (rcirc-track-minor-mode -1))

(provide 'flowtimer)
;;; flowtimer.el ends here
