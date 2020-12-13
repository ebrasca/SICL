(cl:in-package #:sicl-boot-phase-3)
(defun boot (boot)
  (format *trace-output* "Start phase 3~%")
  (with-accessors ((e0 sicl-boot:e0)
                   (e2 sicl-boot:e2)
                   (e3 sicl-boot:e3)
                   (e4 sicl-boot:e4))
      boot
    (change-class e3 'environment
                  :client (make-instance 'client :e3 e3))
    (sicl-boot:create-accessor-defgenerics e3)
    (sicl-boot:create-mop-classes e3)
    (setf (env:find-class (env:client e3) e3 'symbol) (find-class 'symbol))
    (load-source-file "Package-and-symbol/symbol-value-etc-defuns.lisp" e3)
    (load-source-file "CLOS/class-readers-forward-referenced-class-defmethods.lisp" e3)
    (load-source-file "CLOS/class-readers-defmethods-before.lisp" e3)
    (sicl-boot:copy-macro-functions e0 e4)
    (prepare-next-phase e2 e3 e4)))
