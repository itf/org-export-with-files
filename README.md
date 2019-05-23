# org-export-with-files
This package provides org-export-with-files-export which allows one to
 export an orgmode file to a pdf in a directory, while creating hardlinks to all
 the files linked in that subtree. 
 
 This is particularly useful when you want to share your files with someone who
 doesn't use orgmode. You can have links to multiple files inside you tree and
 when you share the directory with someone, all the links will still work in
 the generated pdf file

## Usage
Add it to path, run (require 'org-export-with-files).

Run M-x org-export-with-files-export on the subtree you want to export
