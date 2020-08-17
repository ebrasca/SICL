(in-package #:sicl-hir-evaluator)

;;; This file introduces a convenient macro for creating and registering
;;; instruction thunks.  It automatically handles destructuring of inputs,
;;; outputs, and successors and provides a symbol macro for manipulating
;;; the current dynamic environment.
;;;
;;; This macro also ensures that thunks are created and registered before
;;; any successors are converted.  This way, even circular instruction
;;; graphs can be converted with ease.

(defmacro make-thunk ((client instruction lexical-environment
                       &key (inputs 0) (outputs 0) (successors 1))
                      &body body)
  (sicl-utilities:once-only (client instruction lexical-environment)
    (let ((thunk-gensym (gensym "THUNK"))
          (self-gensym (gensym "SELF"))
          (dynamic-environment-gensym-1 (gensym "DYNAMIC-ENVIRONMENT"))
          (dynamic-environment-gensym-2 (gensym "DYNAMIC-ENVIRONMENT"))
          (input-gensyms (loop repeat inputs collect (gensym "INPUT")))
          (output-gensyms (loop repeat outputs collect (gensym "OUTPUT")))
          (successor-gensyms (loop repeat successors collect (gensym "SUCCESSOR")))
          (successor-thunk-gensyms (loop repeat successors collect (gensym "SUCCESSOR-THUNK"))))
      `(destructuring-bind (,@input-gensyms &rest _)
           (cleavir-ir:inputs ,instruction)
         (declare (ignore _))
         (destructuring-bind (,@output-gensyms &rest _)
             (cleavir-ir:outputs ,instruction)
           (declare (ignore _))
           (destructuring-bind (,@successor-gensyms &rest _)
               (cleavir-ir:successors ,instruction)
             (declare (ignore _))
             (let ((,dynamic-environment-gensym-1
                     (value-cell 'dynamic-environment ,lexical-environment))
                   (,dynamic-environment-gensym-2
                     (value-cell (cleavir-ir:dynamic-environment-location ,instruction)
                                 ,lexical-environment))
                   (,self-gensym #'dummy-successor)
                   ,@(loop for input-gensym in input-gensyms
                           collect
                           `(,input-gensym (value-cell ,input-gensym ,lexical-environment)))
                   ,@(loop for output-gensym in output-gensyms
                           collect
                           `(,output-gensym (value-cell ,output-gensym ,lexical-environment)))
                   ,@(loop for successor-thunk-gensym in successor-thunk-gensyms
                           collect
                           `(,successor-thunk-gensym #'dummy-successor)))
               (declare (ignorable
                         ,dynamic-environment-gensym-1
                         ,dynamic-environment-gensym-2
                         ,self-gensym))
               (macrolet ((input (index)
                            (case index
                              ,@(loop for input-gensym in input-gensyms
                                      for index from 0
                                      collect
                                      `((,index) `(car ,',input-gensym)))
                              (otherwise
                               (error "Invalid input index: ~S" index))))
                          (output (index)
                            (case index
                              ,@(loop for output-gensym in output-gensyms
                                      for index from 0
                                      collect
                                      `((,index) `(car ,',output-gensym)))
                              (otherwise
                               (error "Invalid output index: ~S" index))))
                          (successor (index)
                            (case index
                              ,@(loop for successor-thunk-gensym in successor-thunk-gensyms
                                      for index from 0
                                      collect
                                      `((,index) ',successor-thunk-gensym))
                              (otherwise
                               (error "Invalid successor index: ~S" index)))))
                 (let ((,thunk-gensym
                         (symbol-macrolet
                             ((dynamic-environment (car ,dynamic-environment-gensym-2)))
                           (lambda ()
                             (prologue
                              ,dynamic-environment-gensym-1
                              ,dynamic-environment-gensym-2
                              ,self-gensym)
                             #+(or)
                             (format *trace-output*
                                     "~&~S~% inputs: ~S~%"
                                     (class-name (class-of ,instruction))
                                     (list ,@(loop for input-gensym in input-gensyms
                                                   collect `(car ,input-gensym))))
                             (prog1 (progn ,@body)
                               #+(or)
                               (format *trace-output*
                                       "~& outputs: ~S~% values: ~S~%"
                                      (list ,@(loop for output-gensym in output-gensyms
                                                    collect `(car ,output-gensym)))
                                      *global-values-location*)
                               (epilogue
                                ,dynamic-environment-gensym-1
                                ,dynamic-environment-gensym-2))))))
                   (setf ,self-gensym ,thunk-gensym)
                   (setf (gethash ,instruction *instruction-thunks*)
                         ,thunk-gensym)
                   ,@(loop for successor-gensym in successor-gensyms
                           for successor-thunk-gensym in successor-thunk-gensyms
                           collect
                           `(setf ,successor-thunk-gensym
                                  (instruction-thunk ,client ,successor-gensym ,lexical-environment))
                           collect
                           `(check-type ,successor-thunk-gensym function))
                   ,thunk-gensym)))))))))

(defun dummy-successor ()
  (error "Invocation of the dummy successor."))

(defun prologue (cell-1 cell-2 thunk)
  (let ((env1 (car cell-1))
        (env2 (car cell-2)))
    (unless (or (eq env1 env2)
                (> (length env2) (length env1)))
      (loop for env = env1 then (rest env)
            for entry = (first env)
            until (eq env env2)
            do (sicl-run-time:invalidate-entry entry))
      (let ((last-block/tagbody
              (loop with result = nil
                    for env = env1 then (rest env)
                    for entry = (first env)
                    until (eq env env2)
                    when (typep entry 'sicl-run-time:unwind-protect-entry)
                      do (funcall (sicl-run-time:thunk entry))
                    when (typep entry 'sicl-run-time:block/tagbody-entry)
                      do (setf result entry)
                    finally (return result))))
        (unless (null last-block/tagbody)
          (throw (sicl-run-time:frame-pointer last-block/tagbody)
            thunk))))))

(defun epilogue (cell-1 cell-2)
  (setf (car cell-1)
        (car cell-2)))
