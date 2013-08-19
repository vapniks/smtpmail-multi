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
;;
;; How to create documentation and distribute package:
;;
;;     1) Remember to add ;;;###autoload magic cookies if possible
;;     2) Generate a bitcoin address for donations with shell command: bitcoin getaccountaddress smtpmail-multi
;;        and place address after "Commentary:" above.
;;     3) Use org-readme-top-header-to-readme to create initial Readme.org file.
;;     4) Use M-x auto-document to insert descriptions of commands and documents
;;     5) Create documentation in the Readme.org file:
;;        - Use org-mode features for structuring the data.
;;        - Divide the commands into different categories and create headings
;;          containing org lists of the commands in each category.
;;        - Create headings with any other extra information if needed (e.g. customization).
;;     6) In this buffer use org-readme-to-commentary to fill Commentary section with
;;        documentation from Readme.org file.
;;     7) Make any necessary adjustments to the documentation in this file (e.g. remove the installation
;;        and customization sections added in previous step since these should already be present).
;;     8) Use org-readme-marmalade-post and org-readme-convert-to-emacswiki to post
;;        the library on Marmalade and EmacsWiki respectively.
;; 
;;;;


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

;;; Customize:
;;
;; To automatically insert descriptions of customizable variables defined in this buffer
;; place point at the beginning of the next line and do: M-x auto-document

;;
;; All of the above can customized by:
;;      M-x customize-group RET smtpmail-multi RET
;;

;;; Change log:
;;	
;; 2013/08/19
;;      * First released.
;; 

;;; Acknowledgements:
;;
;; 
;;

;;; TODO
;;
;; 
;;

;;; Require
(require 'cl)

;;; Code:

(defcustom smtpmail-multi-accounts
  "List of SMTP mail accounts."
  :group 'smtpmail)

(setq smtpmail-stream-type 'ssl) ;; If using TLS/SSL.  Use C-h v smtpmail-stream-type RET to see possible values
(setq smtp-accounts
      '(("aa@bb.cc" "John Doe" "default.server.com")
        ("qq@rr.ss" "Mary Johnson" "server2.com")))

(defun my-change-smtp ()
  (save-excursion
    (loop with from = (save-restriction
                        (message-narrow-to-headers)
                        (message-fetch-field "from"))
          for (addr fname server) in smtp-accounts
          when (string-match addr from)
          do (setq user-mail-address addr
                   user-full-name fname
                   smtpmail-smtp-user addr
                   smtpmail-smtp-server server))))
  
(defadvice smtpmail-via-smtp
  (before change-smtp-by-message-from-field (recipient buffer &optional ask) activate)
  (with-current-buffer buffer (my-change-smtp)))
  
(setq user-mail-address "aa@bb.cc"
      user-full-name "John Doe"
      smtpmail-smtp-server "default.server.com"
      smtpmail-auth-credentials (expand-file-name "~/.authinfo"))

(provide 'smtpmail-multi)

;; (magit-push)
;; (yaoddmuse-post "EmacsWiki" "smtpmail-multi.el" (buffer-name) (buffer-string) "update")

;;; smtpmail-multi.el ends here
