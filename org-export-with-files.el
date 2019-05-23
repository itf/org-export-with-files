;;; org-export-with-files.el --- export orgmode with linked files

;;; Commentary:

;; This package provides org-export-with-files-export which allows one to
;; export an orgmode file to a pdf in a directory, while creating hardlinks to all
;; the files linked in that subtree. 
;; 
;; This is particularly useful when you want to share your files with someone who
;; doesn't use orgmode. You can have links to multiple files inside you tree and
;; when you share the directory with someone, all the links will still work in
;; the generated pdf file


;;; License:

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


(require 'ox)

;;; Code:
(defun org-export-with-files-export-parent  (&optional directory-name)
  "Exports the parent of the current subtree to pdf to DIRECTORY-NAME if set.
If not, asks the directory. Create hardlinks to all the linked files."
  (interactive)
  (save-excursion
    (outline-up-heading 1)
    (org-export-with-files-export  directory-name)))


(defun org-export-with-files-export (&optional directory-name)
  "Exports the the current subtree to pdf to DIRECTORY-NAME if set.
If not, asks the directory. Create hardlinks to all the linked files."
  (interactive)
  (let ((directory-name (or directory-name (read-directory-name "Directory:")))
        (export-latex-header (org-entry-get (point) "export_latex_header" t))
        (export-author (org-entry-get (point) "export_author" t))
        (export-file-name (org-entry-get (point) "export_file_name"))
        (export-options (org-entry-get (point) "export_options" t)))
    (make-directory directory-name t)
    (widen)
    (org-narrow-to-subtree)
    
    ;;Create copy of the 
    (org-export-with-buffer-copy
     (let* ((ast (org-element-parse-buffer)))
       (org-element-map ast 'link
         (lambda (link)
           (org-export-with-files--fix-file-external-link-ast directory-name link)))
       
       
       ;;Convert the buffer to contain the new AST, 
       ;;this is needed because the exporter expects the content to be in a buffer
       (erase-buffer) 
       (insert (org-element-interpret-data ast))
       
       (outline-show-all)
       (goto-char (point-min))
       (let* ((file-name  (or export-file-name (org-export-with-files--escaped-headline)))
              (new-file-name (concat directory-name file-name)))
         ;; Make the buffer file be in the new directory, because
         ;; org-latex-export-to-pdf always export to the working directory of the buffer
         (set-visited-file-name (concat new-file-name ".org"))
         
         ;; Set export-otions of the parents
         (if export-options
             (org-set-property
              "EXPORT_OPTIONS"
              export-options))
         (if export-author
             (org-set-property
              "EXPORT_AUTHOR"
              export-author))
         (if export-latex-header
             (org-set-property
              "EXPORT_LATEX_HEADER"
              export-latex-header))
         
         ;; Name of the tex file / pdf file
         (org-set-property
          "EXPORT_FILE_NAME"
          file-name)
         (org-latex-export-to-pdf nil t)))))
  (widen))



(defun org-export-with-files--fix-file-external-link-ast (directory-path link)
  "Create hard links to the external file LINK in DIRECTORY-PATH."
  (when (string= (org-element-property :type link) "file")
    (let* ((path (org-element-property :path link))
           (path (dnd-unescape-uri path))
           (extension (file-name-extension path))
           (link-copy (org-element-copy link))
           (img-extensions '("jpg" "tiff" "png" "bmp"))
           (link-description (org-element-contents link))
           ;; Put files in subdirectories with the extension of the file
           (new-relative-path 
            (concat "./" extension "/" (file-name-nondirectory path)))
           (new-hard-link-path (concat directory-path new-relative-path))
           (new-hard-link-directory (file-name-directory new-hard-link-path)))
      
      ;;Fix the AST
      ;;If image, remove description so it will become a real image instead of a link
      (unless (or (member extension img-extensions) (not link-description))
        (apply #'org-element-adopt-elements link-copy link-description))
      (org-element-put-property link-copy :path new-relative-path)
      (org-element-set-element link  link-copy)
      
      ;;Create hard link folder
      (make-directory new-hard-link-directory t)
      ;;Create hard link, not replacing if it already exists, catching error if file does not exist
      (condition-case nil
          (add-name-to-file path new-hard-link-path nil)
        (error nil)))))



(defun org-export-with-files--escaped-headline ()
  "Escape the headline, since it will be used as the name of the export file."
  (org-export-with-files--escape
   (nth 4 (org-heading-components))))

(defun org-export-with-files--escape(text)
  "Escapes the file names in TEXT, removing anything that could cause problems
for a link in a pdf file"
  (replace-regexp-in-string "[\\?.,!:]" ""
   (replace-regexp-in-string "/" "-" 
    (replace-regexp-in-string " " "_"  text))))


(provide 'org-export-with-files)
;;; org-export-with-files.el ends here
