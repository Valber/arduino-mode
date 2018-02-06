;;; Arduino-mode.el --- Major mode for the Arduino language

;; Copyright (C) 2008  Christopher Grim

;; Author: Christopher Grim <christopher.grim@gmail.com>
;; Keywords: languages, arduino
;; Version: 1.0

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Based on derived-mode-ex.el found here:
;;
;; <http://cc-mode.sourceforge.net/derived-mode-ex.el>.
;;

;;; Code:
(require 'cc-mode)

(eval-when-compile
  (require 'cl)
  (require 'cc-langs)
  (require 'cc-fonts)
  (require 'cc-menus)
  (require 'term))

(eval-and-compile
  ;; fall back on c-mode
  (c-add-language 'arduino-mode 'c-mode))

(c-lang-defconst c-primitive-type-kwds
  arduino (append '(;; Data Types
                    "boolean" "byte"
                    "int" "long" "short" "double" "float"
                    "char" "string"
                    "unsigned char" "unsigned int" "unsigned long"
                    "void" "word"
                    ;; Variable Scope & Qualifiers
                    "const" "scope" "static" "volatile"
                    ;; Structure
                    ;; Sketch
                    "loop" "setup"
                    ;; Control Structure
                    "break" "continue" "do" "while" "else" "for" "goto" "if"
                    "return" "switch" "case"
                    ;; Utilities
                    "PROGMEM"
                    )
                  (c-lang-const c-primitive-type-kwds)))

(c-lang-defconst c-constant-kwds
  arduino (append
           '("HIGH" "LOW"
             "INPUT" "OUTPUT" "INPUT_PULLUP"
             "LED_BUILTIN"
             "true" "false")
           (c-lang-const c-constant-kwds)))

(c-lang-defconst c-simple-stmt-kwds
  arduino
  (append
   '(;; Operator Utilities
     "sizeof"
     ;; Functions
     "pinMode" "digitalWrite" "digitalRead"                ; Digital I/O
     "analogReference" "analogRead" "analogWrite"          ; Analog I/O
     "analogReadResolution" "analogWriteResolution" ; Zero, Due & MKR Family
     "tone" "noTone" "shiftIn" "shiftOut" "pulseIn" "pulseInLong" ; Advanced I/O
     "millis" "micros" "delay" "delayMicroseconds"                ; Time
     "min" "max" "abs" "constrain" "map" "pow" "sq" "sqrt"        ; Math
     "sin" "cos" "tan"                                            ; Trigonometry
     "randomSeed" "random"                              ; Random Numbers
     "bit" "bitRead" "bitWrite" "bitSet" "bitClear" "lowByte" "highByte" ; Bits and Bytes
     "attachInterrupt" "detachInterrupt" ; External Interrupts
     "interrupts" "noInterrupts"         ; Interrupts
     "serial" "stream"                   ; Serial Communication
     ;; Characters
     "isAlpha" "isAlphaNumeric"
     "isAscii" "isControl" "isDigit" "isGraph" "isHexadecimalDigit"
     "isLowerCase" "isUpperCase"
     "isPrintable" "isPunct" "isSpace" "isWhitespace"
     ;; USB Devices like Keyboard functions
     "print" "println"
     ;; Serial
     "begin" "end" "available" "read" "flush"  "peek"
     ;; Keyboard
     "write" "press" "release" "releaseAll"
     ;; Mouse
     "click" "move" "isPressed"
     )
   (c-lang-const c-simple-stmt-kwds)))

(c-lang-defconst c-primary-expr-kwds
  arduino (append
           '(;; Communication
             "Serial"
             ;; USB (Leonoardo based boards and Due only)
             "Keyboard"
             "Mouse")
           (c-lang-const c-primary-expr-kwds)))

(defgroup arduino nil "Arduino mode customizations"
  :group 'languages)

(defcustom arduino-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in Arduino mode.
Each list item should be a regexp matching a single identifier."
  :group 'arduino)

(defcustom arduino-executable "arduino"
  "*The arduino executable"
  :group 'arduino
  :type 'string)

(defconst arduino-font-lock-keywords-1 (c-lang-const c-matchers-1 arduino)
  "Minimal highlighting for Arduino mode.")

(defconst arduino-font-lock-keywords-2 (c-lang-const c-matchers-2 arduino)
  "Fast normal highlighting for Arduino mode.")

(defconst arduino-font-lock-keywords-3 (c-lang-const c-matchers-3 arduino)
  "Accurate normal highlighting for Arduino mode.")

(defvar arduino-font-lock-keywords arduino-font-lock-keywords-3
  "Default expressions to highlight in ARDUINO mode.")

(defvar arduino-mode-syntax-table nil
  "Syntax table used in arduino-mode buffers.")

(or arduino-mode-syntax-table
    (setq arduino-mode-syntax-table
          (funcall (c-lang-const c-make-mode-syntax-table arduino))))

(defvar arduino-mode-abbrev-table nil
  "Abbreviation table used in arduino-mode buffers.")

(c-define-abbrev-table 'arduino-mode-abbrev-table
  ;; Keywords that if they occur first on a line might alter the
  ;; syntactic context, and which therefore should trigger
  ;; reindentation when they are completed.
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)))

(defvar arduino-mode-map
  (let ((map (c-make-inherited-keymap)))
    ;; Add bindings which are only useful for Arduino
    map)
  "Keymap used in arduino-mode buffers.")

(define-key arduino-mode-map (kbd "C-c C-c") 'arduino-upload)
(define-key arduino-mode-map (kbd "C-c m") 'arduino-serial-monitor)

(easy-menu-define arduino-menu arduino-mode-map "Arduino Mode Commands"
  (cons "Arduino" (c-lang-const c-mode-menu arduino)))

(easy-menu-add-item arduino-menu
			              (list "Micro-controller") ["Upload" arduino-upload t])
(easy-menu-add-item arduino-menu
		                nil ["----" nil nil])
(easy-menu-add-item arduino-menu
		                nil ["Upload" arduino-upload t])
(easy-menu-add-item arduino-menu
		                nil ["Serial monitor" arduino-serial-monitor t])

(defun arduino-upload ()
  "Upload the sketch to an Arduino board."
  (interactive)
  (start-file-process
   "arduino-upload" "*arduino-upload*" arduino-executable "--upload" (buffer-file-name)))

(defun arduino-verify ()
  "Verify the sketch."
  (interactive)
  (start-file-process
   "arduino-verify" "*arduino-verify*" arduino-executable "--verify" (buffer-file-name)))

(defun arduino-open-with-arduino ()
  "Open the sketch with the Arduino IDE."
  (interactive)
  (start-file-process
   "arduino-open" "*arduino-open*" arduino-executable (buffer-file-name)))

(defun arduino-serial-monitor (port speed)
  "Monitor the `SPEED' on serial connection on `PORT' to the Arduino."
  (interactive (list (serial-read-name) nil))
  (if (get-buffer-process port)
	    (switch-to-buffer port)
    (serial-term port (or speed (serial-read-speed)))))


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pde\\'" . arduino-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ino\\'" . arduino-mode))

;;;###autoload
(defun arduino-mode ()
  "Major mode for editing Arduino code.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `arduino-mode-hook'.

Key bindings:
\\{arduino-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table arduino-mode-syntax-table)
  (setq major-mode 'arduino-mode
        mode-name "Arduino"
        local-abbrev-table arduino-mode-abbrev-table
        abbrev-mode t
        imenu-generic-expression cc-imenu-c-generic-expression)
  (use-local-map arduino-mode-map)
  ;; `c-init-language-vars' is a macro that is expanded at compile
  ;; time to a large `setq' with all the language variables and their
  ;; customized values for our language.
  (c-init-language-vars arduino-mode)
  ;; `c-common-init' initializes most of the components of a CC Mode
  ;; buffer, including setup of the mode menu, font-lock, etc.
  ;; There's also a lower level routine `c-basic-common-init' that
  ;; only makes the necessary initialization to get the syntactic
  ;; analysis and similar things working.
  (c-common-init 'arduino-mode)
  (easy-menu-add arduino-menu)
  (set (make-local-variable 'c-basic-offset) 2)
  (set (make-local-variable 'tab-width) 2)
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'arduino-mode-hook)
  (c-update-modeline))

(provide 'arduino-mode)
;;; arduino-mode.el ends here
