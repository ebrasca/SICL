(cl:in-package #:sicl-boot-phase-5)

(defun enable-array-access (e5)
  (load-source-file "Array/array-dimension-defun.lisp" e5)
  (load-source-file "Array/array-total-size-defun.lisp" e5)
  (load-source-file "Array/fill-pointer.lisp" e5)
  (load-source-file "Array/row-major-aref-defgenerics.lisp" e5)
  (load-source-file "Array/row-major-aref-defmethods.lisp" e5))