(cl:in-package #:sicl-boot-phase-8)

(defun boot (boot)
  (format *trace-output* "Start of phase 8~%")
  (with-accessors ((e5 sicl-boot:e5))
      boot
    (setf (sicl-genv:macro-function 'defpackage e5)
          (constantly nil))
    (setf (sicl-genv:fdefinition 'host-symbolp e5)
          #'symbolp)
    (setf (sicl-genv:fdefinition 'host-symbol-name e5)
          #'symbol-name)
    (import-function-from-host 'sicl-genv:type-expander e5)
    (import-functions-from-host
     '(caar rplaca rassoc nconc evenp min - > integerp)
     e5)
    (load-source "Boot/Phase-8/symbol-name-defmethod-around.lisp" e5)
    (load-source "Types/Typep/typep.lisp" e5)
    (load-source "Types/Typep/typep-atomic.lisp" e5)
    (load-source "Types/Typep/typep-compound.lisp" e5)
    (load-source "Types/Typep/typep-compound-integer.lisp" e5)
    (load-source "Conditionals/support.lisp" e5)
    (import-function-from-host 'cleavir-code-utilities:parse-macro e5)
    ;; Some functions in the Cons module use hash tables, indirectly
    ;; through LOOP clauses.  Therefore this macro must be defined
    ;; before that module is loaded."
    (load-source "Hash-tables/with-hash-table-iterator-defmacro.lisp" e5)
    (load-source "Loop/run-time-support.lisp" e5)
    (load-source "CLOS/defgeneric-support.lisp" e5)
    (load-hash-table-functionality e5)
    (load-source "Environment/macro-support.lisp" e5)
    (load-source "Environment/standard-environment-macros.lisp" e5)
    (load-source "CLOS/find-method-defgenerics.lisp" e5)
    (load-source "CLOS/find-method-defmethods.lisp" e5)
    (load-source "Iteration/utilities.lisp" e5)
    (load-source "Iteration/dotimes-support.lisp" e5)
    (load-source "Iteration/dotimes-defmacro.lisp" e5)
    (load-source "Iteration/dolist-support.lisp" e5)
    (load-source "Iteration/dolist-defmacro.lisp" e5)
    (load-source "Iteration/do-dostar-support.lisp" e5)
    (load-source "Iteration/do-dostar-defmacro.lisp" e5)
    (import-functions-from-host
     '(cleavir-code-utilities:separate-ordinary-body
       cleavir-code-utilities:parse-destructuring-lambda-list
       cleavir-code-utilities:destructure-lambda-list)
     e5)
    (load-source "Data-and-control-flow/destructuring-bind-support.lisp" e5)
    (load-source "Data-and-control-flow/destructuring-bind-defmacro.lisp" e5)
    (when (null (find-package '#:portable-condition-system))
      (make-package '#:portable-condition-system
                    :use (list (find-package '#:common-lisp))))
    (import-function-from-host 'trucler:macro-function e5)
    (load-source "Evaluation-and-compilation/macroexpand-1-defun.lisp" e5)
    (load-source "Evaluation-and-compilation/macroexpand-defun.lisp" e5)
    (load-source "Data-and-control-flow/constantly-defun.lisp" e5)
    (load-source "Data-and-control-flow/defun-support.lisp" e5)
    (setf (sicl-genv:special-variable '*debug-io* e5 t)
          *debug-io*)
    (import-functions-from-host '(read finish-output) e5)
    (load-asdf-system-components '#:sicl-conditions e5)
    (load-source "CLOS/conditions.lisp" e5)
    (import-function-from-host '(setf sicl-genv:compiler-macro-function) e5)
    (load-asdf-system-components '#:sicl-character e5)
    (load-source "Package-and-symbol/find-package-defun.lisp" e5)
    (load-sicl-utilities e5)
    (load-source "CLOS/slot-value-etc-specified-defuns.lisp" e5)
    (load-sequence-functions e5)
    ;; This files should be loaded last, because they contain code
    ;; that can be executed by the host during bootstrapping.
    (load-source "CLOS/defmethod-support.lisp" e5)
    (load-source "CLOS/defclass-support.lisp" e5)
    (with-intercepted-function-names ((expt) e5)
      (load-source "Arithmetic/expt-defgeneric.lisp" e5)
      (load-source "Arithmetic/expt-defmethods.lisp" e5))
    (load-arithmetic-functions e5)
    (load-source "CLOS/discriminating-automaton.lisp" e5)
    (load-asdf-system-components '#:sicl-cons-defuns e5)
    (load-source "Cons/accessor-defuns.lisp" e5)
    (load-source "Cons/cxr.lisp" e5)
    (load-source "Data-and-control-flow/not-defun.lisp" e5)
    (load-source "Data-and-control-flow/eq-defun.lisp" e5)
    (load-source "Data-and-control-flow/identity-defun.lisp" e5)))
