;;; smtpmail-multi.el --- Use different smtp servers for sending mail

;; Filename: smtpmail-multi.el
;; Description: Use different smtp servers for sending mail
;; Author: Joe Bloggs <vapniks@yahoo.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Copyleft (Ↄ) 2013, Joe Bloggs, all rites reversed.
;; Created: 2013-08-19 02:06:43
;; Version: 0.1
;; Last-Updated: 2013-08-19 02:06:43
;;           By: Joe Bloggs
;; URL: https://github.com/vapniks/smtpmail-multi
;; Keywords: comm
;; Compatibility: GNU Emacs 24.3.1
;; Package-Requires: 
;;
;; Features that might be required by this library:
;;
;; message smtpmail
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary: 
;;
;; Bitcoin donations gratefully accepted: 1BFHneKYeXu3cXUQow2GCzsDcV2vv1Kvrt
;;
;; This library allows you to use different SMTP accounts for sending emails.
;; The SMTP account selected can depend upon the value of the "From" header of the email,
;; or any other header you choose, or even on the results of a predicate function of your choice.

;;; Usage:
;;
;; First you need to add some smtp account details to `smtpmail-multi-accounts' (see the documentation
;; of this variable for more details).
;; Next you may need to set authentication information (usernames and passwords) with `smtpmail-auth-credentials'
;; The `smtpmail-auth-credentials' variable can either be a list of hostname, port, username
;; and password tuples, or the path to an authinfo file containing this information (recommended).
;; For more info on `smtpmail-auth-credentials' see the info page for smtpmail, or view it online
;; here: http://www.gnu.org/software/emacs/manual/html_node/smtpmail/
;; Then you must decide when to use each smtp account and customize `smtpmail-multi-associations'
;; (see the documentation for further details).
;; Finally you must set the values of `send-mail-function' (if you use `mail-mode') and/or
;; `message-send-mail-function' (if you use gnus or `message-mode') to `smtpmail-multi-send-it'.

;;; Installation:
;;
;; Put smtpmail-multi.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'smtpmail-multi)

;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `smtpmail-multi-accounts'
;;    List of SMTP mail accounts.
;;  `smtpmail-multi-associations'
;;    List of rules for associating emails with SMTP accounts in `smtpmail-multi-accounts'.
;;
;; All of the above can customized by:
;;      M-x customize-group RET smtpmail RET
;;

;;; Change log:
;;	
;; 2013/08/19
;;      * First released.
;; 

;;; Acknowledgements:
;;
;; Volkan Yazici, Marcus Harnisch, Abhijeet Dhadge and others who contributed to the following
;; emacswiki page: http://www.emacswiki.org/emacs-en/MultipleSMTPAccounts
;;

;;; TODO
;;
;;

;; NOTE: documentation about the emacs smtp library can be found in the SMTP info page
;; (/usr/share/info/emacs/smtpmail.gz)
;;

;;; Require
(require 'cl)

;;; Code:

(defcustom smtpmail-multi-accounts nil
  "List of SMTP mail accounts.
Each element should be a cons cell whose first element is a symbol label for the account,
and whose second element is a list containing the following items in order: user server port"
  :type '(alist :key-type (symbol :tag "Name" :help-echo "A symbol name for this SMTP account")
                :value-type (list (string :tag "User")
                                  (string :tag "Server")
                                  (integer :tag "Port")))
  :group 'smtpmail)

(defcustom smtpmail-multi-associations nil
  "List of rules for associating emails with SMTP accounts in `smtpmail-multi-accounts'.
The first element of each item in the list is used to indicate whether the mail matches this the item or not.
It can be either a string to match the \"From\" header, a cons cell whose car is a header name and whose cdr
is a string to match that header, or a function to be called from within the mail buffer and which should return
true if the mail matches.
The subsequent elements of the list item are symbols indicating which smtp accounts to try (see `smtpmail-multi-accounts').
These different smtp accounts will be tried sequentially until the mail is successfully sent."
  :type '(repeat (cons (choice (regexp :tag "Regexp" :help-echo "A regular expression to match the \"From\" header")
                               (cons (string :tag "Header name" :help-echo "Name of header to match")
                                     (regexp :tag "Match regexp" :help-echo "A regular expression to match the header"))
                               (function :tag "Predicate" :help-echo "A predicate function that returns non-nil for matching emails"))
                       (repeat (symbol :tag "SMTP Account" :help-echo "A symbol associated with an SMTP account listed in `smtp-multi-accounts'"))))
  :group 'smtpmail)

(setq smtpmail-stream-type 'ssl) ;; If using TLS/SSL.  Use C-h v smtpmail-stream-type RET to see possible values


(defun smtpmail-multi-change account
  "Change the smtp settings to match the settings in `smtpmail-multi-accounts' associated with symbol ACCOUNT."
  (let ((settings (cdr (assoc account smtpmail-multi-accounts))))
    (setq user-mail-address (first settings)
          user-full-name (second settings)
          smtpmail-smtp-user (first settings)
          smtpmail-smtp-server (second settings)
          smtpmail-smtp-service (third settings) ; port (an integer or a string)
          smtpmail-auth-credentials ; netrc file containing username and password
          smtpmail-starttls-credentials
          smtpmail-local-domain
          smtpmail-sendto-domain
          
          )))

(defun smtpmail-multi-send-it nil
  "Send mail using smtp server selected by the `smtpmail-multi-select' function."
  (let ((accounts
         (loop with from = (save-restriction
                             (message-narrow-to-headers)
                             (message-fetch-field "from"))
               for (match . accounts) in smtpmail-multi-associations
               if (or (and (stringp match)
                           (string-match match from))
                      (and (functionp match)
                           (funcall match))
                      (and (consp match)
                           (string-match (cdr match) (message-fetch-field (car match)))))
               return accounts))
        (notsent t))
    (while (and accounts notsent)
      (smtpmail-multi-change (car accounts))
      (funcall message-send-mail-function)
      (setq accounts (cdr accounts)))))

(defadvice smtpmail-via-smtp
  (before change-smtp-by-message-from-field (recipient buffer &optional ask) activate)
  (with-current-buffer buffer (smtpmail-multi-change)))
  
(setq user-mail-address "aa@bb.cc"
      user-full-name "John Doe"
      smtpmail-smtp-server "default.server.com"
      smtpmail-auth-credentials (expand-file-name "~/.authinfo"))

(provide 'smtpmail-multi)

;; (magit-push)
;; (yaoddmuse-post "EmacsWiki" "smtpmail-multi.el" (buffer-name) (buffer-string) "update")

;;; smtpmail-multi.el ends here
